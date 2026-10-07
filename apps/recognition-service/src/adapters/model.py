from __future__ import annotations

import base64
import hashlib
import os
import threading
from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path
from typing import Any, Mapping

import cv2
import numpy as np

from src.domain import ChannelPrediction

from .errors import ModelUnavailableError


@dataclass(frozen=True, slots=True)
class SttPrediction:
    """Printed row number read from the STT cell; None when it cannot be read."""

    raw_output: str | None
    value: int | None
    confidence: Decimal | None
    is_blank: bool = False


@dataclass(frozen=True, slots=True)
class NamePrediction:
    """Full name as written on paper; the service never sees the class roster."""

    raw_output: str | None
    confidence: Decimal | None
    is_blank: bool = False


@dataclass(frozen=True, slots=True)
class ModelRow:
    row_index: int
    struck: bool
    stt: SttPrediction
    name: NamePrediction
    numeric: ChannelPrediction
    written: ChannelPrediction
    numeric_crop: bytes
    written_crop: bytes
    name_crop: bytes


@dataclass(frozen=True, slots=True)
class ModelResult:
    model_version: str
    page_start_stt: int | None
    rows: tuple[ModelRow, ...]


class RecognitionModel:
    def recognize(self, image: bytes) -> ModelResult:
        raise NotImplementedError


_UNITS = (
    "không",
    "một",
    "hai",
    "ba",
    "bốn",
    "năm",
    "sáu",
    "bảy",
    "tám",
    "chín",
)


def _written(value: Decimal) -> str:
    """Spell a 0.0-10.0 grade the way it is usually written on paper."""
    tenths = int(value * 10)
    whole, fraction = divmod(tenths, 10)
    head = "mười" if whole == 10 else _UNITS[whole]
    return head if fraction == 0 else f"{head} phẩy {_UNITS[fraction]}"


def _int_list(name: str, text: str) -> frozenset[int]:
    try:
        values = frozenset(int(part) for part in text.split(",") if part.strip())
    except ValueError as error:
        raise ValueError(f"{name} must be a comma-separated integer list") from error
    if any(value < 1 for value in values):
        raise ValueError(f"{name} must contain positive row numbers")
    return values


class FakeRecognitionModel(RecognitionModel):
    """Deterministic development adapter; never selected in production.

    FAKE_DETECTED_ROWS (default 6), FAKE_START_STT (default 1) and
    FAKE_STRUCK_ROWS (1-based row positions, default none) shape the page. Every
    row carries a different grade so a misassigned row is visible in tests.
    """

    _pixel = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk"
        "+A8AAQUBAScY42YAAAAASUVORK5CYII="
    )

    def recognize(self, image: bytes) -> ModelResult:
        if not image:
            raise ValueError("Image is empty")
        count = int(os.getenv("FAKE_DETECTED_ROWS", "6"))
        start = int(os.getenv("FAKE_START_STT", "1"))
        struck_rows = _int_list("FAKE_STRUCK_ROWS", os.getenv("FAKE_STRUCK_ROWS", ""))
        if count < 1 or start < 1:
            raise ValueError("FAKE_DETECTED_ROWS and FAKE_START_STT must be >= 1")
        rows = tuple(
            self._row(index, start, index in struck_rows)
            for index in range(1, count + 1)
        )
        return ModelResult("fake-dev-v1", start, rows)

    def _row(self, index: int, start: int, struck: bool) -> ModelRow:
        stt = start + index - 1
        grade = (Decimal((index * 7) % 101) / 10).quantize(Decimal("0.1"))
        if struck:
            numeric = ChannelPrediction(None, None, None, is_blank=True)
            written = ChannelPrediction(None, None, None, is_blank=True)
        else:
            numeric = ChannelPrediction(
                raw_output=str(grade), value=grade, confidence=Decimal("0.95")
            )
            written = ChannelPrediction(
                raw_output=_written(grade), value=grade, confidence=Decimal("0.93")
            )
        return ModelRow(
            row_index=index,
            struck=struck,
            stt=SttPrediction(str(stt), stt, Decimal("0.97")),
            name=NamePrediction(f"Học sinh {stt:02d}", Decimal("0.90")),
            numeric=numeric,
            written=written,
            numeric_crop=self._pixel,
            written_crop=self._pixel,
            name_crop=self._pixel,
        )


PNG_BLANK = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk"
    "+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


def _png(cell: Any) -> bytes:
    """Mã hóa ô ảnh thành PNG; ô thiếu/rỗng thành ảnh trắng 1×1 (hợp đồng yêu cầu ảnh ô không rỗng)."""
    if cell is None or getattr(cell, "size", 0) == 0:
        return PNG_BLANK
    ok, buffer = cv2.imencode(".png", cell)
    return buffer.tobytes() if ok else PNG_BLANK


def _confidence(value: float) -> Decimal:
    return Decimal(f"{min(max(value, 0.0), 1.0):.4f}")


BLANK_CHANNEL = ChannelPrediction(None, None, None, is_blank=True)
STT_NOT_READ = SttPrediction(None, None, Decimal("0"), is_blank=True)


