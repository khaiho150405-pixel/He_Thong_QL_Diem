"""P7: khớp mẫu chịu được vạch dọc bị mất/đứt, nhưng chỉ khi có nét kẻ thật; không có thì vẫn TEMPLATE_MISMATCH."""
import json
import unittest

import cv2
import numpy as np

from src.domain.layout import parse_layout
from src.pipeline import template_match as tm
from src.pipeline.errors import PipelineError
from src.pipeline.khoi_phuc_vach import tim_vach_doc
from src.pipeline.layout import chuan_bi_doc, phan_tich_bo_cuc
from synthetic import (
    OTHER_COLUMNS,
    OTHER_HEADERS,
    THPT_COLUMNS,
    encode_png,
    make_page,
    make_thpt_page,
    photograph,
)

MIN_SCORE = 0.8


def photo(page, **kwargs):
    return encode_png(photograph(page, **{"angle": 2.0, "perspective": 0.02, **kwargs}))


def layout_for(signature, *columns):
    """``columns``: (chỉ số mẫu, vai trò[, khóa]) → layout /v2 hợp lệ."""
    items = []
    for index, role, *key in columns:
        item = {"index": index, "role": role}
        if key:
            item["key"] = key[0]
        items.append(item)
    return parse_layout(json.dumps({"signature": signature, "columns": items}))


def mismatch(test, image, layout):
    with test.assertRaises(PipelineError) as caught:
        chuan_bi_doc(image, layout, None, MIN_SCORE)
    test.assertEqual(caught.exception.code, "TEMPLATE_MISMATCH")
    return caught.exception.details


