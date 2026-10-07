"""Short tables: the last page of a class has only a header and a few rows (BE-16, ADR-0015)."""
import unittest

import cv2

from src.pipeline import grid as gd
from src.pipeline import page as pg
from src.pipeline import rows as rw
from synthetic import encode_png, make_page, photograph, scan
from test_pipeline_grid import SCORE_HEADERS, SCORE_SHEET


def short_sheet(n: int, line_gaps: float = 0.0, struck: tuple[int, ...] = ()):
    cell_text = {}
    ink = []
    for row in range(n):
        cell_text[(row, 1)] = f"Hoc sinh {row + 1:02d}"
        cell_text[(row, 3)] = "tam ruoi"
        ink.append((row, 2))
    return make_page(
        rows=n,
        columns=SCORE_SHEET,
        headers=SCORE_HEADERS,
        header_height=45,
        cell_text=cell_text,
        ink_cells=tuple(ink),
        struck_rows=struck,
        first_stt=39,
        line_gaps=line_gaps,
    )[0]


class ShortTableTest(unittest.TestCase):
    def check(self, image, n: int, label: str, struck: int = 0) -> None:
        analysis = rw.analyze_page(encode_png(image), None)
        self.assertEqual(len(analysis.rows), n, label)
        self.assertEqual(analysis.grid["so_hang"], n + 1, label)
        self.assertEqual(sum(r.struck for r in analysis.rows), struck, label)
        self.assertEqual(sum(r.has_grade_ink for r in analysis.rows), n - struck, label)
        self.assertTrue(all(r.has_name_ink for r in analysis.rows), label)
        self.assertEqual(analysis.selection["cot_diem_chinh"]["chi_so"], 2, label)

    def test_header_plus_one_two_three_and_five_rows_in_a_phone_photo(self) -> None:
        for n in (1, 2, 3, 5):
            with self.subTest(rows=n):
                photo = photograph(short_sheet(n), angle=4.0, perspective=0.03)
                self.check(photo, n, f"phone {n}")

    def test_the_same_tables_on_a_flatbed_scan(self) -> None:
        for n in (1, 2, 3, 5):
            with self.subTest(rows=n):
                self.check(scan(short_sheet(n)), n, f"scan {n}")

    def test_broken_row_lines_do_not_lose_the_table(self) -> None:
        for n in (2, 3, 5):
            with self.subTest(rows=n):
                page = short_sheet(n, line_gaps=0.35)
                self.check(scan(page), n, f"scan gaps {n}")
                self.check(photograph(page, angle=-3.0), n, f"phone gaps {n}")

    def test_a_struck_row_in_a_short_table_is_still_one_row(self) -> None:
        page = short_sheet(3, struck=(1,))
        self.check(scan(page), 3, "scan struck", struck=1)
        self.check(photograph(page, angle=3.0), 3, "phone struck", struck=1)

    def test_grid_is_found_from_the_vertical_rules_alone(self) -> None:
        flat = scan(short_sheet(3, line_gaps=0.4))
        luoi = gd.trich_luoi(flat)
        self.assertIsNotNone(luoi)
        self.assertEqual(luoi["nguon_luoi"], "vach_doc")
        self.assertEqual(luoi["so_hang"], 4)
        self.assertEqual(len(gd._cot_du_lieu(luoi, 1)) - 1, 6)

    def test_long_tables_still_use_the_same_rows(self) -> None:
        page, _ = make_page(rows=38, columns=SCORE_SHEET, headers=SCORE_HEADERS, header_height=45)
        luoi = gd.trich_luoi(scan(page))
        self.assertEqual(luoi["so_hang"], 39)

    def test_lines_outside_the_vertical_rules_are_not_rows(self) -> None:
        page = short_sheet(3)
        # A ruled signature line well below the table must not extend it.
        cv2.line(page, (200, 900), (1200, 900), (35, 35, 35), 3)
        cv2.line(page, (200, 940), (1200, 940), (35, 35, 35), 3)
        luoi = gd.trich_luoi(scan(page))
        self.assertEqual(luoi["so_hang"], 4)

    def test_flattening_keeps_straight_lines_for_a_tiny_table(self) -> None:
        photo = photograph(short_sheet(1), angle=4.0)
        flat = pg.nan_trang(photo)["page"]
        luoi = gd.trich_luoi(flat)
        self.assertIsNotNone(luoi)
        self.assertEqual(luoi["so_hang"], 2)


if __name__ == "__main__":
    unittest.main()
