import os
import unittest
from decimal import Decimal
from pathlib import Path
from unittest.mock import patch

import cv2
import numpy as np
from fastapi import HTTPException, UploadFile
from fastapi.testclient import TestClient

from src.adapters import model as model_module
from src.adapters.crnn import CellRead, SttRead
from src.adapters.errors import ModelUnavailableError
from src.adapters.model import WeightsRecognitionModel, configured_model
from src.adapters.vietocr_reader import TextRead
from src.api.main import app, recognize
from src.pipeline.errors import PipelineError
from synthetic import encode_png, make_page, photograph
from test_pipeline_grid import SCORE_HEADERS, SCORE_SHEET

ROWS = 6
STRUCK = 2  # zero-based
BLANK = 4


def sheet_photo() -> bytes:
    cell_text, ink = {}, []
    for row in range(ROWS):
        if row != BLANK:
            cell_text[(row, 1)] = f"Hoc sinh {row + 1:02d}"
            cell_text[(row, 3)] = "tam ruoi"
            ink.append((row, 2))
    page, _ = make_page(
        rows=ROWS,
        columns=SCORE_SHEET,
        headers=SCORE_HEADERS,
        header_height=45,
        cell_text=cell_text,
        ink_cells=tuple(ink),
        struck_rows=(STRUCK,),
        first_stt=39,
    )
    return encode_png(photograph(page, angle=2.0, perspective=0.02))


class StubCrnn:
    """Numeric reader: STT cells are read as 39, 40, ... in call order; score cells as '8.5'."""

    sha256 = "a" * 64

    def __init__(self, score_text: str = "8.5", score_conf: float = 0.97, stt_values=None) -> None:
        self.score_text, self.score_conf = score_text, score_conf
        self.stt_values = stt_values
        self.stt_calls = 0

    def read_stt(self, images):
        out = []
        for index, _ in enumerate(images):
            self.stt_calls += 1
            number = self.stt_values[index] if self.stt_values else 39 + index
            out.append(SttRead(str(number) if number else "", number or None, 0.98 if number else 0.0))
        return out

    def read_cells(self, images):
        return [CellRead(self.score_text, self.score_conf, self.score_conf, self.score_conf) for _ in images]


class StubVietOcr:
    """Điểm chữ: mọi ô điểm chữ đọc ra 'tám rưỡi' (mô hình tinh chỉnh); không bao giờ nhận ô họ tên."""

    sha256 = "b" * 64

    def __init__(self, written: str = "tám rưỡi", written_prob: float = 0.95) -> None:
        self.written, self.written_prob = written, written_prob
        self.calls: list[int] = []

    def read_cells(self, images):
        self.calls.append(len(images))
        return [TextRead(self.written, self.written_prob) for _ in images]


class StubNameReader:
    """Họ tên in: mô hình VietOCR gốc, tách biệt với mô hình điểm chữ."""

    sha256 = "c" * 64

    def __init__(self) -> None:
        self.calls: list[int] = []

    def read_cells(self, images):
        self.calls.append(len(images))
        return [TextRead("Họ tên giả", 0.93) for _ in images]


VERSION = "crnn-dot5+vietocr-tang4+name-vgg:abcdef012345"


def build(crnn=None, vietocr=None, name=None) -> WeightsRecognitionModel:
    return WeightsRecognitionModel(crnn or StubCrnn(), vietocr or StubVietOcr(), name or StubNameReader(), VERSION)


class WeightsModelTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.image = sheet_photo()
        cls.result = build().recognize(cls.image)

    def test_one_row_per_table_row_with_version_and_page_start(self) -> None:
        self.assertEqual(len(self.result.rows), ROWS)
        self.assertEqual(self.result.model_version, VERSION)
        self.assertEqual([r.row_index for r in self.result.rows], list(range(1, ROWS + 1)))
        self.assertIsNone(self.result.page_start_stt)

    def test_both_channels_are_preserved_with_decimal_values(self) -> None:
        row = self.result.rows[0]
        self.assertFalse(row.struck)
        self.assertEqual(row.numeric.value, Decimal("8.5"))
        self.assertEqual(row.numeric.raw_output, "8.5")
        self.assertEqual(row.numeric.confidence, Decimal("0.9700"))
        self.assertEqual(row.written.value, Decimal("8.5"))
        self.assertEqual(row.written.raw_output, "tám rưỡi")
        self.assertEqual(row.written.confidence, Decimal("0.9500"))
        self.assertEqual(row.name.raw_output, "Họ tên giả")

    def test_names_are_read_by_the_name_model_and_written_grades_by_the_other(self) -> None:
        vietocr, name = StubVietOcr(), StubNameReader()
        result = build(vietocr=vietocr, name=name).recognize(self.image)
        self.assertEqual(sum(vietocr.calls), sum(1 for r in result.rows if not r.written.is_blank))
        self.assertEqual(sum(name.calls), sum(1 for r in result.rows if not r.name.is_blank))
        self.assertTrue(all(r.name.raw_output == "Họ tên giả" for r in result.rows if not r.name.is_blank))
        self.assertTrue(all(r.written.raw_output == "tám rưỡi" for r in result.rows if not r.written.is_blank))

    def test_struck_and_blank_rows_have_blank_channels_and_no_reading(self) -> None:
        struck = self.result.rows[STRUCK]
        self.assertTrue(struck.struck)
        for channel in (struck.numeric, struck.written):
            self.assertTrue(channel.is_blank)
            self.assertIsNone(channel.value)
        self.assertTrue(struck.stt.is_blank and struck.name.is_blank)
        blank = self.result.rows[BLANK]
        self.assertFalse(blank.struck)
        self.assertTrue(blank.numeric.is_blank and blank.written.is_blank)

    def test_crops_are_png_bytes_for_every_row(self) -> None:
        for row in self.result.rows:
            for crop in (row.numeric_crop, row.written_crop, row.name_crop):
                self.assertTrue(crop.startswith(b"\x89PNG"))

    def test_written_noise_is_not_turned_into_a_grade(self) -> None:
        noisy = build(vietocr=StubVietOcr(written="qqqq zzzz xx")).recognize(self.image)
        row = noisy.rows[0]
        self.assertEqual(row.written.raw_output, "qqqq zzzz xx")
        self.assertIsNone(row.written.value)
        self.assertFalse(row.written.is_blank)  # ink present, text unreadable
        self.assertEqual(row.numeric.value, Decimal("8.5"))

    def test_one_edit_typo_is_snapped_but_value_comes_from_the_dictionary(self) -> None:
        typo = build(vietocr=StubVietOcr(written="tám rưởi")).recognize(self.image)
        self.assertEqual(typo.rows[0].written.value, Decimal("8.5"))
        self.assertEqual(typo.rows[0].written.raw_output, "tám rưởi")  # raw output is preserved

    def test_invalid_numeric_text_is_unreadable_not_clamped(self) -> None:
        for text in ("11", "7.55", "", "."):
            result = build(crnn=StubCrnn(score_text=text)).recognize(self.image)
            self.assertIsNone(result.rows[0].numeric.value, text)

    def test_stt_is_never_read(self) -> None:
        # Project decision (BE-19b): the goal is the score and written-score columns; STT is not recognised.
        crnn = StubCrnn()
        result = build(crnn=crnn).recognize(self.image)
        self.assertEqual(crnn.stt_calls, 0)
        self.assertIsNone(result.page_start_stt)
        for row in result.rows:
            self.assertIsNone(row.stt.value)
            self.assertIsNone(row.stt.raw_output)
            self.assertEqual(row.stt.confidence, Decimal("0"))
            self.assertTrue(row.stt.is_blank)

    def test_stt_fields_serialise_as_null_value_and_zero_confidence(self) -> None:
        with patch("src.api.main.configured_model", return_value=build()):
            response = TestClient(app).post(
                "/v1/recognize", files={"image": ("s.png", self.image, "image/png")}
            )
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertIsNone(body["pageStartStt"])
        for row in body["rows"]:
            self.assertEqual(
                row["stt"],
                {"raw": None, "value": None, "confidence": "0", "isBlank": True},
            )

    def test_empty_image_and_unusable_photo_raise(self) -> None:
        with self.assertRaises(ValueError):
            build().recognize(b"")
        with self.assertRaises(PipelineError) as caught:
            build().recognize(b"not an image")
        self.assertEqual(caught.exception.code, "IMAGE_UNREADABLE")


