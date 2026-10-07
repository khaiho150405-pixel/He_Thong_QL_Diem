import hashlib
import os
import pickle
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np
import torch

from src.adapters import crnn
from src.adapters.crnn import CrnnReader, ModelUnavailableError, decode_ctc, tien_xu_ly_anh


def write_checkpoint(directory: Path, name: str = "crnn.pth", seed: int = 0) -> tuple[Path, str]:
    torch.manual_seed(seed)
    model = crnn._build_model(torch)
    path = directory / name
    torch.save({"model_state_dict": model.state_dict(), "epoch": 1}, path)
    return path, hashlib.sha256(path.read_bytes()).hexdigest()


def digits(text: str, width: int = 90) -> np.ndarray:
    cell = np.full((44, width, 3), 245, np.uint8)
    cv2.putText(cell, text, (8, 34), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (30, 30, 30), 3)
    return cell


class PreprocessTest(unittest.TestCase):
    def test_output_shape_range_and_padding(self) -> None:
        out = tien_xu_ly_anh(digits("8.5"))
        self.assertEqual(out.shape, (32, 128))
        self.assertEqual(out.dtype, np.float32)
        self.assertTrue(-1.0 <= out.min() and out.max() <= 1.0)
        # narrow cells are centred on white padding (value 1.0 after normalisation)
        self.assertEqual(float(out[0, 0]), 1.0)
        self.assertEqual(float(out[0, -1]), 1.0)

    def test_wide_cells_are_squeezed_and_empty_input_is_blank(self) -> None:
        wide = np.full((20, 900), 200, np.uint8)
        self.assertEqual(tien_xu_ly_anh(wide).shape, (32, 128))
        for empty in (None, np.zeros((0, 0), np.uint8)):
            self.assertTrue(np.all(tien_xu_ly_anh(empty) == 1.0))

    def test_gray_and_colour_cells_give_the_same_tensor(self) -> None:
        colour = digits("7")
        gray = cv2.cvtColor(colour, cv2.COLOR_BGR2GRAY)
        np.testing.assert_array_equal(tien_xu_ly_anh(colour), tien_xu_ly_anh(gray))


class DecodeTest(unittest.TestCase):
    @staticmethod
    def probs(path: list[int], confidence: float = 0.9) -> np.ndarray:
        steps = np.full((1, len(path), crnn.NUM_CLASSES), (1 - confidence) / (crnn.NUM_CLASSES - 1))
        for t, token in enumerate(path):
            steps[0, t, token] = confidence
        return steps

    def test_greedy_ctc_collapses_repeats_and_blanks(self) -> None:
        # blank 8 8 blank . blank 5 5 -> "8.5"
        idx = {c: i + 1 for i, c in enumerate(crnn.CHARSET)}
        path = [0, idx["8"], idx["8"], 0, idx["."], 0, idx["5"], idx["5"]]
        read = decode_ctc(self.probs(path))[0]
        self.assertEqual(read.text, "8.5")
        self.assertAlmostEqual(read.conf_mean, 0.9, places=6)
        self.assertAlmostEqual(read.conf_min, 0.9, places=6)
        self.assertGreater(read.conf_path, 0.85)

    def test_same_digit_twice_needs_a_blank_between(self) -> None:
        idx = {c: i + 1 for i, c in enumerate(crnn.CHARSET)}
        self.assertEqual(decode_ctc(self.probs([idx["1"], idx["1"]]))[0].text, "1")
        self.assertEqual(decode_ctc(self.probs([idx["1"], 0, idx["1"]]))[0].text, "11")

    def test_only_blanks_is_empty_with_zero_confidence(self) -> None:
        read = decode_ctc(self.probs([0, 0, 0, 0]))[0]
        self.assertEqual((read.text, read.conf_mean, read.conf_min), ("", 0.0, 0.0))


