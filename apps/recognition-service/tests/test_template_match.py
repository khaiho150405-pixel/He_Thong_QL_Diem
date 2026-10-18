import unittest

from src.pipeline import template_match as tm
from src.pipeline.layout import phan_tich_bo_cuc
from synthetic import (
    OTHER_COLUMNS,
    OTHER_HEADERS,
    OTHER_OCR,
    THPT_COLUMNS,
    THPT_OCR,
    encode_png,
    make_thpt_page,
    photograph,
)
from test_pipeline_grid import HeaderOcr

TEMPLATE_INDEXES = list(range(len(THPT_COLUMNS)))


def signature_of(page, ocr=None, **photo):
    return phan_tich_bo_cuc(encode_png(photograph(page, **photo)), ocr).signature


class SignatureTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.page, _ = make_thpt_page()
        cls.signature = signature_of(cls.page, HeaderOcr(THPT_COLUMNS, THPT_OCR), angle=4.0, perspective=0.02)

    def test_signature_has_the_adr_fields_rounded_to_four_digits(self) -> None:
        signature = self.signature
        self.assertEqual(
            set(signature),
            {"version", "columnWidths", "headerTexts", "headerRows", "rowHeightMm", "tableWidthMm"},
        )
        self.assertEqual(signature["version"], 1)
        self.assertEqual(len(signature["columnWidths"]), 9)
        self.assertAlmostEqual(sum(signature["columnWidths"]), 1.0, delta=0.01)
        for width in signature["columnWidths"]:
            self.assertEqual(width, round(width, 4))
        for name in ("rowHeightMm", "tableWidthMm"):
            self.assertEqual(signature[name], round(signature[name], 4))
        self.assertEqual(signature["headerRows"], 1)
        # 1430 px at 200 DPI = 181.9 mm; the row pitch is 44 px = 5.6 mm
        self.assertAlmostEqual(signature["tableWidthMm"], 181.9, delta=1.5)
        self.assertAlmostEqual(signature["rowHeightMm"], 5.6, delta=0.3)

    def test_header_texts_are_accent_free_and_lowercase(self) -> None:
        self.assertEqual(self.signature["headerTexts"][:2], ["stt", "hovaten"])
        self.assertEqual(self.signature["headerTexts"][-1], "ghichu")

    def test_the_signature_is_deterministic(self) -> None:
        again = signature_of(self.page, HeaderOcr(THPT_COLUMNS, THPT_OCR), angle=4.0, perspective=0.02)
        self.assertEqual(again, self.signature)

    def test_without_ocr_the_header_texts_are_empty(self) -> None:
        signature = signature_of(self.page, None)
        self.assertEqual(signature["headerTexts"], [""] * 9)


class TemplateMatchPhotoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.page, _ = make_thpt_page()
        cls.template = signature_of(cls.page, None, angle=0.5, perspective=0.0)

    def test_the_same_form_photographed_skewed_or_in_mild_perspective_scores_high(self) -> None:
        for photo in (
            {"angle": 4.0, "perspective": 0.02},
            {"angle": -3.0, "perspective": 0.03, "scale": 0.7},
            {"angle": 0.0, "perspective": 0.04},
        ):
            score, column_map = tm.khop_mau(signature_of(self.page, None, **photo), self.template)
            self.assertGreaterEqual(score, 0.9, photo)
            self.assertEqual(column_map, {i: i for i in TEMPLATE_INDEXES}, photo)

    def test_the_same_form_with_fewer_rows_still_matches(self) -> None:
        page, _ = make_thpt_page(rows=8)
        score, column_map = tm.khop_mau(signature_of(page, None), self.template)
        self.assertGreaterEqual(score, 0.9)
        self.assertEqual(len(column_map), 9)

    def test_a_different_form_scores_below_the_default_threshold(self) -> None:
        other, _ = make_thpt_page(
            columns=OTHER_COLUMNS, headers=OTHER_HEADERS, score_columns=(3, 4, 5, 6), name_column=2
        )
        signature = signature_of(other, HeaderOcr(OTHER_COLUMNS, OTHER_OCR))
        self.assertEqual(len(signature["columnWidths"]), len(OTHER_COLUMNS))
        score, _ = tm.khop_mau(signature, self.template)
        self.assertLess(score, 0.8)
        self.assertLess(score, tm.DEFAULT_MIN_SCORE)

    def test_a_lost_vertical_rule_still_matches_and_maps_the_other_columns(self) -> None:
        # Rule between TX3 (template column 4) and TX4 (column 5) is missing: those two columns merge into one.
        page, _ = make_thpt_page(missing_lines=(5,))
        signature = signature_of(page, None)
        self.assertEqual(len(signature["columnWidths"]), 8)
        score, column_map = tm.khop_mau(signature, self.template)
        self.assertGreaterEqual(score, 0.9)
        self.assertEqual(column_map, {0: 0, 1: 1, 2: 2, 3: 3, 6: 5, 7: 6, 8: 7})
        self.assertNotIn(4, column_map)
        self.assertNotIn(5, column_map)

    def test_a_spurious_vertical_rule_splits_a_column_and_leaves_it_unmapped(self) -> None:
        columns = (60, 380, 52, 53, 105, 105, 105, 116, 128, 326)  # TX1 drawn as two cells
        page, _ = make_thpt_page(columns=columns, headers=None, score_columns=(4, 5, 6, 7))
        signature = signature_of(page, None)
        self.assertEqual(len(signature["columnWidths"]), 10)
        score, column_map = tm.khop_mau(signature, self.template)
        self.assertGreaterEqual(score, 0.8)
        self.assertEqual(column_map, {0: 0, 1: 1, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 9})
        self.assertNotIn(2, column_map)

    def test_matching_is_deterministic(self) -> None:
        signature = signature_of(self.page, None, angle=-3.0, perspective=0.03)
        self.assertEqual(tm.khop_mau(signature, self.template), tm.khop_mau(signature, self.template))


