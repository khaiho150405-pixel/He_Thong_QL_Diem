import hashlib
import importlib.util
import os
import pickle
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import cv2
import numpy as np

from src.adapters import vietocr_reader as vr
from src.adapters.errors import ModelUnavailableError

HAS_VIETOCR = (
    importlib.util.find_spec("vietocr") is not None and importlib.util.find_spec("torch") is not None
)
needs_vietocr = unittest.skipUnless(HAS_VIETOCR, "vietocr is not installed (pip install --no-deps vietocr==0.3.13)")


def fake_weights(directory: Path, name: str = "weights.pth") -> tuple[Path, str]:
    path = directory / name
    path.write_bytes(b"not a real checkpoint")
    return path, hashlib.sha256(path.read_bytes()).hexdigest()


class ConfigTest(unittest.TestCase):
    def test_config_follows_the_finetune_settings_and_has_no_remote_url(self) -> None:
        cfg = vr.build_config(vr.DEFAULT_CONFIG, Path("/models/vietocr.pth"), "cpu")
        self.assertEqual(
            (
                cfg["dataset"]["image_height"],
                cfg["dataset"]["image_min_width"],
                cfg["dataset"]["image_max_width"],
            ),
            (32, 32, 384),
        )
        self.assertIs(cfg["predictor"]["beamsearch"], False)
        self.assertIs(cfg["cnn"]["pretrained"], False)
        self.assertEqual(cfg["device"], "cpu")
        self.assertEqual(Path(cfg["weights"]), Path("/models/vietocr.pth"))
        self.assertNotIn("pretrain", cfg)
        for key, value in cfg.items():
            if key != "vocab":
                self.assertNotIn("http", str(value).lower(), key)

    def test_shipped_yaml_only_references_urls_that_are_overridden(self) -> None:
        text = vr.DEFAULT_CONFIG.read_text(encoding="utf-8")
        self.assertIn("vocr.vn", text)  # present in the file ...
        cfg = vr.build_config(vr.DEFAULT_CONFIG, Path("w.pth"), "cpu")
        self.assertNotIn("vocr.vn", str(cfg["weights"]))  # ... and gone from the effective configuration

    def test_a_config_that_keeps_a_url_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            bad = Path(directory) / "bad.yml"
            bad.write_text(
                vr.DEFAULT_CONFIG.read_text(encoding="utf-8") + "\nextra_download: http://example.test/x.pth\n",
                encoding="utf-8",
            )
            with self.assertRaises(ModelUnavailableError):
                vr.build_config(bad, Path("w.pth"), "cpu")

    def test_source_never_uses_predictor_unsafe_loading_or_downloads(self) -> None:
        code = Path(vr.__file__).read_text(encoding="utf-8").split('"""', 2)[2]
        for forbidden in ("weights_only=False", "Predictor(", "download", "urlopen", "requests"):
            self.assertNotIn(forbidden, code)
        self.assertIn("weights_only=True", code)


