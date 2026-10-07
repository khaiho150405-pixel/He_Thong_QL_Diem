import unittest

import cv2
import numpy as np

from src.pipeline import rows as rw
from src.pipeline.errors import PipelineError
from synthetic import encode_png, make_page, photograph
from test_pipeline_grid import SCORE_HEADERS, SCORE_OCR, SCORE_SHEET, HeaderOcr

ROWS = 10
STRUCK = 3  # zero-based: the 4th data row is crossed out
BLANK = 6  # the 7th data row has no name and no grade
HYPHEN = 8  # a long dash only inside the score cell: a grade, not a strike


def sheet():
    cell_text = {}
    ink = []
    for row in range(ROWS):
        if row != BLANK:
            cell_text[(row, 1)] = f"Hoc sinh {row + 1:02d}"
            cell_text[(row, 3)] = "tam ruoi"
            ink.append((row, 2))
    page, layout = make_page(
        rows=ROWS,
        columns=SCORE_SHEET,
        headers=SCORE_HEADERS,
        cell_text=cell_text,
        ink_cells=tuple(ink),
        struck_rows=(STRUCK,),
        first_stt=1,
    )
    xs, ys = layout["xs"], layout["ys"]
    y0, y1 = ys[HYPHEN + 1], ys[HYPHEN + 2]
    cv2.line(page, (xs[2] + 8, y0 + 22), (xs[2] + 78, y0 + 22), (35, 35, 35), 3)
    return page, layout


class RowExtractionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.page, cls.layout = sheet()
        cls.photo = photograph(cls.page, angle=3.0, perspective=0.02)
        cls.ocr = HeaderOcr(SCORE_SHEET, SCORE_OCR)
        cls.analysis = rw.analyze_page(encode_png(cls.photo), cls.ocr)

    def test_one_row_per_data_row_in_page_order(self) -> None:
        analysis = self.analysis
        self.assertEqual(len(analysis.rows), ROWS)
        self.assertEqual([r.row_index for r in analysis.rows], list(range(1, ROWS + 1)))
        self.assertFalse(analysis.guessed_columns)
        self.assertEqual(analysis.selection["cot_diem_chinh"]["chi_so"], 2)

    def test_struck_row_is_detected_and_has_no_grade(self) -> None:
        flags = [r.struck for r in self.analysis.rows]
        self.assertEqual(flags, [i == STRUCK for i in range(ROWS)])
        struck = self.analysis.rows[STRUCK]
        self.assertFalse(struck.has_grade_ink)

    def test_blank_row_has_neither_grade_nor_name_ink(self) -> None:
        blank = self.analysis.rows[BLANK]
        self.assertFalse(blank.struck)
        self.assertFalse(blank.has_grade_ink)
        self.assertFalse(blank.has_name_ink)
        self.assertLess(blank.score_ink, rw.NGUONG_TRONG)

    def test_written_rows_have_grade_and_name_ink(self) -> None:
        for index, row in enumerate(self.analysis.rows):
            if index in (STRUCK, BLANK):
                continue
            self.assertTrue(row.has_grade_ink, index)
            self.assertTrue(row.has_name_ink, index)
            self.assertGreaterEqual(row.score_ink, rw.NGUONG_TRONG, index)

    def test_a_long_dash_inside_the_score_cell_is_not_a_strike(self) -> None:
        row = self.analysis.rows[HYPHEN]
        self.assertTrue(rw.la_gach_ngang(row.score_cell))
        self.assertFalse(row.struck)
        self.assertTrue(row.has_grade_ink)

    def test_cells_are_cropped_from_the_right_columns(self) -> None:
        row = self.analysis.rows[0]
        expected = {
            "stt_cell": SCORE_SHEET[0],
            "name_cell": SCORE_SHEET[1],
            "score_cell": SCORE_SHEET[2],
            "written_cell": SCORE_SHEET[3],
        }
        for attribute, width in expected.items():
            cell = getattr(row, attribute)
            self.assertIsNotNone(cell, attribute)
            self.assertAlmostEqual(cell.shape[1], width, delta=14, msg=attribute)
            self.assertAlmostEqual(cell.shape[0], 44, delta=8, msg=attribute)

    def test_quality_report_is_attached(self) -> None:
        self.assertEqual(self.analysis.quality.blocking, ())
        self.assertIn("do_net", self.analysis.quality.metrics)

    def test_without_ocr_the_columns_are_marked_as_guessed(self) -> None:
        analysis = rw.analyze_page(encode_png(self.photo), None)
        self.assertTrue(analysis.guessed_columns)
        self.assertEqual(len(analysis.rows), ROWS)
        self.assertEqual(analysis.selection["cot_diem_chinh"]["chi_so"], 2)
        self.assertEqual(
            [r.struck for r in analysis.rows], [i == STRUCK for i in range(ROWS)]
        )