def sig(widths, texts=None):
    return {"version": 1, "columnWidths": list(widths), "headerTexts": list(texts or [])}


class KhopMauUnitTest(unittest.TestCase):
    WIDTHS = [0.05, 0.25, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]

    def test_identical_signatures_score_one_with_identity_map(self) -> None:
        score, column_map = tm.khop_mau(sig(self.WIDTHS), sig(self.WIDTHS))
        self.assertEqual(score, 1.0)
        self.assertEqual(column_map, {i: i for i in range(9)})

    def test_widths_are_normalised_so_a_cropped_table_edge_does_not_matter(self) -> None:
        scaled = [w * 0.97 for w in self.WIDTHS]
        self.assertEqual(tm.khop_mau(sig(scaled), sig(self.WIDTHS))[0], 1.0)

    def test_columns_that_cannot_be_aligned_give_zero_and_no_map(self) -> None:
        self.assertEqual(tm.khop_mau(sig([0.1] * 10), sig([0.5, 0.5])), (0.0, {}))
        self.assertEqual(tm.khop_mau(sig([]), sig(self.WIDTHS)), (0.0, {}))
        self.assertEqual(tm.khop_mau(sig(self.WIDTHS), sig([])), (0.0, {}))

    def test_a_merged_pair_costs_a_fixed_penalty_and_leaves_both_unmapped(self) -> None:
        merged = [0.05, 0.25, 0.2, 0.1, 0.1, 0.1, 0.1, 0.1]  # columns 2 and 3 merged
        score, column_map = tm.khop_mau(sig(merged), sig(self.WIDTHS))
        self.assertAlmostEqual(score, 1.0 - tm.PHAT_GOP_COT, places=4)
        self.assertEqual(column_map, {0: 0, 1: 1, 4: 3, 5: 4, 6: 5, 7: 6, 8: 7})

    def test_the_score_is_in_zero_one_and_rounded_to_four_digits(self) -> None:
        score, _ = tm.khop_mau(sig([0.9, 0.1]), sig([0.1, 0.9]))
        self.assertGreaterEqual(score, 0.0)
        self.assertLessEqual(score, 1.0)
        self.assertEqual(score, round(score, 4))

    def test_different_header_texts_lower_the_score_and_missing_texts_are_ignored(self) -> None:
        same = ["stt", "hovaten", "tx1", "tx2", "tx3", "tx4", "gk", "ck", "ghichu"]
        other = ["aaaa", "bbbb", "cccc", "dddd", "eeee", "ffff", "gggg", "hhhh", "iiii"]
        self.assertEqual(tm.khop_mau(sig(self.WIDTHS, same), sig(self.WIDTHS, same))[0], 1.0)
        lower, _ = tm.khop_mau(sig(self.WIDTHS, other), sig(self.WIDTHS, same))
        self.assertLess(lower, 0.8)
        self.assertEqual(tm.khop_mau(sig(self.WIDTHS, [""] * 9), sig(self.WIDTHS, same))[0], 1.0)
        self.assertEqual(tm.khop_mau(sig(self.WIDTHS), sig(self.WIDTHS, same))[0], 1.0)
        # a single comparable header pair is not enough evidence to move the score
        one = [""] * 8 + ["zzzz"]
        self.assertEqual(tm.khop_mau(sig(self.WIDTHS, one), sig(self.WIDTHS, same))[0], 1.0)

    def test_header_comparison_ignores_accents_and_case(self) -> None:
        accented = ["STT", "Họ và tên", "TX1", "TX2", "TX3", "TX4", "GK", "CK", "Ghi chú"]
        plain = ["stt", "hovaten", "tx1", "tx2", "tx3", "tx4", "gk", "ck", "ghichu"]
        self.assertEqual(tm.khop_mau(sig(self.WIDTHS, accented), sig(self.WIDTHS, plain))[0], 1.0)


class ThresholdFromEnvTest(unittest.TestCase):
    def test_default_is_zero_point_eight(self) -> None:
        self.assertEqual(tm.nguong_khop_mau({}), 0.8)
        self.assertEqual(tm.nguong_khop_mau({tm.ENV_MIN_SCORE: "  "}), 0.8)

    def test_value_from_the_environment(self) -> None:
        self.assertEqual(tm.nguong_khop_mau({"RECOGNITION_TEMPLATE_MIN_SCORE": "0.65"}), 0.65)

    def test_invalid_values_are_rejected(self) -> None:
        for bad in ("abc", "1.5", "-0.1", "nan", "inf"):
            with self.assertRaises(ValueError, msg=bad):
                tm.nguong_khop_mau({"RECOGNITION_TEMPLATE_MIN_SCORE": bad})


if __name__ == "__main__":
    unittest.main()
