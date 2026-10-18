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
from src.domain import ChannelPrediction, classify_channels, floors_from_env, thresholds_from_env
from src.domain.layout import InvalidLayoutError, parse_layout
from src.pipeline.errors import PipelineError
from src.pipeline.template_match import nguong_khop_mau


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
    # Kênh cho giá trị gợi ý: "SO" | "CHU"; null khi Đỏ (không gợi ý giá trị).
    suggestedSource: str | None = None
    # Đối chiếu STT (RECOGNITION_STT_CHECK=1): STT đọc ở ô STT in, STT suy theo vị trí dòng; null khi tắt/không có. `stt.value` là
    # STT trên giấy = giá trị khi hai nguồn trùng nhau.
    sttRead: int | None = None
    sttFromPosition: int | None = None


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
        numeric_floor, written_floor = floors_from_env(os.environ)
    except ValueError as error:
        raise HTTPException(status_code=503, detail="MODEL_UNAVAILABLE") from error
    rows: list[RowResponse] = []
    for item in result.rows:
        classification = classify_channels(
            item.numeric,
            item.written,
            numeric_confidence=numeric_threshold,
            written_confidence=written_threshold,
            numeric_floor=numeric_floor,
            written_floor=written_floor,
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
                sttRead=item.stt_read,
                sttFromPosition=item.stt_from_position,
                suggestedSource=(
                    classification.suggestion.value if classification.suggestion else None
                ),
            )
        )
    return RecognitionResponse(
        modelVersion=result.model_version,
        pageStartStt=result.page_start_stt,
        rows=rows,
    )


# ── Contract v2 (ADR-0016): phân tích bố cục, khớp mẫu, đọc nhiều cột. /v1/recognize ở trên không đổi. ──


class SignatureResponse(BaseModel):
    version: int
    columnWidths: list[float]
    headerTexts: list[str]
    headerRows: int
    rowHeightMm: float
    tableWidthMm: float


class LayoutColumnResponse(BaseModel):
    index: int
    # Tỉ lệ 0–1 theo bề rộng bảng.
    x0: float
    x1: float
    widthMm: float
    headerText: str
    # STT | HO_TEN | DIEM | DIEM_CHU | BO_QUA; null khi không đọc được tiêu đề.
    suggestedRole: str | None
    # TX | GK | CK cho cột DIEM; null khi không suy ra được.
    suggestedGroup: str | None
    suggestedOrder: int | None


class LayoutAnalyzeResponse(BaseModel):
    signature: SignatureResponse
    columns: list[LayoutColumnResponse]
    previewPngBase64: str


class GradeResponse(BaseModel):
    key: str
    numeric: ChannelResponse
    # null khi cột chỉ có kênh số; khi đó tối đa Vàng (D-01).
    written: ChannelResponse | None
    numericCropBase64: str
    writtenCropBase64: str | None
    comparison: str
    reviewLevel: str
    suggestedSource: str | None = None


class RowV2Response(BaseModel):
    rowIndex: int = Field(ge=1)
    struck: bool
    stt: SttResponse
    name: NameResponse
    nameCropBase64: str
    sttRead: int | None = None
    sttFromPosition: int | None = None
    grades: list[GradeResponse]


class TemplateMatchResponse(BaseModel):
    score: float
    # {chỉ số cột mẫu: chỉ số cột ảnh}
    columnMap: dict[int, int]


class RecognitionV2Response(BaseModel):
    modelVersion: str
    pageStartStt: int | None
    templateMatch: TemplateMatchResponse
    rows: list[RowV2Response]


MAX_IMAGE_BYTES = 10 * 1024 * 1024


def _http_error(status: int, code: str, message: str, details: dict | None = None) -> HTTPException:
    body: dict = {"code": code, "message": message}
    if details:
        body["details"] = details
    return HTTPException(status_code=status, detail=body)


def _pipeline_http_error(error: PipelineError) -> HTTPException:
    return _http_error(422, error.code, error.detail, error.details)


async def _read_image(image: UploadFile) -> bytes:
    content = await image.read(MAX_IMAGE_BYTES + 1)
    if not content or len(content) > MAX_IMAGE_BYTES:
        raise _http_error(422, "IMAGE_UNREADABLE", "Ảnh rỗng hoặc vượt 10 MB.")
    return content


