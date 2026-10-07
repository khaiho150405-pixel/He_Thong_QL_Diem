"""Rules for comparing numeric and written-grade recognition channels."""

from dataclasses import dataclass
from collections.abc import Mapping
from decimal import Decimal, InvalidOperation
from enum import StrEnum


class Comparison(StrEnum):
    MATCH = "KHOP"
    MISMATCH = "LECH"
    ONE_CHANNEL = "MOT_KENH"
    UNREADABLE = "KHONG_DOC_DUOC"


class ReviewLevel(StrEnum):
    GREEN = "XANH"
    YELLOW = "VANG"
    RED = "DO"


@dataclass(frozen=True, slots=True)
class ChannelPrediction:
    raw_output: str | None
    value: Decimal | None
    confidence: Decimal | None
    is_blank: bool = False

    def __post_init__(self) -> None:
        if self.is_blank and self.value is not None:
            raise ValueError("A blank channel cannot contain a value")
        if self.value is not None and (
            not self.value.is_finite()
            or self.value < Decimal("0.0")
            or self.value > Decimal("10.0")
            or self.value.as_tuple().exponent < -1
        ):
            raise ValueError("Grade must be between 0.0 and 10.0 in 0.1 steps")
        if self.confidence is not None and (
            not self.confidence.is_finite()
            or not Decimal("0.0") <= self.confidence <= Decimal("1.0")
        ):
            raise ValueError("Confidence must be between 0.0 and 1.0")

    @property
    def readable(self) -> bool:
        return not self.is_blank and self.value is not None


@dataclass(frozen=True, slots=True)
class Classification:
    comparison: Comparison
    level: ReviewLevel


# Ngưỡng riêng từng kênh (giá trị khởi điểm từ ket_hop/ket_qua/tang4/cau_hinh_hop_nhat_dev_co_mai.json; dò lại ở
# BE-21–BE-22): độ tin cậy CRNN+CTC và VietOCR không cùng thang đo nên không dùng chung một ngưỡng.
DEFAULT_NUMERIC_THRESHOLD = Decimal("0.95")
DEFAULT_WRITTEN_THRESHOLD = Decimal("0.90")


def _check_threshold(value: Decimal) -> Decimal:
    if not value.is_finite() or not (Decimal("0.0") <= value <= Decimal("1.0")):
        raise ValueError("Threshold must be between 0.0 and 1.0")
    return value


def thresholds_from_env(env: Mapping[str, str]) -> tuple[Decimal, Decimal]:
    """(ngưỡng điểm số, ngưỡng điểm chữ) từ ``RECOGNITION_NUMERIC_THRESHOLD`` / ``RECOGNITION_WRITTEN_THRESHOLD``."""
    try:
        numeric = Decimal(env.get("RECOGNITION_NUMERIC_THRESHOLD", str(DEFAULT_NUMERIC_THRESHOLD)))
        written = Decimal(env.get("RECOGNITION_WRITTEN_THRESHOLD", str(DEFAULT_WRITTEN_THRESHOLD)))
    except InvalidOperation as error:
        raise ValueError("Threshold must be a decimal number") from error
    return _check_threshold(numeric), _check_threshold(written)


def classify_channels(
    numeric: ChannelPrediction,
    written: ChannelPrediction,
    *,
    green_confidence: Decimal | None = None,
    numeric_confidence: Decimal | None = None,
    written_confidence: Decimal | None = None,
) -> Classification:
    """Classify two preserved predictions without selecting a final grade.

    Ngưỡng Xanh riêng từng kênh (``numeric_confidence``/``written_confidence``); ``green_confidence`` là một ngưỡng
    chung dùng khi không đưa ngưỡng riêng. Không có nhánh "trọng tài" chọn giá trị: hai kênh lệch nhau, cùng yếu hoặc
    chỉ một kênh đọc được đều chỉ là Vàng; chỉ khi cả hai kênh không đọc được mới là Đỏ, và không bao giờ gợi ý giá trị.
    """
    numeric_threshold = _check_threshold(
        numeric_confidence if numeric_confidence is not None else green_confidence
        if green_confidence is not None else DEFAULT_NUMERIC_THRESHOLD
    )
    written_threshold = _check_threshold(
        written_confidence if written_confidence is not None else green_confidence
        if green_confidence is not None else DEFAULT_WRITTEN_THRESHOLD
    )

    readable = [channel for channel in (numeric, written) if channel.readable]
    if not readable:
        return Classification(Comparison.UNREADABLE, ReviewLevel.RED)
    if len(readable) == 1:
        return Classification(Comparison.ONE_CHANNEL, ReviewLevel.YELLOW)
    if numeric.value != written.value:
        return Classification(Comparison.MISMATCH, ReviewLevel.YELLOW)

    confident = (
        numeric.confidence is not None
        and numeric.confidence >= numeric_threshold
        and written.confidence is not None
        and written.confidence >= written_threshold
    )
    return Classification(
        Comparison.MATCH,
        ReviewLevel.GREEN if confident else ReviewLevel.YELLOW,
    )
