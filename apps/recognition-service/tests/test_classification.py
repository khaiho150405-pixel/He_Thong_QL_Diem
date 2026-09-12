from decimal import Decimal
from unittest import TestCase

from src.domain import (
    ChannelPrediction,
    Classification,
    Comparison,
    ReviewLevel,
    classify_channels,
)


def prediction(
    value: str | None,
    confidence: str | None,
    *,
    blank: bool = False,
) -> ChannelPrediction:
    return ChannelPrediction(
        raw_output=value,
        value=None if value is None else Decimal(value),
        confidence=None if confidence is None else Decimal(confidence),
        is_blank=blank,
    )


class ClassificationTest(TestCase):
    threshold = Decimal("0.85")

    def classify(
        self, numeric: ChannelPrediction, written: ChannelPrediction
    ):
        return classify_channels(
            numeric, written, green_confidence=self.threshold
        )

    def test_matching_confident_channels_are_green(self) -> None:
        result = self.classify(
            prediction("8.5", "0.93"), prediction("8.5", "0.91")
        )
        self.assertEqual(result.comparison, Comparison.MATCH)
        self.assertEqual(result.level, ReviewLevel.GREEN)

    def test_zero_is_a_real_matching_grade(self) -> None:
        result = self.classify(
            prediction("0.0", "0.99"), prediction("0.0", "0.98")
        )
        self.assertEqual(result.level, ReviewLevel.GREEN)

    def test_low_confidence_match_and_mismatch_are_yellow(self) -> None:
        low = self.classify(
            prediction("7.0", "0.84"), prediction("7.0", "0.95")
        )
        mismatch = self.classify(
            prediction("7.0", "0.95"), prediction("8.0", "0.95")
        )
        self.assertEqual(low, Classification(Comparison.MATCH, ReviewLevel.YELLOW))
        self.assertEqual(
            mismatch,
            Classification(Comparison.MISMATCH, ReviewLevel.YELLOW),
        )

    def test_one_readable_channel_is_yellow(self) -> None:
        result = self.classify(
            prediction("9.0", "0.90"), prediction(None, None, blank=True)
        )
        self.assertEqual(
            result,
            Classification(Comparison.ONE_CHANNEL, ReviewLevel.YELLOW),
        )

    def test_blank_or_unreadable_pair_is_red(self) -> None:
        blank = prediction(None, None, blank=True)
        unreadable = prediction(None, Decimal("0.10").to_eng_string())
        self.assertEqual(
            self.classify(blank, unreadable),
            Classification(Comparison.UNREADABLE, ReviewLevel.RED),
        )

    def test_contract_rejects_invalid_grade_confidence_and_threshold(self) -> None:
        with self.assertRaises(ValueError):
            prediction("8.55", "0.9")
        with self.assertRaises(ValueError):
            prediction("10.1", "0.9")
        with self.assertRaises(ValueError):
            prediction("NaN", "0.9")
        with self.assertRaises(ValueError):
            prediction("8.0", "1.1")
        with self.assertRaises(ValueError):
            classify_channels(
                prediction("8.0", "0.9"),
                prediction("8.0", "0.9"),
                green_confidence=Decimal("1.1"),
            )