@app.post("/v2/layout/analyze", response_model=LayoutAnalyzeResponse)
async def analyze_layout(image: UploadFile = File()) -> LayoutAnalyzeResponse:
    """Phân tích ảnh một tờ có kẻ ô thành các cột (kèm vai trò gợi ý) và chữ ký lưới. Không lưu gì."""
    content = await _read_image(image)
    try:
        model = configured_model()
        result = await run_in_threadpool(model.analyze_layout, content)
    except ModelUnavailableError as error:
        raise HTTPException(status_code=503, detail="MODEL_UNAVAILABLE") from error
    except PipelineError as error:
        raise _pipeline_http_error(error) from error
    layout = result.layout
    return LayoutAnalyzeResponse(
        signature=SignatureResponse(**layout.signature),
        columns=[
            LayoutColumnResponse(
                index=c.index,
                x0=c.x0,
                x1=c.x1,
                widthMm=c.width_mm,
                headerText=c.header_text,
                suggestedRole=c.suggested_role,
                suggestedGroup=c.suggested_group,
                suggestedOrder=c.suggested_order,
            )
            for c in layout.columns
        ],
        previewPngBase64=crop(result.preview_png),
    )


@app.post("/v2/recognize", response_model=RecognitionV2Response)
async def recognize_v2(
    image: UploadFile = File(), layout: str = Form()
) -> RecognitionV2Response:
    """Đọc các cột điểm được yêu cầu của một trang theo ``layout``. Không nhận danh sách học sinh."""
    try:
        parsed = parse_layout(layout)
    except InvalidLayoutError as error:
        raise _http_error(422, "INVALID_LAYOUT", str(error)) from error
    content = await _read_image(image)
    try:
        min_score = nguong_khop_mau(os.environ)
        numeric_threshold, written_threshold = thresholds_from_env(os.environ)
        numeric_floor, written_floor = floors_from_env(os.environ)
    except ValueError as error:
        raise HTTPException(status_code=503, detail="MODEL_UNAVAILABLE") from error
    try:
        model = configured_model()
        result = await run_in_threadpool(model.recognize_v2, content, parsed, min_score)
    except ModelUnavailableError as error:
        raise HTTPException(status_code=503, detail="MODEL_UNAVAILABLE") from error
    except PipelineError as error:
        raise _pipeline_http_error(error) from error
    rows: list[RowV2Response] = []
    for item in result.rows:
        grades: list[GradeResponse] = []
        for cell in item.grades:
            classification = classify_channels(
                cell.numeric,
                # Cột một kênh: kênh chữ coi như trống → chỉ có thể Vàng (kênh số đủ tin cậy) hoặc Đỏ, không bao giờ Xanh.
                cell.written
                if cell.written is not None
                else ChannelPrediction(None, None, None, is_blank=True),
                numeric_confidence=numeric_threshold,
                written_confidence=written_threshold,
                numeric_floor=numeric_floor,
                written_floor=written_floor,
            )
            grades.append(
                GradeResponse(
                    key=cell.key,
                    numeric=channel(cell.numeric),
                    written=channel(cell.written) if cell.written is not None else None,
                    numericCropBase64=crop(cell.numeric_crop),
                    writtenCropBase64=(
                        crop(cell.written_crop) if cell.written_crop is not None else None
                    ),
                    comparison=classification.comparison.value,
                    reviewLevel=classification.level.value,
                    suggestedSource=(
                        classification.suggestion.value if classification.suggestion else None
                    ),
                )
            )
        rows.append(
            RowV2Response(
                rowIndex=item.row_index,
                struck=item.struck,
                stt=stt(item.stt),
                name=name(item.name),
                nameCropBase64=crop(item.name_crop),
                sttRead=item.stt_read,
                sttFromPosition=item.stt_from_position,
                grades=grades,
            )
        )
    return RecognitionV2Response(
        modelVersion=result.model_version,
        pageStartStt=result.page_start_stt,
        templateMatch=TemplateMatchResponse(
            score=result.template_score, columnMap=result.column_map
        ),
        rows=rows,
    )