class PipelineErrorsTest(unittest.TestCase):
    def test_garbage_bytes_are_unreadable(self) -> None:
        for content in (b"", b"hello"):
            with self.assertRaises(PipelineError) as caught:
                rw.analyze_page(content)
            self.assertEqual(caught.exception.code, "IMAGE_UNREADABLE")

    def test_blurred_photo_is_image_quality_low(self) -> None:
        page, _ = sheet()
        blurred = photograph(page, blur=9.0)
        with self.assertRaises(PipelineError) as caught:
            rw.analyze_page(encode_png(blurred), HeaderOcr(SCORE_SHEET, SCORE_OCR))
        self.assertEqual(caught.exception.code, "IMAGE_QUALITY_LOW")

    def test_plain_paper_has_no_grid(self) -> None:
        paper = np.full((2338, 1654, 3), 246, np.uint8)
        cv2.putText(paper, "NOTES", (200, 400), cv2.FONT_HERSHEY_SIMPLEX, 3, (30, 30, 30), 6)
        photo = photograph(paper)
        with self.assertRaises(PipelineError) as caught:
            rw.analyze_page(encode_png(photo))
        self.assertIn(
            caught.exception.code, {"GRID_NOT_FOUND", "IMAGE_QUALITY_LOW"}
        )

    def test_a_three_column_table_is_not_a_gradebook(self) -> None:
        page, _ = make_page(rows=20, columns=(80, 600, 300), headers=("STT", "Ho ten", "Ghi chu"))
        with self.assertRaises(PipelineError) as caught:
            rw.analyze_page(encode_png(photograph(page)))
        self.assertEqual(caught.exception.code, "NOT_A_GRADEBOOK")

    def test_a_table_without_a_score_column_is_rejected(self) -> None:
        page, _ = make_page(
            rows=20, columns=(60, 480, 300, 300, 200, 160), headers=SCORE_HEADERS
        )
        with self.assertRaises(PipelineError) as caught:
            rw.analyze_page(encode_png(photograph(page)))
        self.assertEqual(caught.exception.code, "SCORE_COLUMN_NOT_FOUND")


class PageStartSttTest(unittest.TestCase):
    def test_starts_from_a_clean_column(self) -> None:
        reads = {n: 38 + n for n in range(1, 4)}  # rows 1-3 read as 39, 40, 41
        self.assertEqual(rw.suy_stt_bat_dau(reads, 3), 39)

    def test_two_wrong_reads_do_not_move_the_start(self) -> None:
        reads = {n: 38 + n for n in range(1, 11)}
        reads[4] = 99  # misread
        reads[7] = 12  # misread
        del reads[9]  # missed
        self.assertEqual(rw.suy_stt_bat_dau(reads, 10), 39)

    def test_first_page_starts_at_one(self) -> None:
        self.assertEqual(rw.suy_stt_bat_dau({n: n for n in range(1, 39)}, 38), 1)

    def test_not_enough_evidence_returns_none(self) -> None:
        self.assertIsNone(rw.suy_stt_bat_dau({}, 38))
        self.assertIsNone(rw.suy_stt_bat_dau({5: 7}, 38))  # a single vote on a long page
        scattered = {1: 3, 2: 30, 3: 11, 4: 90, 5: 2, 6: 55}
        self.assertIsNone(rw.suy_stt_bat_dau(scattered, 6))
        self.assertIsNone(rw.suy_stt_bat_dau({1: 0, 2: 600}, 5))  # out-of-range reads

    def test_short_last_page_needs_only_two_votes(self) -> None:
        self.assertEqual(rw.suy_stt_bat_dau({1: 39, 3: 41}, 3), 39)

    def test_analysis_helper_uses_its_own_row_count(self) -> None:
        page, _ = sheet()
        analysis = rw.analyze_page(encode_png(photograph(page)), HeaderOcr(SCORE_SHEET, SCORE_OCR))
        reads = {n: 20 + n for n in range(1, ROWS + 1)}
        self.assertEqual(analysis.page_start_stt(reads), 21)


class RowLineNormalizationTest(unittest.TestCase):
    @staticmethod
    def grid(lines: list[float]) -> dict:
        return {"hang_y": lines, "so_hang": len(lines) - 1, "buoc_dong": 44.0}

    def test_a_strike_line_is_merged_back_into_its_row(self) -> None:
        lines = [100.0 + 44 * k for k in range(8)]
        lines.insert(4, lines[3] + 22)  # strike through row 4 (index 3)
        fixed = rw.chuan_hoa_hang_y(self.grid(lines))
        self.assertEqual(fixed["so_hang"], 7)
        self.assertEqual(fixed["hang_y"], [100.0 + 44 * k for k in range(8)])
        self.assertAlmostEqual(fixed["buoc_dong"], 44.0)

    def test_regular_rows_and_taller_rows_are_untouched(self) -> None:
        regular = self.grid([100.0 + 44 * k for k in range(8)])
        self.assertEqual(rw.chuan_hoa_hang_y(regular)["hang_y"], regular["hang_y"])
        tall = self.grid([100, 144, 188, 288, 332, 376, 420])  # one double-height row
        self.assertEqual(rw.chuan_hoa_hang_y(tall)["hang_y"], [100, 144, 188, 288, 332, 376, 420])

    def test_two_real_short_rows_that_do_not_make_one_row_are_kept(self) -> None:
        lines = [100, 144, 188, 200, 212, 256, 300, 344]  # 12 px slivers: total 24, not a row
        self.assertEqual(rw.chuan_hoa_hang_y(self.grid(lines))["hang_y"], lines)

    def test_tiny_grids_are_returned_unchanged(self) -> None:
        tiny = self.grid([100.0, 144.0, 188.0])
        self.assertEqual(rw.chuan_hoa_hang_y(tiny)["hang_y"], [100.0, 144.0, 188.0])


class InkMeasureTest(unittest.TestCase):
    def test_ink_is_measured_in_percent_and_blank_is_zero(self) -> None:
        blank = np.full((44, 90, 3), 245, np.uint8)
        self.assertEqual(rw.do_dam_muc(blank), 0.0)
        written = blank.copy()
        cv2.putText(written, "8.5", (10, 34), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (30, 30, 30), 3)
        self.assertGreater(rw.do_dam_muc(written), rw.NGUONG_TRONG)
        self.assertEqual(rw.do_dam_muc(None), 0.0)


if __name__ == "__main__":
    unittest.main()