class ConfiguredModelTest(unittest.TestCase):
    def test_fake_is_only_for_development_and_test(self) -> None:
        for env in ("development", "test"):
            self.assertEqual(
                configured_model({"APP_ENV": env, "RECOGNITION_MODEL_MODE": "fake"}).__class__.__name__,
                "FakeRecognitionModel",
            )
        for env in ("production", "staging", ""):
            with self.assertRaises(ModelUnavailableError):
                configured_model({"APP_ENV": env, "RECOGNITION_MODEL_MODE": "fake"})

    def test_weights_mode_without_or_with_bad_configuration_is_unavailable(self) -> None:
        good = {
            "APP_ENV": "production",
            "RECOGNITION_MODEL_MODE": "weights",
            "RECOGNITION_CRNN_WEIGHTS": "/models/crnn.pth",
            "RECOGNITION_CRNN_SHA256": "a" * 64,
            "RECOGNITION_VIETOCR_WEIGHTS": "/models/vietocr.pth",
            "RECOGNITION_VIETOCR_SHA256": "b" * 64,
            "RECOGNITION_NAME_WEIGHTS": "/models/name.pth",
            "RECOGNITION_NAME_SHA256": "c" * 64,
        }
        cases = [
            {"APP_ENV": "production"},  # default mode is weights, nothing configured
            {k: v for k, v in good.items() if k != "RECOGNITION_VIETOCR_WEIGHTS"},
            {k: v for k, v in good.items() if k != "RECOGNITION_CRNN_WEIGHTS"},
            {**good, "RECOGNITION_CRNN_SHA256": ""},
            {**good, "RECOGNITION_VIETOCR_SHA256": "xyz"},
            # thiếu mô hình tên thì báo không dùng được, KHÔNG lặng lẽ dùng mô hình điểm chữ
            {k: v for k, v in good.items() if k != "RECOGNITION_NAME_WEIGHTS"},
            {**good, "RECOGNITION_NAME_WEIGHTS": ""},
            {k: v for k, v in good.items() if k != "RECOGNITION_NAME_SHA256"},
            {**good, "RECOGNITION_NAME_SHA256": "xyz"},
            good,  # files do not exist
            {**good, "RECOGNITION_DEVICE": "tpu"},
            {**good, "RECOGNITION_MODEL_MODE": "other"},
        ]
        for env in cases:
            with self.assertRaises(ModelUnavailableError, msg=str(env)):
                configured_model(env)

    def test_wrong_hash_on_an_existing_file_is_unavailable(self) -> None:
        import tempfile

        with tempfile.TemporaryDirectory() as directory:
            crnn = Path(directory) / "crnn.pth"
            ocr = Path(directory) / "vietocr.pth"
            name = Path(directory) / "name.pth"
            crnn.write_bytes(b"x")
            ocr.write_bytes(b"y")
            name.write_bytes(b"z")
            env = {
                "APP_ENV": "production",
                "RECOGNITION_MODEL_MODE": "weights",
                "RECOGNITION_CRNN_WEIGHTS": str(crnn),
                "RECOGNITION_CRNN_SHA256": "0" * 64,
                "RECOGNITION_VIETOCR_WEIGHTS": str(ocr),
                "RECOGNITION_VIETOCR_SHA256": "0" * 64,
                "RECOGNITION_NAME_WEIGHTS": str(name),
                "RECOGNITION_NAME_SHA256": "0" * 64,
            }
            with self.assertRaises(ModelUnavailableError):
                configured_model(env)

    def test_valid_configuration_loads_once_and_builds_the_version_from_all_hashes(self) -> None:
        crnn, ocr, name = StubCrnn(), StubVietOcr(), StubNameReader()
        env = {
            "APP_ENV": "production",
            "RECOGNITION_MODEL_MODE": "weights",
            "RECOGNITION_CRNN_WEIGHTS": "/m/c.pth",
            "RECOGNITION_CRNN_SHA256": "a" * 64,
            "RECOGNITION_VIETOCR_WEIGHTS": "/m/v.pth",
            "RECOGNITION_VIETOCR_SHA256": "b" * 64,
            "RECOGNITION_NAME_WEIGHTS": "/m/n.pth",
            "RECOGNITION_NAME_SHA256": "c" * 64,
        }
        model_module._WEIGHTS_CACHE.clear()
        with patch("src.adapters.crnn.CrnnReader.load", return_value=crnn) as load_crnn, patch(
            "src.adapters.vietocr_reader.VietOcrReader.load", side_effect=[ocr, name]
        ) as load_ocr:
            first = configured_model(env)
            second = configured_model(env)
        self.assertIs(first, second)
        self.assertEqual((load_crnn.call_count, load_ocr.call_count), (1, 2))
        # mô hình điểm chữ và mô hình tên là hai tệp riêng, nạp theo đường dẫn riêng
        self.assertEqual(
            [call.args[0] for call in load_ocr.call_args_list], [Path("/m/v.pth"), Path("/m/n.pth")]
        )
        self.assertIs(first._vietocr, ocr)
        self.assertIs(first._name_reader, name)
        self.assertRegex(first._version, r"^crnn-dot5\+vietocr-tang4\+name-vgg:[0-9a-f]{12}$")
        model_module._WEIGHTS_CACHE.clear()


