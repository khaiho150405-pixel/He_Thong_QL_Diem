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


class PerChannelThresholdTest(TestCase):
    def classify(self, numeric, written, **kwargs):
        return classify_channels(numeric, written, **kwargs)

    def test_each_channel_uses_its_own_threshold(self) -> None:
        # numeric 0.94 < 0.95 → yellow even though the written channel is strong
        low_numeric = self.classify(
            prediction("8.0", "0.94"), prediction("8.0", "0.99")
        )
        self.assertEqual(low_numeric.level, ReviewLevel.YELLOW)
        # written 0.91 ≥ 0.90 while a single shared 0.95 would have rejected it
        ok = self.classify(prediction("8.0", "0.96"), prediction("8.0", "0.91"))
        self.assertEqual(ok.level, ReviewLevel.GREEN)
        shared = self.classify(
            prediction("8.0", "0.96"),
            prediction("8.0", "0.91"),
            green_confidence=Decimal("0.95"),
        )
        self.assertEqual(shared.level, ReviewLevel.YELLOW)

    def test_thresholds_are_inclusive_and_configurable(self) -> None:
        edge = self.classify(prediction("7.5", "0.95"), prediction("7.5", "0.90"))
        self.assertEqual(edge.level, ReviewLevel.GREEN)
        stricter = self.classify(
            prediction("7.5", "0.95"),
            prediction("7.5", "0.90"),
            numeric_confidence=Decimal("0.99"),
            written_confidence=Decimal("0.90"),
        )
        self.assertEqual(stricter.level, ReviewLevel.YELLOW)

    def test_there_is_no_arbiter_when_channels_disagree_or_are_both_weak(self) -> None:
        # Strong numeric vs weak written, and the reverse: neither value is chosen; both stay yellow.
        for numeric, written in (
            (prediction("8.0", "0.99"), prediction("7.0", "0.30")),
            (prediction("8.0", "0.30"), prediction("7.0", "0.99")),
            (prediction("8.0", "0.30"), prediction("7.0", "0.30")),
        ):
            result = self.classify(numeric, written)
            self.assertEqual(
                result, Classification(Comparison.MISMATCH, ReviewLevel.YELLOW)
            )

    def test_zero_with_low_confidence_is_yellow_not_red(self) -> None:
        result = self.classify(prediction("0.0", "0.40"), prediction("0.0", "0.40"))
        self.assertEqual(result, Classification(Comparison.MATCH, ReviewLevel.YELLOW))

    def test_defaults_match_the_agreed_starting_values(self) -> None:
        from src.domain import (
            DEFAULT_NUMERIC_THRESHOLD,
            DEFAULT_WRITTEN_THRESHOLD,
            thresholds_from_env,
        )

        self.assertEqual(
            (DEFAULT_NUMERIC_THRESHOLD, DEFAULT_WRITTEN_THRESHOLD),
            (Decimal("0.95"), Decimal("0.90")),
        )
        self.assertEqual(thresholds_from_env({}), (Decimal("0.95"), Decimal("0.90")))
        self.assertEqual(
            thresholds_from_env(
                {
                    "RECOGNITION_NUMERIC_THRESHOLD": "0.97",
                    "RECOGNITION_WRITTEN_THRESHOLD": "0.8",
                }
            ),
            (Decimal("0.97"), Decimal("0.8")),
        )
        for bad in ("abc", "1.2", "-0.1", "NaN"):
            with self.assertRaises(ValueError):
                thresholds_from_env({"RECOGNITION_NUMERIC_THRESHOLD": bad})
