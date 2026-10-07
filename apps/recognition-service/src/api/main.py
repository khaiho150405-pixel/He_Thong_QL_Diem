"""HTTP API for the recognition service."""
from __future__ import annotations

import base64
import os
from decimal import Decimal

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, Field

from src.adapters.model import (
    ModelUnavailableError,
    NamePrediction,
    SttPrediction,
    configured_model,
)
from src.domain import ChannelPrediction, classify_channels, thresholds_from_env
from src.pipeline.errors import PipelineError


class ChannelResponse(BaseModel):
    rawOutput: str | None
    value: Decimal | None
    confidence: Decimal | None
    isBlank: bool


class SttResponse(BaseModel):
    raw: str | None
    value: int | None
    confidence: Decimal | None
    isBlank: bool


class NameResponse(BaseModel):
    raw: str | None
    confidence: Decimal | None
    isBlank: bool


class RowResponse(BaseModel):
    rowIndex: int = Field(ge=1)
    struck: bool
    stt: SttResponse
    name: NameResponse
    numeric: ChannelResponse
    written: ChannelResponse
    numericCropBase64: str
    writtenCropBase64: str
    nameCropBase64: str
    comparison: str
    reviewLevel: str


class RecognitionResponse(BaseModel):
    modelVersion: str
    pageStartStt: int | None
    rows: list[RowResponse]


app = FastAPI(title="Gradebook recognition service", version="2.0.0")


def channel(value: ChannelPrediction) -> ChannelResponse:
    return ChannelResponse(
        rawOutput=value.raw_output,
        value=value.value,
        confidence=value.confidence,
        isBlank=value.is_blank,
    )


def stt(value: SttPrediction) -> SttResponse:
    return SttResponse(
        raw=value.raw_output,
        value=value.value,
        confidence=value.confidence,
        isBlank=value.is_blank,
    )


def name(value: NamePrediction) -> NameResponse:
    return NameResponse(
        raw=value.raw_output, confidence=value.confidence, isBlank=value.is_blank
    )


def crop(value: bytes) -> str:
    return base64.b64encode(value).decode("ascii")


@app.get("/health/live")
def live() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/recognize", response_model=RecognitionResponse)
async def recognize(
    image: UploadFile = File(),
    # Deprecated: callers no longer declare a row count (ADR-0015); ignored.
    declaredRows: int | None = Form(default=None),
) -> RecognitionResponse:
    """Read every row of a gradebook photo. The service never receives a roster."""
    del declaredRows
    content = await image.read(10 * 1024 * 1024 + 1)
    if not content or len(content) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=422,
            detail={"code": "IMAGE_UNREADABLE", "message": "Ảnh rỗng hoặc vượt 10 MB."},
        )
    try:
        model = configured_model()
        # Suy luận nặng CPU: chạy ngoài vòng lặp sự kiện để /health vẫn trả lời khi đang xử lý ảnh.
        result = await run_in_threadpool(model.recognize, content)
    except ModelUnavailableError as error:
        raise HTTPException(status_code=503, detail="MODEL_UNAVAILABLE") from error
    except PipelineError as error:
        # Ảnh không dùng được (mờ, không có bảng, không phải bảng điểm...): 422 kèm mã ổn định để API đánh dấu LOI.
        raise HTTPException(
            status_code=422, detail={"code": error.code, "message": error.detail}
        ) from error
    try:
        numeric_threshold, written_threshold = thresholds_from_env(os.environ)
    except ValueError as error:
        raise HTTPException(status_code=503, detail="MODEL_UNAVAILABLE") from error
    rows: list[RowResponse] = []
    for item in result.rows:
        classification = classify_channels(
            item.numeric,
            item.written,
            numeric_confidence=numeric_threshold,
            written_confidence=written_threshold,
        )
        rows.append(
            RowResponse(
                rowIndex=item.row_index,
                struck=item.struck,
                stt=stt(item.stt),
                name=name(item.name),
                numeric=channel(item.numeric),
                written=channel(item.written),
                numericCropBase64=crop(item.numeric_crop),
                writtenCropBase64=crop(item.written_crop),
                nameCropBase64=crop(item.name_crop),
                comparison=classification.comparison.value,
                reviewLevel=classification.level.value,
            )
        )
    return RecognitionResponse(
        modelVersion=result.model_version,
        pageStartStt=result.page_start_stt,
        rows=rows,
    )
