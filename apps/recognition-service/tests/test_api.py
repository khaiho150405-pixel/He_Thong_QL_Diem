import os
from unittest import IsolatedAsyncioTestCase, TestCase
from unittest.mock import patch

from fastapi import HTTPException, UploadFile

from src.adapters.model import ModelUnavailableError, configured_model
from src.api.main import recognize


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
        upload = UploadFile(filename="sheet.png", file=__import__("io").BytesIO(b"png"))
        with patch.dict(
            os.environ,
            {"APP_ENV": "test", "RECOGNITION_MODEL_MODE": "fake"},
            clear=False,
        ):
            response = await recognize(declaredRows=2, image=upload)
        self.assertEqual(response.detectedRows, 2)
        self.assertEqual(len(response.rows), 2)
        self.assertEqual(response.rows[0].numeric.value, 8)
        self.assertEqual(response.rows[0].written.rawOutput, "tám")
        self.assertEqual(response.rows[0].reviewLevel, "XANH")

    async def test_missing_weights_returns_service_unavailable(self) -> None:
        upload = UploadFile(filename="sheet.png", file=__import__("io").BytesIO(b"png"))
        with patch.dict(os.environ, {"APP_ENV": "production"}, clear=True):
            with self.assertRaises(HTTPException) as caught:
                await recognize(declaredRows=1, image=upload)
        self.assertEqual(caught.exception.status_code, 503)
