from decimal import Decimal
from unittest import TestCase

from src.domain import (
    ChannelPrediction,
    Classification,
    Comparison,
    ReviewLevel,
    Suggestion,
    classify_channels,
    floors_from_env,
    thresholds_from_env,
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


BLANK = prediction(None, None, blank=True)
GREEN, YELLOW, RED = ReviewLevel.GREEN, ReviewLevel.YELLOW, ReviewLevel.RED


class ResearchRuleTest(TestCase):
    """Luật hợp nhất của nghiên cứu (hop_nhat.py::hop_nhat_mot_o) đổi sang ba màu; τ số 0,95, τ chữ 0,90."""

    def classify(self, numeric, written, **kwargs):
        return classify_channels(numeric, written, **kwargs)

    def test_two_channels_with_the_same_value_are_green_whatever_their_confidence(self) -> None:
        for numeric_confidence, written_confidence in (("0.99", "0.99"), ("0.30", "0.20"), ("0.96", "0.10")):
            result = self.classify(
                prediction("8.5", numeric_confidence), prediction("8.5", written_confidence)
            )
            self.assertEqual(result, Classification(Comparison.MATCH, GREEN, Suggestion.NUMERIC))

    def test_zero_is_a_real_agreeing_grade(self) -> None:
        result = self.classify(prediction("0.0", "0.5"), prediction("0.0", "0.5"))
        self.assertEqual(result.level, GREEN)
        self.assertEqual(result.suggestion, Suggestion.NUMERIC)

    def test_only_the_numeric_channel_is_trusted_takes_the_numeric_value(self) -> None:
        for written in (
            prediction("7.0", "0.30"),  # khác giá trị, yếu
            prediction("7.0", "0.89"),  # khác giá trị, sát ngưỡng chữ
            prediction(None, None, blank=True),  # không đọc được
        ):
            result = self.classify(prediction("8.0", "0.95"), written)
            self.assertEqual(result.level, YELLOW, written)
            self.assertEqual(result.suggestion, Suggestion.NUMERIC, written)

    def test_only_the_written_channel_is_trusted_takes_the_written_value(self) -> None:
        for numeric in (
            prediction("8.0", "0.94"),  # khác giá trị, sát ngưỡng số
            prediction("8.0", "0.10"),
            prediction(None, None, blank=True),
        ):
            result = self.classify(numeric, prediction("7.0", "0.90"))
            self.assertEqual(result.level, YELLOW, numeric)
            self.assertEqual(result.suggestion, Suggestion.WRITTEN, numeric)

    def test_both_strong_but_different_is_red_without_a_suggestion(self) -> None:
        result = self.classify(prediction("8.0", "0.99"), prediction("7.0", "0.99"))
        self.assertEqual(result, Classification(Comparison.MISMATCH, RED, None))

    def test_both_weak_is_red_without_a_suggestion(self) -> None:
        for numeric, written in (
            (prediction("8.0", "0.30"), prediction("7.0", "0.30")),
            (prediction("8.0", "0.30"), prediction(None, None, blank=True)),
            (prediction(None, None, blank=True), prediction("7.0", "0.30")),
        ):
            result = self.classify(numeric, written)
            self.assertEqual(result.level, RED)
            self.assertIsNone(result.suggestion)

    def test_no_valid_channel_is_unreadable_red(self) -> None:
        unreadable = prediction(None, "0.10")
        self.assertEqual(
            self.classify(BLANK, unreadable),
            Classification(Comparison.UNREADABLE, RED, None),
        )
        self.assertEqual(
            self.classify(BLANK, BLANK), Classification(Comparison.UNREADABLE, RED, None)
        )

    def test_comparison_labels_are_kept(self) -> None:
        self.assertEqual(
            self.classify(prediction("8.0", "0.99"), BLANK).comparison, Comparison.ONE_CHANNEL
        )
        self.assertEqual(
            self.classify(prediction("8.0", "0.99"), prediction("7.0", "0.2")).comparison,
            Comparison.MISMATCH,
        )

    def test_thresholds_are_inclusive_and_configurable_per_channel(self) -> None:
        edge = self.classify(prediction("8.0", "0.95"), prediction("7.0", "0.10"))
        self.assertEqual(edge.suggestion, Suggestion.NUMERIC)
        stricter = self.classify(
            prediction("8.0", "0.95"),
            prediction("7.0", "0.10"),
            numeric_confidence=Decimal("0.99"),
        )
        self.assertEqual(stricter.level, RED)
        edge_written = self.classify(prediction("8.0", "0.10"), prediction("7.0", "0.90"))
        self.assertEqual(edge_written.suggestion, Suggestion.WRITTEN)
        looser = self.classify(
            prediction("8.0", "0.10"),
            prediction("7.0", "0.50"),
            written_confidence=Decimal("0.50"),
        )
        self.assertEqual(looser.suggestion, Suggestion.WRITTEN)

    def test_the_two_raw_predictions_are_never_modified(self) -> None:
        numeric, written = prediction("8.0", "0.95"), prediction("7.0", "0.40")
        self.classify(numeric, written)
        self.assertEqual((numeric.value, numeric.confidence), (Decimal("8.0"), Decimal("0.95")))
        self.assertEqual((written.value, written.confidence), (Decimal("7.0"), Decimal("0.40")))


class AgreementFloorTest(TestCase):
    def test_default_floor_is_zero_like_the_research(self) -> None:
        self.assertEqual(floors_from_env({}), (Decimal("0.00"), Decimal("0.00")))

    def test_agreement_below_a_floor_is_yellow_but_still_suggests_the_common_value(self) -> None:
        low_numeric = classify_channels(
            prediction("8.0", "0.40"),
            prediction("8.0", "0.99"),
            numeric_floor=Decimal("0.50"),
        )
        self.assertEqual(low_numeric, Classification(Comparison.MATCH, YELLOW, Suggestion.NUMERIC))
        low_written = classify_channels(
            prediction("8.0", "0.99"),
            prediction("8.0", "0.40"),
            written_floor=Decimal("0.50"),
        )
        self.assertEqual(low_written.level, YELLOW)
        at_floor = classify_channels(
            prediction("8.0", "0.50"),
            prediction("8.0", "0.50"),
            numeric_floor=Decimal("0.50"),
            written_floor=Decimal("0.50"),
        )
        self.assertEqual(at_floor.level, GREEN)

    def test_floor_never_affects_disagreeing_channels(self) -> None:
        result = classify_channels(
            prediction("8.0", "0.99"),
            prediction("7.0", "0.10"),
            numeric_floor=Decimal("0.90"),
            written_floor=Decimal("0.90"),
        )
        self.assertEqual(result, Classification(Comparison.MISMATCH, YELLOW, Suggestion.NUMERIC))

    def test_floors_come_from_the_environment_and_are_validated(self) -> None:
        self.assertEqual(
            floors_from_env(
                {"RECOGNITION_NUMERIC_FLOOR": "0.35", "RECOGNITION_WRITTEN_FLOOR": "0.5"}
            ),
            (Decimal("0.35"), Decimal("0.5")),
        )
        for bad in ("abc", "1.2", "-0.1", "NaN"):
            with self.assertRaises(ValueError):
                floors_from_env({"RECOGNITION_WRITTEN_FLOOR": bad})


class ContractTest(TestCase):
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
                numeric_confidence=Decimal("1.1"),
            )

    def test_threshold_defaults_and_environment(self) -> None:
        from src.domain import DEFAULT_NUMERIC_THRESHOLD, DEFAULT_WRITTEN_THRESHOLD

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