class RecoveryBase(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.clean, _ = make_thpt_page()
        cls.template = phan_tich_bo_cuc(photo(cls.clean, angle=0.5, perspective=0.0), None).signature
        cls.stt_name_tx = layout_for(
            cls.template, (0, "STT"), (1, "HO_TEN"), (2, "DIEM", "TX1"), (4, "DIEM", "TX3"), (5, "DIEM", "TX4")
        )


class MiddleRuleTest(RecoveryBase):
    def test_a_broken_rule_between_two_wanted_columns_is_found_again(self) -> None:
        # (a) The rule between TX3 (column 4) and TX4 (column 5) is dashed: the grid drops it, the ink is still there.
        page, _ = make_thpt_page(dashed_lines=(5,))
        image = photo(page)
        self.assertEqual(len(phan_tich_bo_cuc(image, None).columns), 8, "the grid must have lost the rule")
        result = chuan_bi_doc(image, self.stt_name_tx, None, MIN_SCORE)
        self.assertEqual(sorted(result.column_map), [0, 1, 2, 3, 4, 5, 6, 7, 8])
        self.assertGreaterEqual(result.score, 0.9)
        self.assertEqual(len(result.bo_cuc.columns), 9)
        tx3, tx4 = result.bo_cuc.columns[result.column_map[4]], result.bo_cuc.columns[result.column_map[5]]
        self.assertAlmostEqual(tx3.px1, tx4.px0, delta=1.0)
        self.assertAlmostEqual(tx3.px1 - tx3.px0, tx4.px1 - tx4.px0, delta=0.12 * (tx3.px1 - tx3.px0))
        self.assertEqual(len(result.rows), 20)
        self.assertTrue(all(len(row.grades) == 3 for row in result.rows))

    def test_the_recovered_page_reads_the_same_cells_as_the_intact_page(self) -> None:
        intact = chuan_bi_doc(photo(self.clean), self.stt_name_tx, None, MIN_SCORE)
        broken_page, _ = make_thpt_page(dashed_lines=(5,))
        recovered = chuan_bi_doc(photo(broken_page), self.stt_name_tx, None, MIN_SCORE)
        for want, got in zip(intact.rows, recovered.rows):
            for a, b in zip(want.grades, got.grades):
                self.assertAlmostEqual(a.numeric_cell.shape[1], b.numeric_cell.shape[1], delta=4)
                self.assertAlmostEqual(a.numeric_ink, b.numeric_ink, delta=3.0)

    def test_without_any_ink_in_the_gap_the_page_is_still_rejected(self) -> None:
        # (b) Same situation but the rule is simply not there: nothing to find, nothing to guess.
        page, _ = make_thpt_page(missing_lines=(5,))
        details = mismatch(self, photo(page), self.stt_name_tx)
        self.assertEqual(details["unmappedColumns"], [4, 5])
        self.assertEqual(details["imageColumns"], 8)

    def test_a_missing_rule_between_columns_that_are_not_wanted_needs_no_recovery(self) -> None:
        page, _ = make_thpt_page(missing_lines=(5,))
        wanted = layout_for(self.template, (0, "STT"), (1, "HO_TEN"), (2, "DIEM", "TX1"), (6, "DIEM", "GK"))
        self.assertEqual(sorted(chuan_bi_doc(photo(page), wanted, None, MIN_SCORE).column_map), [0, 1, 2, 3, 6, 7, 8])

    def test_a_rule_that_is_not_where_the_template_expects_it_is_not_accepted(self) -> None:
        # The dashed rule is 40% of a column away from the expected place: the search window does not reach it.
        shifted = (60, 380, 105, 105, 105 + 45, 105 - 45, 116, 128, 326)
        page, _ = make_thpt_page(columns=shifted, dashed_lines=(5,))
        mismatch(self, photo(page), self.stt_name_tx)


class EdgeRuleTest(RecoveryBase):
    def test_a_lost_left_border_is_found_again_so_the_stt_column_can_be_read(self) -> None:
        page, _ = make_thpt_page(dashed_lines=(0,))
        image = photo(page)
        broken = phan_tich_bo_cuc(image, None)
        self.assertEqual(len(broken.columns), 8)
        ket_qua = tm.khop_mau_chi_tiet(broken.signature, self.template)
        self.assertEqual((ket_qua.cat_trai, ket_qua.cat_phai), (1, 0))
        self.assertNotIn(0, ket_qua.column_map)
        result = chuan_bi_doc(image, self.stt_name_tx, None, MIN_SCORE)
        self.assertEqual(sorted(result.column_map), list(range(9)))
        stt = result.bo_cuc.columns[result.column_map[0]]
        name = result.bo_cuc.columns[result.column_map[1]]
        self.assertAlmostEqual(stt.px1, name.px0, delta=1.0)
        self.assertAlmostEqual(stt.px1 - stt.px0, name.px0 - stt.px0, delta=0.01)
        self.assertEqual(len(result.rows), 20)
        self.assertTrue(all(row.stt_cell is not None and row.stt_cell.size for row in result.rows))

    def test_a_left_border_without_ink_is_not_invented(self) -> None:
        page, _ = make_thpt_page(missing_lines=(0,))
        details = mismatch(self, photo(page), self.stt_name_tx)
        self.assertEqual(details["unmappedColumns"], [0])

    def test_two_lost_left_columns_need_two_real_rules(self) -> None:
        # Rules 0 and 1 are both lost, so STT and the name column are outside the grid.
        wanted = layout_for(self.template, (0, "STT"), (1, "HO_TEN"), (4, "DIEM", "TX3"))
        both = make_thpt_page(dashed_lines=(0, 1))[0]
        self.assertTrue({0, 1, 4} <= set(chuan_bi_doc(photo(both), wanted, None, MIN_SCORE).column_map))
        # Only one of the two rules has ink: the other cannot be invented.
        one_ink = make_thpt_page(dashed_lines=(0,), missing_lines=(1,))[0]
        mismatch(self, photo(one_ink), wanted)

    def test_a_lost_right_border_hides_only_the_last_column(self) -> None:
        page, _ = make_thpt_page(dashed_lines=(9,))
        image = photo(page)
        without_last = layout_for(self.template, (0, "STT"), (1, "HO_TEN"), (7, "DIEM", "CK"))
        result = chuan_bi_doc(image, without_last, None, MIN_SCORE)
        self.assertEqual(sorted(result.column_map), list(range(8)))
        with_last = layout_for(self.template, (0, "STT"), (1, "HO_TEN"), (8, "DIEM", "GHICHU"))
        recovered = chuan_bi_doc(image, with_last, None, MIN_SCORE)
        self.assertEqual(sorted(recovered.column_map), list(range(9)))
        gone, _ = make_thpt_page(missing_lines=(9,))
        self.assertEqual(mismatch(self, photo(gone), with_last)["unmappedColumns"], [8])


class OtherFormTest(RecoveryBase):
    def other_page(self, **kwargs):
        return make_thpt_page(
            columns=OTHER_COLUMNS, headers=OTHER_HEADERS, score_columns=(3, 4, 5, 6), name_column=2, **kwargs
        )[0]

    def test_another_form_is_rejected(self) -> None:
        # (c) Different column count and widths, with or without broken rules.
        for kwargs in ({}, {"dashed_lines": (3,)}, {"dashed_lines": (0,)}, {"missing_lines": (0,)}):
            with self.subTest(**kwargs):
                mismatch(self, photo(self.other_page(**kwargs)), self.stt_name_tx)

    def test_another_form_with_the_same_number_of_columns_is_rejected(self) -> None:
        page = make_thpt_page(columns=(110, 150, 90, 220, 90, 140, 200, 160, 270))[0]
        mismatch(self, photo(page), self.stt_name_tx)

    def test_a_broken_rule_never_lets_an_unrelated_score_through(self) -> None:
        details = mismatch(self, photo(self.other_page(dashed_lines=(3,))), self.stt_name_tx)
        self.assertLess(details["score"], MIN_SCORE)


class EdgeAlignmentTest(unittest.TestCase):
    WIDTHS = [0.0475, 0.1159, 0.2696, 0.0957, 0.1316, 0.0554, 0.1089, 0.0825, 0.0927]

    @staticmethod
    def sig(widths):
        return {"version": 1, "columnWidths": list(widths), "headerTexts": []}

    def test_the_last_columns_missing_from_the_grid_are_detected(self) -> None:
        for dropped in (1, 2):
            image = self.WIDTHS[: len(self.WIDTHS) - dropped]
            ket_qua = tm.khop_mau_chi_tiet(self.sig(image), self.sig(self.WIDTHS))
            self.assertEqual((ket_qua.cat_trai, ket_qua.cat_phai), (0, dropped))
            self.assertEqual(ket_qua.column_map, {i: i for i in range(len(image))})
            self.assertGreaterEqual(ket_qua.score, 0.8)

    def test_the_first_columns_missing_from_the_grid_are_detected(self) -> None:
        for dropped in (1, 2):
            ket_qua = tm.khop_mau_chi_tiet(self.sig(self.WIDTHS[dropped:]), self.sig(self.WIDTHS))
            self.assertEqual((ket_qua.cat_trai, ket_qua.cat_phai), (dropped, 0))
            self.assertEqual(ket_qua.column_map, {i + dropped: i for i in range(len(self.WIDTHS) - dropped)})

    def test_an_intact_grid_never_uses_the_edge_alignment(self) -> None:
        ket_qua = tm.khop_mau_chi_tiet(self.sig(self.WIDTHS), self.sig(self.WIDTHS))
        self.assertEqual((ket_qua.cat_trai, ket_qua.cat_phai, ket_qua.score), (0, 0, 1.0))

    def test_equally_plausible_cuts_are_not_guessed(self) -> None:
        # Nine equal columns: dropping the first or the last one explains an eight column image equally well.
        equal = [1 / 9] * 9
        ket_qua = tm.khop_mau_chi_tiet(self.sig([1 / 8] * 8), self.sig(equal))
        self.assertEqual((ket_qua.cat_trai, ket_qua.cat_phai), (0, 0))

    def test_a_merged_pair_is_reported_for_recovery(self) -> None:
        merged = [0.0475, 0.1159, 0.2696, 0.0957 + 0.1316, 0.0554, 0.1089, 0.0825, 0.0927]
        ket_qua = tm.khop_mau_chi_tiet(self.sig(merged), self.sig(self.WIDTHS))
        self.assertEqual(ket_qua.gop, ((3, 3),))
        self.assertNotIn(3, ket_qua.column_map)
        self.assertNotIn(4, ket_qua.column_map)

    def test_khop_mau_keeps_its_two_value_contract(self) -> None:
        self.assertEqual(tm.khop_mau(self.sig(self.WIDTHS), self.sig(self.WIDTHS)), (1.0, {i: i for i in range(9)}))

    def test_a_form_with_more_columns_is_not_made_to_fit_by_cutting_the_template(self) -> None:
        wide = [0.044, 0.101, 0.251, 0.075, 0.104, 0.033, 0.034, 0.033, 0.033, 0.034, 0.033, 0.046, 0.082, 0.097]
        ket_qua = tm.khop_mau_chi_tiet(self.sig(wide), self.sig(self.WIDTHS))
        self.assertLess(ket_qua.score, 0.8)


class RuleSearchTest(unittest.TestCase):
    def test_a_real_rule_is_located_within_a_pixel_or_two(self) -> None:
        page, info = make_page(rows=12, dashed_lines=(3,))
        found = tim_vach_doc(page, info["ys"], 1, info["xs"][3] + 12, 30)
        self.assertIsNotNone(found)
        self.assertAlmostEqual(found, info["xs"][3], delta=2.0)

    def test_a_slightly_slanted_rule_is_still_found(self) -> None:
        page, info = make_page(rows=12, missing_lines=(3,))
        ys, x = info["ys"], info["xs"][3]
        cv2.line(page, (x - 4, ys[1]), (x + 4, ys[-1]), (35, 35, 35), 3)
        found = tim_vach_doc(page, ys, 1, x + 10, 30)
        self.assertIsNotNone(found)
        self.assertAlmostEqual(found, x, delta=4.0)

    def test_two_separate_candidates_are_ambiguous_and_refused(self) -> None:
        page, info = make_page(rows=12, missing_lines=(3,))
        ys, x = info["ys"], info["xs"][3]
        for dx in (-15, 15):
            cv2.line(page, (x + dx, ys[0]), (x + dx, ys[-1]), (35, 35, 35), 3)
        self.assertIsNone(tim_vach_doc(page, ys, 1, x, 30))

    def test_nothing_is_found_where_there_is_no_rule(self) -> None:
        page, info = make_page(rows=12, missing_lines=(3,))
        self.assertIsNone(tim_vach_doc(page, info["ys"], 1, info["xs"][3], 30))

    def test_handwriting_is_not_a_rule(self) -> None:
        page, info = make_page(rows=12, missing_lines=(3,), cell_text={(r, 3): "8.5 / 7.25" for r in range(12)})
        self.assertIsNone(tim_vach_doc(page, info["ys"], 1, info["xs"][3] + 40, 50))

    def test_a_rule_already_in_the_grid_is_excluded(self) -> None:
        page, info = make_page(rows=12)
        self.assertIsNone(tim_vach_doc(page, info["ys"], 1, info["xs"][3], 20, tranh=[info["xs"][3]]))

    def test_a_wide_dark_band_is_a_shadow_not_a_rule(self) -> None:
        page, info = make_page(rows=12, missing_lines=(3,))
        x = info["xs"][3]
        page[info["ys"][1] : info["ys"][-1], x - 8 : x + 9] = (60, 60, 60)
        self.assertIsNone(tim_vach_doc(page, info["ys"], 1, x, 30))

    def test_a_dark_edge_at_the_page_margin_is_not_a_rule(self) -> None:
        page, info = make_page(rows=12, left=12)
        self.assertIsNone(tim_vach_doc(page, info["ys"], 1, 5, 15))

    def test_a_rule_present_in_only_a_few_rows_is_not_enough(self) -> None:
        page, info = make_page(rows=12, missing_lines=(3,))
        ys = info["ys"]
        cv2.line(page, (info["xs"][3], ys[1]), (info["xs"][3], ys[4]), (35, 35, 35), 3)
        self.assertIsNone(tim_vach_doc(page, ys, 1, info["xs"][3], 30))


if __name__ == "__main__":
    unittest.main()