class LoadingTest(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path, self.sha = write_checkpoint(Path(self.directory.name))

    def test_wrong_hash_is_model_unavailable_and_nothing_is_loaded(self) -> None:
        with self.assertRaises(ModelUnavailableError) as caught:
            CrnnReader.load(self.path, "0" * 64)
        self.assertIn("SHA-256", str(caught.exception))

    def test_missing_or_malformed_hash_or_file(self) -> None:
        for bad in ("", "abc", "G" * 64, None):
            with self.assertRaises(ModelUnavailableError):
                CrnnReader.load(self.path, bad)  # type: ignore[arg-type]
        with self.assertRaises(ModelUnavailableError):
            CrnnReader.load(Path(self.directory.name) / "absent.pth", self.sha)

    def test_pickled_object_is_rejected_without_downgrading_weights_only(self) -> None:
        class Evil:
            def __reduce__(self):  # would run on an unsafe pickle load
                return (os.getcwd, ())

        path = Path(self.directory.name) / "evil.pth"
        with path.open("wb") as handle:
            pickle.dump({"model_state_dict": {"x": Evil()}}, handle)
        sha = hashlib.sha256(path.read_bytes()).hexdigest()
        with self.assertRaises(ModelUnavailableError):
            CrnnReader.load(path, sha)

    def test_checkpoint_that_does_not_fit_the_architecture_is_rejected(self) -> None:
        path = Path(self.directory.name) / "other.pth"
        torch.save({"model_state_dict": {"fc.weight": torch.zeros(3, 3)}}, path)
        with self.assertRaises(ModelUnavailableError):
            CrnnReader.load(path, hashlib.sha256(path.read_bytes()).hexdigest())

    def test_loader_source_never_uses_unsafe_loading(self) -> None:
        source = Path(crnn.__file__).read_text(encoding="utf-8")
        self.assertIn("weights_only=True", source)
        self.assertNotIn("weights_only=False", source)

    def test_loaded_reader_reads_batches_in_order(self) -> None:
        reader = CrnnReader.load(self.path, self.sha)
        self.assertEqual(reader.sha256, self.sha)
        images = [digits(text) for text in ("8.5", "10", "7", "9.0", "6")]
        batched = reader.read_cells(images, batch_size=2)
        single = [reader.read_cells([image])[0] for image in images]
        self.assertEqual(len(batched), 5)
        for a, b in zip(batched, single):
            self.assertEqual(a.text, b.text)
            self.assertAlmostEqual(a.conf_mean, b.conf_mean, places=4)
        for read in batched:
            self.assertTrue(set(read.text) <= set(crnn.CHARSET))
            self.assertTrue(0.0 <= read.conf_mean <= 1.0)
            self.assertTrue(0.0 <= read.conf_min <= read.conf_mean <= 1.0 or read.text == "")
        self.assertEqual(reader.read_cells([]), [])

    def test_stt_reading_accepts_only_positive_integers(self) -> None:
        reader = CrnnReader.load(self.path, self.sha)
        cases = {
            "41": 41,
            "7": 7,
            "500": 500,
            "501": None,  # out of range
            "0": None,
            "8.5": None,  # not an integer
            "": None,
        }
        original = reader.read_cells
        for text, expected in cases.items():
            reader.read_cells = lambda images, batch_size=64, text=text: [  # type: ignore[method-assign]
                crnn.CellRead(text, 0.9, 0.8, 0.7)
            ]
            result = reader.read_stt([digits("1")])[0]
            self.assertEqual(result.value, expected, text)
            self.assertEqual(result.confidence, 0.9 if expected is not None else 0.0)
        reader.read_cells = original  # type: ignore[method-assign]


@unittest.skipUnless(
    os.getenv("RECOGNITION_CRNN_WEIGHTS"), "RECOGNITION_CRNN_WEIGHTS is not set (no real weights in CI)"
)
class RealWeightsTest(unittest.TestCase):
    def test_real_checkpoint_loads_with_weights_only_and_reads_digits(self) -> None:
        path = Path(os.environ["RECOGNITION_CRNN_WEIGHTS"])
        sha = os.getenv("RECOGNITION_CRNN_SHA256") or crnn.sha256_of(path)
        reader = CrnnReader.load(path, sha)
        reads = reader.read_cells([digits("8.5"), digits("10.0"), np.full((44, 90, 3), 245, np.uint8)])
        self.assertEqual(len(reads), 3)
        for read in reads:
            self.assertTrue(set(read.text) <= set(crnn.CHARSET))


if __name__ == "__main__":
    unittest.main()