class WeightsRecognitionModel(RecognitionModel):
    """Mô hình thật: ``analyze_page`` (BE-13–15) + CRNN (Đ.số; không đọc STT) + VietOCR (Điểm chữ, Họ tên).

    Dịch vụ không nhận danh sách học sinh; chỉ trả những gì đọc được trên giấy. Kênh điểm chữ đi qua ``nan_diem_chu``
    (chỉ nắn về từ điển khi gần một cụm hợp lệ) rồi ``so_tu_chuoi_chu``; kênh điểm số qua ``so_tu_chuoi_so``. Chuỗi
    không giải ra điểm hợp lệ để ``value=None`` (kênh không đọc được), không bị ép thành một giá trị.
    """

    def __init__(self, crnn_reader: Any, vietocr_reader: Any, model_version: str) -> None:
        self._crnn = crnn_reader
        self._vietocr = vietocr_reader
        self._version = model_version

    def recognize(self, image: bytes) -> ModelResult:
        from src.domain.written_grade import (
            grade_decimal,
            nan_diem_chu,
            so_tu_chuoi_chu,
            so_tu_chuoi_so,
        )
        from src.pipeline.errors import PipelineError
        from src.pipeline.rows import analyze_page

        if not image:
            raise ValueError("Image is empty")
        analysis = analyze_page(image, None)
        rows = analysis.rows
        if not rows:
            raise PipelineError("GRID_NOT_FOUND", "Bảng không có dòng dữ liệu nào.")
        active = [r for r in rows if not r.struck]
        score_rows = [r for r in active if r.score_ink >= 1.0]
        score_reads = dict(
            zip((r.row_index for r in score_rows), self._crnn.read_cells([r.score_cell for r in score_rows]))
        )
        written_rows = [r for r in active if r.written_cell is not None and r.written_ink >= 1.0]
        written_reads = dict(
            zip(
                (r.row_index for r in written_rows),
                self._vietocr.read_cells([r.written_cell for r in written_rows]),
            )
        )
        name_rows = [r for r in active if r.has_name_ink]
        name_reads = dict(
            zip((r.row_index for r in name_rows), self._vietocr.read_cells([r.name_cell for r in name_rows]))
        )

        out: list[ModelRow] = []
        for row in rows:
            i = row.row_index
            # Chủ dự án chốt (BE-19b): KHÔNG đọc STT; mục tiêu là điểm số và điểm chữ. STT luôn là null với độ tin cậy 0,
            # còn việc ghép dòng ↔ học sinh dựa vào họ tên và thứ tự (row-matching.ts đã hỗ trợ ghép không cần STT).
            stt_pred = STT_NOT_READ
            name = name_reads.get(i)
            # Ô họ tên "trống" theo MỰC (không theo việc OCR đọc ra chữ): có mực mà không đọc được vẫn là có dữ liệu.
            name_pred = (
                NamePrediction(None, None, is_blank=True)
                if name is None
                else NamePrediction(
                    name.text or None, _confidence(name.prob) if name.text else None
                )
            )
            numeric = BLANK_CHANNEL
            read = score_reads.get(i)
            if read is not None:
                value = grade_decimal(so_tu_chuoi_so(read.text))
                numeric = ChannelPrediction(
                    read.text or None, value, _confidence(read.conf_mean) if read.text else None
                )
            written = BLANK_CHANNEL
            text = written_reads.get(i)
            if text is not None:
                snapped = nan_diem_chu(text.text)
                written = ChannelPrediction(
                    text.text or None,
                    grade_decimal(so_tu_chuoi_chu(snapped)),
                    _confidence(text.prob) if text.text else None,
                )
            out.append(
                ModelRow(
                    row_index=i,
                    struck=row.struck,
                    stt=stt_pred,
                    name=name_pred,
                    numeric=numeric,
                    written=written,
                    numeric_crop=_png(row.score_cell),
                    written_crop=_png(row.written_cell),
                    name_crop=_png(row.name_cell),
                )
            )
        return ModelResult(self._version, None, tuple(out))


_WEIGHTS_LOCK = threading.Lock()
_WEIGHTS_CACHE: dict[tuple[str, str, str, str, str], WeightsRecognitionModel] = {}


def weights_model(values: Mapping[str, str]) -> WeightsRecognitionModel:
    """Nạp (một lần cho mỗi cấu hình) CRNN + VietOCR từ ``RECOGNITION_*``; thiếu/sai hash/sai tệp → không dùng được."""
    from .crnn import CrnnReader
    from .vietocr_reader import VietOcrReader

    crnn_path = values.get("RECOGNITION_CRNN_WEIGHTS", "")
    crnn_sha = values.get("RECOGNITION_CRNN_SHA256", "")
    ocr_path = values.get("RECOGNITION_VIETOCR_WEIGHTS", "")
    ocr_sha = values.get("RECOGNITION_VIETOCR_SHA256", "")
    device = values.get("RECOGNITION_DEVICE", "cpu")
    if not (crnn_path and ocr_path):
        raise ModelUnavailableError("Recognition weights are not configured")
    if device not in {"cpu", "cuda"}:
        raise ModelUnavailableError("RECOGNITION_DEVICE must be cpu or cuda")
    key = (crnn_path, crnn_sha.lower(), ocr_path, ocr_sha.lower(), device)
    with _WEIGHTS_LOCK:
        cached = _WEIGHTS_CACHE.get(key)
        if cached is not None:
            return cached
        crnn_reader = CrnnReader.load(Path(crnn_path), crnn_sha, device)
        vietocr_reader = VietOcrReader.load(Path(ocr_path), ocr_sha, device)
        digest = hashlib.sha256((crnn_reader.sha256 + vietocr_reader.sha256).encode("ascii")).hexdigest()
        version = f"crnn-dot5+vietocr-tang4:{digest[:12]}"
        model = WeightsRecognitionModel(crnn_reader, vietocr_reader, version)
        _WEIGHTS_CACHE[key] = model
        return model


def configured_model(env: dict[str, str] | None = None) -> RecognitionModel:
    values = os.environ if env is None else env
    environment = values.get("APP_ENV", "production")
    mode = values.get("RECOGNITION_MODEL_MODE", "weights")
    if mode == "fake" and environment in {"development", "test"}:
        return FakeRecognitionModel()
    if mode == "weights":
        return weights_model(values)
    raise ModelUnavailableError("Recognition weights are unavailable")
