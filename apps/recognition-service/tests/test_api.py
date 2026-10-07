import io
import os
from unittest import IsolatedAsyncioTestCase, TestCase
from unittest.mock import patch

from fastapi import HTTPException, UploadFile

from src.adapters.model import ModelUnavailableError, configured_model
from src.api.main import recognize

FAKE_ENV = {"APP_ENV": "test", "RECOGNITION_MODEL_MODE": "fake"}


def upload(content: bytes = b"png") -> UploadFile:
    return UploadFile(filename="sheet.png", file=io.BytesIO(content))


class AdapterSelectionTest(TestCase):
    def test_fake_is_explicit_and_cannot_run_in_production(self) -> None:
        self.assertEqual(
            configured_model({"APP_ENV": "test", "RECOGNITION_MODEL_MODE": "fake"})
            .__class__
            .__name__,
            "FakeRecognitionModel",
        )
        with self.assertRaises(ModelUnavailableError):
            configured_model(
                {"APP_ENV": "production", "RECOGNITION_MODEL_MODE": "fake"}
            )
        with self.assertRaises(ModelUnavailableError):
            configured_model({"APP_ENV": "production"})


class ApiContractTest(IsolatedAsyncioTestCase):
    async def test_fake_contract_preserves_both_channels(self) -> None:
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            response = await recognize(image=upload())
        self.assertEqual(response.modelVersion, "fake-dev-v1")
        self.assertEqual(response.pageStartStt, 1)
        self.assertEqual(len(response.rows), 6)
        first = response.rows[0]
        self.assertEqual(first.rowIndex, 1)
        self.assertFalse(first.struck)
        self.assertEqual(str(first.numeric.value), "0.7")
        self.assertEqual(first.written.rawOutput, "không phẩy bảy")
        self.assertEqual(first.reviewLevel, "XANH")
        self.assertEqual(first.comparison, "KHOP")
        self.assertTrue(first.numericCropBase64)
        self.assertTrue(first.writtenCropBase64)
        self.assertTrue(first.nameCropBase64)

    async def test_contract_has_no_detected_rows_or_declared_rows(self) -> None:
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            body = (await recognize(image=upload())).model_dump(mode="json")
        self.assertEqual(set(body), {"modelVersion", "pageStartStt", "rows"})
        self.assertEqual(
            set(body["rows"][0]),
            {
                "rowIndex",
                "struck",
                "stt",
                "name",
                "numeric",
                "written",
                "numericCropBase64",
                "writtenCropBase64",
                "nameCropBase64",
                "comparison",
                "reviewLevel",
                "suggestedSource",
            },
        )
        self.assertEqual(set(body["rows"][0]["stt"]), {"raw", "value", "confidence", "isBlank"})
        self.assertEqual(set(body["rows"][0]["name"]), {"raw", "confidence", "isBlank"})

    async def test_every_row_has_a_different_grade(self) -> None:
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            response = await recognize(image=upload())
        values = [row.numeric.value for row in response.rows]
        self.assertEqual(len(set(values)), len(values))
        self.assertEqual([row.written.value for row in response.rows], values)

    async def test_stt_and_fake_names_are_consecutive_from_start(self) -> None:
        env = {**FAKE_ENV, "FAKE_START_STT": "39", "FAKE_DETECTED_ROWS": "3"}
        with patch.dict(os.environ, env, clear=True):
            response = await recognize(image=upload())
        self.assertEqual(response.pageStartStt, 39)
        self.assertEqual([row.stt.value for row in response.rows], [39, 40, 41])
        self.assertEqual(
            [row.name.raw for row in response.rows],
            ["Học sinh 39", "Học sinh 40", "Học sinh 41"],
        )
        self.assertEqual([row.rowIndex for row in response.rows], [1, 2, 3])

    async def test_struck_rows_are_configurable_and_never_green(self) -> None:
        env = {**FAKE_ENV, "FAKE_STRUCK_ROWS": "2, 4"}
        with patch.dict(os.environ, env, clear=True):
            response = await recognize(image=upload())
        self.assertEqual(
            [row.struck for row in response.rows],
            [False, True, False, True, False, False],
        )
        struck = response.rows[1]
        self.assertTrue(struck.numeric.isBlank)
        self.assertIsNone(struck.numeric.value)
        self.assertEqual(struck.reviewLevel, "DO")
        # STT stays aligned with row position even when a row is struck.
        self.assertEqual([row.stt.value for row in response.rows], [1, 2, 3, 4, 5, 6])

    async def test_invalid_fake_configuration_is_rejected(self) -> None:
        for bad in ({"FAKE_STRUCK_ROWS": "x"}, {"FAKE_START_STT": "0"}):
            with patch.dict(os.environ, {**FAKE_ENV, **bad}, clear=True):
                with self.assertRaises(ValueError):
                    await recognize(image=upload())

    async def test_legacy_declared_rows_is_accepted_and_ignored(self) -> None:
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            response = await recognize(image=upload(), declaredRows=2)
        self.assertEqual(len(response.rows), 6)

    async def test_empty_image_is_rejected(self) -> None:
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            with self.assertRaises(HTTPException) as caught:
                await recognize(image=upload(b""))
        self.assertEqual(caught.exception.status_code, 422)

    async def test_missing_weights_returns_service_unavailable(self) -> None:
        with patch.dict(os.environ, {"APP_ENV": "production"}, clear=True):
            with self.assertRaises(HTTPException) as caught:
                await recognize(image=upload())
        self.assertEqual(caught.exception.status_code, 503)


class HttpContractTest(TestCase):
    def test_multipart_needs_only_the_image(self) -> None:
        from fastapi.testclient import TestClient

        from src.api.main import app

        client = TestClient(app)
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            only_image = client.post(
                "/v1/recognize", files={"image": ("sheet.png", b"png", "image/png")}
            )
            legacy = client.post(
                "/v1/recognize",
                data={"declaredRows": "41"},
                files={"image": ("sheet.png", b"png", "image/png")},
            )
            missing = client.post("/v1/recognize", data={"declaredRows": "41"})
        self.assertEqual(only_image.status_code, 200)
        self.assertEqual(legacy.status_code, 200)
        self.assertEqual(only_image.json(), legacy.json())
        self.assertEqual(missing.status_code, 422)
        body = only_image.json()
        self.assertEqual(body["rows"][0]["stt"]["value"], 1)
        self.assertIsInstance(body["rows"][0]["numeric"]["value"], str)


class SharedContractFixtureTest(TestCase):
    """The API parser (apps/api) is tested against the same golden response."""

    def test_fake_response_matches_the_golden_fixture(self) -> None:
        import json
        from pathlib import Path

        from fastapi.testclient import TestClient

        from src.api.main import app

        fixture = (
            Path(__file__).resolve().parents[2]
            / "api"
            / "test"
            / "fixtures"
            / "recognition-fake-response.json"
        )
        env = {
            **FAKE_ENV,
            "FAKE_DETECTED_ROWS": "3",
            "FAKE_STRUCK_ROWS": "2",
            "FAKE_START_STT": "39",
        }
        with patch.dict(os.environ, env, clear=True):
            body = TestClient(app).post(
                "/v1/recognize", files={"image": ("sheet.png", b"png", "image/png")}
            ).json()
        self.assertEqual(body, json.loads(fixture.read_text(encoding="utf-8")))
