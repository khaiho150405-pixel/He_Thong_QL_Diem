"""Rules for comparing numeric and written-grade recognition channels.

Luật hợp nhất hai kênh (BE-21/22) lấy từ ``ket_hop/hop_nhat.py::hop_nhat_mot_o`` của nghiên cứu, đổi sang ba màu:

* Hai kênh cùng một giá trị hợp lệ (đồng thuận) → XANH, giá trị chung (kèm mức sàn mỗi kênh, mặc định 0 = đúng nghiên
  cứu; dưới sàn thì hạ xuống VÀNG, vẫn gợi ý giá trị chung).
* Chỉ kênh số đủ tin cậy (≥ τ số; kênh chữ yếu, không hợp lệ hoặc khác giá trị) → VÀNG, gợi ý giá trị kênh số.
* Chỉ kênh chữ đủ tin cậy (≥ τ chữ; kênh số yếu, không hợp lệ hoặc khác giá trị) → VÀNG, gợi ý giá trị kênh chữ.
* Cả hai mạnh nhưng mâu thuẫn, cả hai yếu hoặc không kênh nào hợp lệ → ĐỎ, KHÔNG gợi ý giá trị (không có trọng tài
  hiệu chuẩn nhiệt độ của nghiên cứu).

"Đủ tin cậy" của dòng Xanh nghĩa là hai kênh ĐỘC LẬP (mô hình số và mô hình chữ) đồng thuận, không cần độ tin cậy
riêng từng kênh vượt ngưỡng. Hai kênh thô, giá trị chuẩn hóa và độ tin cậy luôn được giữ nguyên trong dữ liệu trả về.
"""

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


class Suggestion(StrEnum):
    """Kênh cho giá trị gợi ý (máy chỉ đề xuất; người duyệt mới chốt)."""

    NUMERIC = "SO"
    WRITTEN = "CHU"


@dataclass(frozen=True, slots=True)
class Classification:
    comparison: Comparison
    level: ReviewLevel
    # Kênh có giá trị được gợi ý; None khi Đỏ (không gợi ý giá trị). Khi hai kênh đồng thuận, hai giá trị bằng nhau
    # nên chọn NUMERIC.
    suggestion: Suggestion | None = None


# Ngưỡng riêng từng kênh (τ của nghiên cứu: ket_hop/ket_qua/tang4/cau_hinh_hop_nhat_dev_co_mai.json): độ tin cậy
# CRNN+CTC và VietOCR không cùng thang đo nên không dùng chung một ngưỡng.
DEFAULT_NUMERIC_THRESHOLD = Decimal("0.95")
DEFAULT_WRITTEN_THRESHOLD = Decimal("0.90")
# Mức sàn đồng thuận mỗi kênh; 0 = đúng luật nghiên cứu (đồng thuận luôn Xanh). Giá trị đã khóa ở BE-22.
DEFAULT_NUMERIC_FLOOR = Decimal("0.00")
DEFAULT_WRITTEN_FLOOR = Decimal("0.00")


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


def floors_from_env(env: Mapping[str, str]) -> tuple[Decimal, Decimal]:
    """(sàn điểm số, sàn điểm chữ) của nhánh đồng thuận từ ``RECOGNITION_NUMERIC_FLOOR`` / ``RECOGNITION_WRITTEN_FLOOR``."""
    try:
        numeric = Decimal(env.get("RECOGNITION_NUMERIC_FLOOR", str(DEFAULT_NUMERIC_FLOOR)))
        written = Decimal(env.get("RECOGNITION_WRITTEN_FLOOR", str(DEFAULT_WRITTEN_FLOOR)))
    except InvalidOperation as error:
        raise ValueError("Floor must be a decimal number") from error
    return _check_threshold(numeric), _check_threshold(written)


def classify_channels(
    numeric: ChannelPrediction,
    written: ChannelPrediction,
    *,
    numeric_confidence: Decimal | None = None,
    written_confidence: Decimal | None = None,
    numeric_floor: Decimal | None = None,
    written_floor: Decimal | None = None,
) -> Classification:
    """Phân loại ba màu theo luật hợp nhất (xem docstring module); hai dự đoán gốc không bị sửa.

    ``numeric_confidence``/``written_confidence`` là τ của từng kênh; ``numeric_floor``/``written_floor`` là sàn của
    nhánh đồng thuận. Kênh không có giá trị hợp lệ coi như độ tin cậy 0 (như ``hop_nhat_mot_o``).
    """
    tau_numeric = _check_threshold(
        numeric_confidence if numeric_confidence is not None else DEFAULT_NUMERIC_THRESHOLD
    )
    tau_written = _check_threshold(
        written_confidence if written_confidence is not None else DEFAULT_WRITTEN_THRESHOLD
    )
    floor_numeric = _check_threshold(numeric_floor if numeric_floor is not None else DEFAULT_NUMERIC_FLOOR)
    floor_written = _check_threshold(written_floor if written_floor is not None else DEFAULT_WRITTEN_FLOOR)

    zero = Decimal("0")
    numeric_score = (numeric.confidence or zero) if numeric.readable else zero
    written_score = (written.confidence or zero) if written.readable else zero

    if numeric.readable and written.readable:
        comparison = Comparison.MATCH if numeric.value == written.value else Comparison.MISMATCH
    elif numeric.readable or written.readable:
        comparison = Comparison.ONE_CHANNEL
    else:
        return Classification(Comparison.UNREADABLE, ReviewLevel.RED)

    if comparison is Comparison.MATCH:
        agreed = numeric_score >= floor_numeric and written_score >= floor_written
        return Classification(
            comparison, ReviewLevel.GREEN if agreed else ReviewLevel.YELLOW, Suggestion.NUMERIC
        )

    strong_numeric = numeric.readable and numeric_score >= tau_numeric
    strong_written = written.readable and written_score >= tau_written
    if strong_numeric and not strong_written:
        return Classification(comparison, ReviewLevel.YELLOW, Suggestion.NUMERIC)
    if strong_written and not strong_numeric:
        return Classification(comparison, ReviewLevel.YELLOW, Suggestion.WRITTEN)
    # Cả hai mạnh mà mâu thuẫn, hoặc cả hai (còn đọc được) cùng yếu: Đỏ, không gợi ý giá trị.
    return Classification(comparison, ReviewLevel.RED)
