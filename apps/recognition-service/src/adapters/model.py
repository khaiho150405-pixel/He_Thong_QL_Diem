from __future__ import annotations

import base64
import os
from dataclasses import dataclass
from decimal import Decimal

from src.domain import ChannelPrediction


class ModelUnavailableError(RuntimeError):
    pass


@dataclass(frozen=True, slots=True)
class ModelRow:
    order: int
    numeric: ChannelPrediction
    written: ChannelPrediction
    numeric_crop: bytes
    written_crop: bytes


@dataclass(frozen=True, slots=True)
class ModelResult:
    detected_rows: int
    model_version: str
    rows: tuple[ModelRow, ...]


class RecognitionModel:
    def recognize(self, image: bytes, declared_rows: int) -> ModelResult:
        raise NotImplementedError


class FakeRecognitionModel(RecognitionModel):
    """Deterministic development adapter; never selected in production."""

    _pixel = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk"
        "+A8AAQUBAScY42YAAAAASUVORK5CYII="
    )

    def recognize(self, image: bytes, declared_rows: int) -> ModelResult:
        if not image:
            raise ValueError("Image is empty")
        detected = int(os.getenv("FAKE_DETECTED_ROWS", str(declared_rows)))
        rows = tuple(
            ModelRow(
                order=order,
                numeric=ChannelPrediction(
                    raw_output="8.0", value=Decimal("8.0"), confidence=Decimal("0.95")
                ),
                written=ChannelPrediction(
                    raw_output="tám", value=Decimal("8.0"), confidence=Decimal("0.93")
                ),
                numeric_crop=self._pixel,
                written_crop=self._pixel,
            )
            for order in range(1, detected + 1)
        )
        return ModelResult(detected, "fake-dev-v1", rows)


def configured_model(env: dict[str, str] | None = None) -> RecognitionModel:
    values = os.environ if env is None else env
    environment = values.get("APP_ENV", "production")
    mode = values.get("RECOGNITION_MODEL_MODE", "weights")
    if mode == "fake" and environment in {"development", "test"}:
        return FakeRecognitionModel()
    raise ModelUnavailableError("Recognition weights are unavailable")
