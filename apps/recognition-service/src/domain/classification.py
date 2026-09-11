"""Rules for comparing numeric and written-grade recognition channels."""

from dataclasses import dataclass
from decimal import Decimal
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


def classify_channels(
    numeric: ChannelPrediction,
    written: ChannelPrediction,
    *,
    green_confidence: Decimal,
) -> Classification:
    """Classify two preserved predictions without selecting a final grade."""
    if not green_confidence.is_finite() or not (
        Decimal("0.0") <= green_confidence <= Decimal("1.0")
    ):
        raise ValueError("Green threshold must be between 0.0 and 1.0")

    readable = [channel for channel in (numeric, written) if channel.readable]
    if not readable:
        return Classification(Comparison.UNREADABLE, ReviewLevel.RED)
    if len(readable) == 1:
        return Classification(Comparison.ONE_CHANNEL, ReviewLevel.YELLOW)
    if numeric.value != written.value:
        return Classification(Comparison.MISMATCH, ReviewLevel.YELLOW)

    confidences = (numeric.confidence, written.confidence)
    confident = all(
        confidence is not None and confidence >= green_confidence
        for confidence in confidences
    )
    return Classification(
        Comparison.MATCH,
        ReviewLevel.GREEN if confident else ReviewLevel.YELLOW,
    )