class LoadingTest(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path, self.sha = fake_weights(Path(self.directory.name))

    def test_wrong_missing_or_malformed_hash_and_missing_file(self) -> None:
        for bad in ("0" * 64, "", "abc", None):
            with self.assertRaises(ModelUnavailableError):
                vr.VietOcrReader.load(self.path, bad)  # type: ignore[arg-type]
        with self.assertRaises(ModelUnavailableError):
            vr.VietOcrReader.load(Path(self.directory.name) / "absent.pth", self.sha)

    def test_the_hash_is_checked_before_anything_is_imported_or_loaded(self) -> None:
        with mock.patch.object(vr, "_vietocr", side_effect=AssertionError("must not be reached")):
            with self.assertRaises(ModelUnavailableError):
                vr.VietOcrReader.load(self.path, "f" * 64)

    def test_missing_vietocr_package_is_model_unavailable(self) -> None:
        with mock.patch.dict(sys.modules, {"vietocr": None, "vietocr.tool": None, "vietocr.tool.translate": None}):
            with self.assertRaises(ModelUnavailableError) as caught:
                vr.VietOcrReader.load(self.path, self.sha)
        self.assertIn("vietocr", str(caught.exception))

    @needs_vietocr
    def test_pickled_object_is_rejected_without_downgrading(self) -> None:
        class Evil:
            def __reduce__(self):
                return (os.getcwd, ())

        path = Path(self.directory.name) / "evil.pth"
        with path.open("wb") as handle:
            pickle.dump({"x": Evil()}, handle)
        with self.assertRaises(ModelUnavailableError) as caught:
            vr.VietOcrReader.load(path, hashlib.sha256(path.read_bytes()).hexdigest())
        self.assertIn("safely", str(caught.exception))

    @needs_vietocr
    def test_state_dict_that_does_not_fit_is_rejected(self) -> None:
        import torch

        path = Path(self.directory.name) / "small.pth"
        torch.save({"fc.weight": torch.zeros(2, 2)}, path)
        with self.assertRaises(ModelUnavailableError):
            vr.VietOcrReader.load(path, hashlib.sha256(path.read_bytes()).hexdigest())


@needs_vietocr
class ReadingTest(unittest.TestCase):
    """Architecture-only checks with a randomly initialised model (no real weights needed)."""

    @classmethod
    def setUpClass(cls) -> None:
        import torch
        from vietocr.tool import translate

        cls.directory = tempfile.TemporaryDirectory()
        path = Path(cls.directory.name) / "random.pth"
        cfg = vr.build_config(vr.DEFAULT_CONFIG, path, "cpu")
        torch.manual_seed(0)
        model, _ = translate.build_model(cfg)
        torch.save(model.state_dict(), path)
        cls.reader = vr.VietOcrReader.load(path, hashlib.sha256(path.read_bytes()).hexdigest())

    @classmethod
    def tearDownClass(cls) -> None:
        cls.directory.cleanup()

    @staticmethod
    def cell(width: int, text: str = "Tam ruoi") -> np.ndarray:
        image = np.full((44, width, 3), 245, np.uint8)
        cv2.putText(image, text, (6, 32), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (30, 30, 30), 2)
        return image

    def test_reads_keep_order_across_width_buckets(self) -> None:
        images = [self.cell(120), self.cell(300), self.cell(120, "Chin"), self.cell(480)]
        reads = self.reader.read_cells(images)
        self.assertEqual(len(reads), 4)
        singles = [self.reader.read_cells([image])[0] for image in images]
        for batched, single in zip(reads, singles):
            self.assertEqual(batched.text, single.text)
            self.assertAlmostEqual(batched.prob, single.prob, places=4)
            self.assertTrue(0.0 <= batched.prob <= 1.0)

    def test_text_is_nfc_and_stripped_and_empty_input_is_safe(self) -> None:
        import unicodedata

        for read in self.reader.read_cells([self.cell(200), None, np.zeros((0, 0), np.uint8)]):
            self.assertEqual(read.text, unicodedata.normalize("NFC", read.text.strip()))
        self.assertEqual(self.reader.read_cells([]), [])


@unittest.skipUnless(
    HAS_VIETOCR and os.getenv("RECOGNITION_VIETOCR_WEIGHTS"),
    "RECOGNITION_VIETOCR_WEIGHTS is not set or vietocr is missing (no real weights in CI)",
)
class RealWeightsTest(unittest.TestCase):
    def test_real_checkpoint_loads_offline_and_reads_a_cell(self) -> None:
        from src.adapters.crnn import sha256_of

        path = Path(os.environ["RECOGNITION_VIETOCR_WEIGHTS"])
        sha = os.getenv("RECOGNITION_VIETOCR_SHA256") or sha256_of(path)
        reader = vr.VietOcrReader.load(path, sha)
        reads = reader.read_cells([ReadingTest.cell(260)])
        self.assertEqual(len(reads), 1)
        self.assertIsInstance(reads[0].text, str)


if __name__ == "__main__":
    unittest.main()
