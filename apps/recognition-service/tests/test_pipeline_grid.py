import unittest

import numpy as np

from src.pipeline import grid as gd
from src.pipeline.errors import PipelineError
from synthetic import make_page

# STT | Họ tên | Đ.số | Điểm chữ | Ký tên | Ghi chú (mimics the E0330113 proportions in px at 200 DPI).
SCORE_SHEET = (60, 480, 90, 210, 150, 160)
SCORE_HEADERS = ("STT", "Ho va ten", "D.so", "Diem chu", "Ky ten", "Ghi chu")
SCORE_OCR = ("STT", "Họ và tên", "Đ.số", "Điểm chữ", "Ký tên", "Ghi chú")

# High-school layout: STT | Mã HS | Họ tên | ĐĐGtx | ĐĐGgk | ĐĐGck
HIGH_SCHOOL = (60, 105, 380, 115, 130, 145)
HIGH_SCHOOL_HEADERS = ("STT", "Ma HS", "Ho ten", "DDGtx", "DDGgk", "DDGck")
HIGH_SCHOOL_OCR = ("STT", "Mã HS", "Họ tên học sinh", "ĐĐGtx", "ĐĐGgk", "ĐĐGck")


class HeaderOcr:
    """Fake printed-text OCR: answers by the width of the header cell it is shown."""

    def __init__(self, widths: tuple[int, ...], texts: tuple[str, ...]) -> None:
        # cat_o trims 3 px per side, _anh_cho_ocr scales x2 and pads 8 px per side.
        self.expected = [2 * (w - 6) + 16 for w in widths]
        self.texts = texts
        self.calls = 0

    def __call__(self, image) -> str:
        self.calls += 1
        width = image.shape[1]
        index = int(np.argmin([abs(width - w) for w in self.expected]))
        return self.texts[index]


def grid_for(columns, headers, **kwargs):
    page, layout = make_page(columns=columns, headers=headers, **kwargs)
    return page, gd.phat_hien_luoi(page)


class KeywordMatchingTest(unittest.TestCase):
    def test_header_text_maps_to_roles(self) -> None:
        cases = {
            "Đ.số": "diem_so",
            "D.s6": "diem_so",
            "Điểm số": "diem_so",
            "ĐTK": "diem_so",
            "Điểm chữ": "diem_chu",
            "Diem chu": "diem_chu",
            "Điểm bằng chữ": "diem_chu",
            "Họ và tên": "ho_ten",
            "Họ tên học sinh": "ho_ten",
            "STT": "stt",
            "Mã HS": "ma_hs",
            "Mã học sinh": "ma_hs",
            "MSSV": "ma_sv",
            "Ghi chú": "ghi_chu",
            "Ký tên": "ky_ten",
            # high school (cấp 3)
            "ĐĐGtx": "diem_qua_trinh",
            "Miệng": "diem_qua_trinh",
            "Điểm kiểm tra 15 phút": "diem_qua_trinh",
            "ĐĐGgk": "diem_so",
            "ĐĐGck": "diem_so",
            "Điểm giữa kỳ": "diem_so",
            "Điểm cuối kỳ": "diem_so",
            "Cuối kỳ": "diem_so",
        }
        for text, role in cases.items():
            self.assertEqual(gd.khop_tu_khoa(text)[0], role, text)

    def test_unrelated_text_matches_nothing(self) -> None:
        for text in ("", "x", "Trường THPT Giả", "Môn học"):
            self.assertIsNone(gd.khop_tu_khoa(text)[0], text)

    def test_accents_and_case_are_folded(self) -> None:
        self.assertEqual(gd.bo_dau("Điểm Chữ"), "diemchu")
        self.assertEqual(gd.bo_dau(None), "")


class GridDetectionTest(unittest.TestCase):
    def test_detects_rows_and_columns_of_a_ruled_table(self) -> None:
        _, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        self.assertEqual(luoi["so_hang"], 39)  # header + 38 data rows
        columns = gd._cot_du_lieu(luoi, 1)
        self.assertEqual(len(columns) - 1, 6)
        widths = np.diff(columns)
        np.testing.assert_allclose(widths, SCORE_SHEET, atol=6)

    def test_blank_paper_has_no_grid(self) -> None:
        blank = np.full((2338, 1654, 3), 246, np.uint8)
        with self.assertRaises(PipelineError) as caught:
            gd.phat_hien_luoi(blank)
        self.assertEqual(caught.exception.code, "GRID_NOT_FOUND")

    def test_three_column_table_is_not_a_gradebook(self) -> None:
        _, luoi = grid_for((80, 600, 300), ("STT", "Ho ten", "Ghi chu"), rows=20)
        with self.assertRaises(PipelineError) as caught:
            gd.bao_dam_la_bang_diem(luoi)
        self.assertEqual(caught.exception.code, "NOT_A_GRADEBOOK")
        self.assertIn("cột", caught.exception.detail)

    def test_gradebook_passes_the_structure_check(self) -> None:
        _, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        metrics = gd.bao_dam_la_bang_diem(luoi)
        self.assertEqual(metrics["so_cot"], 6)
        self.assertGreater(metrics["ty_le_rong"], 0.45)