class HttpErrorContractTest(unittest.IsolatedAsyncioTestCase):
    @staticmethod
    def upload(content: bytes = b"png") -> UploadFile:
        import io

        return UploadFile(filename="sheet.png", file=io.BytesIO(content))

    class Raising:
        def __init__(self, error: Exception) -> None:
            self.error = error

        def recognize(self, image: bytes):
            raise self.error

    async def test_every_pipeline_code_is_a_422_with_a_stable_code(self) -> None:
        for code in (
            "IMAGE_UNREADABLE",
            "IMAGE_QUALITY_LOW",
            "GRID_NOT_FOUND",
            "NOT_A_GRADEBOOK",
            "SCORE_COLUMN_NOT_FOUND",
        ):
            with patch("src.api.main.configured_model", return_value=self.Raising(PipelineError(code, "chi tiết"))):
                with self.assertRaises(HTTPException) as caught:
                    await recognize(image=self.upload())
            self.assertEqual(caught.exception.status_code, 422, code)
            self.assertEqual(caught.exception.detail["code"], code)
            self.assertEqual(caught.exception.detail["message"], "chi tiết")

    async def test_unavailable_model_stays_503(self) -> None:
        with patch(
            "src.api.main.configured_model", side_effect=ModelUnavailableError("no weights")
        ):
            with self.assertRaises(HTTPException) as caught:
                await recognize(image=self.upload())
        self.assertEqual((caught.exception.status_code, caught.exception.detail), (503, "MODEL_UNAVAILABLE"))

    async def test_invalid_threshold_configuration_is_unavailable_not_a_crash(self) -> None:
        env = {"APP_ENV": "test", "RECOGNITION_MODEL_MODE": "fake", "RECOGNITION_NUMERIC_THRESHOLD": "7"}
        with patch.dict(os.environ, env, clear=True):
            with self.assertRaises(HTTPException) as caught:
                await recognize(image=self.upload())
        self.assertEqual(caught.exception.status_code, 503)

    async def test_floors_from_the_environment_demote_an_agreement_to_yellow(self) -> None:
        # Fake rows read 0.95 (numeric) and 0.93 (written), with the same value on both channels: the research
        # rule makes them green; only the optional agreement floors (default 0) can demote them.
        base = {"APP_ENV": "test", "RECOGNITION_MODEL_MODE": "fake"}
        with patch.dict(os.environ, base, clear=True):
            green = await recognize(image=self.upload())
        self.assertEqual(green.rows[0].reviewLevel, "XANH")
        self.assertEqual(green.rows[0].suggestedSource, "SO")
        strict = {**base, "RECOGNITION_NUMERIC_FLOOR": "0.99"}
        with patch.dict(os.environ, strict, clear=True):
            yellow = await recognize(image=self.upload())
        self.assertEqual(yellow.rows[0].reviewLevel, "VANG")
        self.assertEqual(yellow.rows[0].suggestedSource, "SO")
        strict_written = {**base, "RECOGNITION_WRITTEN_FLOOR": "0.99"}
        with patch.dict(os.environ, strict_written, clear=True):
            self.assertEqual((await recognize(image=self.upload())).rows[0].reviewLevel, "VANG")
        with patch.dict(os.environ, {**base, "RECOGNITION_NUMERIC_FLOOR": "abc"}, clear=True):
            with self.assertRaises(HTTPException) as caught:
                await recognize(image=self.upload())
        self.assertEqual(caught.exception.status_code, 503)

    def test_http_body_carries_the_code(self) -> None:
        with patch(
            "src.api.main.configured_model",
            return_value=self.Raising(PipelineError("GRID_NOT_FOUND", "x")),
        ):
            response = TestClient(app).post(
                "/v1/recognize", files={"image": ("s.png", b"png", "image/png")}
            )
        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["detail"]["code"], "GRID_NOT_FOUND")

    def test_a_real_photo_through_the_endpoint_returns_the_new_contract(self) -> None:
        crnn, ocr = StubCrnn(), StubVietOcr()
        model = WeightsRecognitionModel(crnn, ocr, StubNameReader(), VERSION)
        with patch("src.api.main.configured_model", return_value=model):
            response = TestClient(app).post(
                "/v1/recognize", files={"image": ("s.png", sheet_photo(), "image/png")}
            )
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(set(body), {"modelVersion", "pageStartStt", "rows"})
        self.assertEqual(len(body["rows"]), ROWS)
        first = body["rows"][0]
        self.assertEqual(first["numeric"]["value"], "8.5")
        self.assertEqual(first["written"]["value"], "8.5")
        self.assertEqual(first["reviewLevel"], "XANH")
        self.assertEqual(body["rows"][STRUCK]["reviewLevel"], "DO")
        self.assertEqual(body["rows"][BLANK]["comparison"], "KHONG_DOC_DUOC")


