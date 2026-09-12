from __future__ import annotations

import base64
import os
from decimal import Decimal

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field

from src.adapters.model import ModelUnavailableError, configured_model
from src.domain import ChannelPrediction, classify_channels


class ChannelResponse(BaseModel):
    rawOutput: str | None
    value: Decimal | None
    confidence: Decimal | None
    isBlank: bool


class RowResponse(BaseModel):
    order: int
    numeric: ChannelResponse
    written: ChannelResponse
    numericCropBase64: str
    writtenCropBase64: str
    comparison: str
    reviewLevel: str


class RecognitionResponse(BaseModel):
    detectedRows: int = Field(ge=0)
    modelVersion: str
    rows: list[RowResponse]


app = FastAPI(title="Gradebook recognition service", version="1.0.0")


def channel(value: ChannelPrediction) -> ChannelResponse:
    return ChannelResponse(
        rawOutput=value.raw_output,
        value=value.value,
        confidence=value.confidence,
        isBlank=value.is_blank,
    )


@app.get("/health/live")
def live() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/recognize", response_model=RecognitionResponse)
async def recognize(
    declaredRows: int = Form(ge=1, le=5000),
    image: UploadFile = File(),
) -> RecognitionResponse:
    content = await image.read(10 * 1024 * 1024 + 1)
    if not content or len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=422, detail="INVALID_IMAGE")
    try:
        result = configured_model().recognize(content, declaredRows)
    except ModelUnavailableError as error:
        raise HTTPException(status_code=503, detail="MODEL_UNAVAILABLE") from error
    threshold = Decimal(os.getenv("RECOGNITION_GREEN_THRESHOLD", "0.85"))
    rows: list[RowResponse] = []
    for item in result.rows:
        classification = classify_channels(
            item.numeric, item.written, green_confidence=threshold
        )
        rows.append(
            RowResponse(
                order=item.order,
                numeric=channel(item.numeric),
                written=channel(item.written),
                numericCropBase64=base64.b64encode(item.numeric_crop).decode("ascii"),
                writtenCropBase64=base64.b64encode(item.written_crop).decode("ascii"),
                comparison=classification.comparison.value,
                reviewLevel=classification.level.value,
            )
        )
    return RecognitionResponse(
        detectedRows=result.detected_rows,
        modelVersion=result.model_version,
        rows=rows,
    )