class ColumnIdentificationTest(unittest.TestCase):
    def test_header_ocr_identifies_the_four_printed_columns(self) -> None:
        page, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        ocr = HeaderOcr(SCORE_SHEET, SCORE_OCR)
        dinh_danh = gd.dinh_danh_cot(page, luoi, ocr)
        roles = [c["vai_tro"] for c in dinh_danh["cot"]]
        self.assertEqual(
            roles, ["stt", "ho_ten", "diem_so", "diem_chu", "ky_ten", "ghi_chu"]
        )
        self.assertEqual(dinh_danh["hang_tieu_de"], 0)
        self.assertGreater(ocr.calls, 0)
        chon = gd.chon_cot_diem_bat_buoc(luoi, dinh_danh)
        self.assertEqual(chon["cot_diem_chinh"]["chi_so"], 2)
        self.assertEqual(chon["cot_diem_chu"]["chi_so"], 3)
        self.assertFalse(chon["suy_doan_hinh_hoc"])
        self.assertFalse(chon["cot_diem_chinh"].get("suy_doan", False))

    def test_without_ocr_the_narrow_column_before_the_wide_one_is_the_score(
        self,
    ) -> None:
        page, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        dinh_danh = gd.dinh_danh_cot(page, luoi, None)
        self.assertTrue(all(c["vai_tro"] is None for c in dinh_danh["cot"]))
        chon = gd.chon_cot_diem_bat_buoc(luoi, dinh_danh)
        self.assertTrue(chon["suy_doan_hinh_hoc"])
        self.assertTrue(chon["cot_diem_chinh"]["suy_doan"])
        self.assertEqual(chon["cot_diem_chinh"]["chi_so"], 2)
        self.assertEqual(chon["cot_diem_chu"]["chi_so"], 3)

    def test_ocr_that_matches_no_keyword_falls_back_to_geometry(self) -> None:
        page, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        garbage = HeaderOcr(SCORE_SHEET, ("###",) * 6)
        dinh_danh = gd.dinh_danh_cot(page, luoi, garbage)
        self.assertTrue(all(c["vai_tro"] is None for c in dinh_danh["cot"]))
        self.assertEqual(
            gd.chon_cot_diem_bat_buoc(luoi, dinh_danh)["cot_diem_chinh"]["chi_so"], 2
        )

    def test_high_school_headers_pick_the_midterm_or_final_column(self) -> None:
        page, luoi = grid_for(HIGH_SCHOOL, HIGH_SCHOOL_HEADERS)
        dinh_danh = gd.dinh_danh_cot(page, luoi, HeaderOcr(HIGH_SCHOOL, HIGH_SCHOOL_OCR))
        roles = [c["vai_tro"] for c in dinh_danh["cot"]]
        self.assertEqual(
            roles,
            ["stt", "ma_hs", "ho_ten", "diem_qua_trinh", "diem_so", "diem_so"],
        )
        chon = gd.chon_cot_diem_bat_buoc(luoi, dinh_danh)
        self.assertEqual(chon["cot_diem_chinh"]["vai_tro"], "diem_so")
        self.assertIn(chon["cot_diem_chinh"]["chi_so"], (4, 5))
        self.assertTrue(any(c["vai_tro"] == "diem_qua_trinh" for c in chon["cot_diem_phu"]))

    def test_header_reader_returns_the_requested_tiers(self) -> None:
        page, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        ocr = HeaderOcr(SCORE_SHEET, SCORE_OCR)
        tiers = gd.doc_hang_tieu_de(page, luoi, ocr, so_hang_thu=2)
        self.assertEqual(len(tiers), 2)
        self.assertEqual(len(tiers[0]["o"]), 6)
        self.assertEqual(tiers[0]["o"][2]["vai_tro"], "diem_so")

    def test_no_score_column_raises_the_stable_error(self) -> None:
        page, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        names = ("STT", "Họ và tên", "Ghi chú", "Ký tên", "Ngày sinh", "Lớp")
        dinh_danh = gd.dinh_danh_cot(page, luoi, HeaderOcr(SCORE_SHEET, names))
        self.assertTrue(any(c["vai_tro"] for c in dinh_danh["cot"]))
        with self.assertRaises(PipelineError) as caught:
            gd.chon_cot_diem_bat_buoc(luoi, dinh_danh)
        self.assertEqual(caught.exception.code, "SCORE_COLUMN_NOT_FOUND")

    def test_no_narrow_column_and_no_ocr_raises(self) -> None:
        wide = (60, 480, 300, 300, 200, 160)
        page, luoi = grid_for(wide, SCORE_HEADERS, rows=30)
        dinh_danh = gd.dinh_danh_cot(page, luoi, None)
        with self.assertRaises(PipelineError) as caught:
            gd.chon_cot_diem_bat_buoc(luoi, dinh_danh)
        self.assertEqual(caught.exception.code, "SCORE_COLUMN_NOT_FOUND")

    def test_content_scorer_can_rescue_unlabelled_columns(self) -> None:
        page, luoi = grid_for(SCORE_SHEET, SCORE_HEADERS)
        dinh_danh = gd.dinh_danh_cot(page, luoi, None)
        scored: list[tuple[float, float]] = []

        def scorer(x0: float, x1: float) -> dict:
            scored.append((x0, x1))
            narrow = (x1 - x0) < 100
            return {"ty_le_hop_le": 1.0 if narrow else 0.0, "tin_cay": 0.9}

        chon = gd.chon_cot_diem_bat_buoc(luoi, dinh_danh, scorer)
        self.assertTrue(scored)
        self.assertIn(chon["cot_diem_chinh"]["chi_so"], (0, 2))


class OcrIsolationTest(unittest.TestCase):
    def test_module_never_imports_an_ocr_engine_or_the_network(self) -> None:
        with open(gd.__file__, encoding="utf-8") as handle:
            code = handle.read().split('"""', 2)[2]
        for forbidden in ("import easyocr", "import pytesseract", "vietocr", "urllib", "requests"):
            self.assertNotIn(forbidden, code)


if __name__ == "__main__":
    unittest.main()