@unittest.skipUnless(
    os.getenv("RECOGNITION_CRNN_WEIGHTS")
    and os.getenv("RECOGNITION_VIETOCR_WEIGHTS")
    and os.getenv("RECOGNITION_NAME_WEIGHTS"),
    "real weights are not configured (no weights in CI)",
)
class RealWeightsEndToEndTest(unittest.TestCase):
    def test_real_models_run_on_a_synthetic_sheet(self) -> None:
        env = {
            "APP_ENV": "production",
            "RECOGNITION_MODEL_MODE": "weights",
            **{
                k: os.environ[k]
                for k in ("RECOGNITION_CRNN_WEIGHTS", "RECOGNITION_VIETOCR_WEIGHTS", "RECOGNITION_NAME_WEIGHTS")
            },
        }
        from src.adapters.crnn import sha256_of

        env["RECOGNITION_CRNN_SHA256"] = os.getenv("RECOGNITION_CRNN_SHA256") or sha256_of(
            Path(env["RECOGNITION_CRNN_WEIGHTS"])
        )
        env["RECOGNITION_VIETOCR_SHA256"] = os.getenv("RECOGNITION_VIETOCR_SHA256") or sha256_of(
            Path(env["RECOGNITION_VIETOCR_WEIGHTS"])
        )
        env["RECOGNITION_NAME_SHA256"] = os.getenv("RECOGNITION_NAME_SHA256") or sha256_of(
            Path(env["RECOGNITION_NAME_WEIGHTS"])
        )
        result = configured_model(env).recognize(sheet_photo())
        self.assertEqual(len(result.rows), ROWS)
        self.assertRegex(result.model_version, r"^crnn-dot5\+vietocr-tang4\+name-vgg:[0-9a-f]{12}$")


if __name__ == "__main__":
    unittest.main()
