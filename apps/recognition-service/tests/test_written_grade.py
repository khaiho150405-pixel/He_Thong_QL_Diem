import unittest
from decimal import Decimal

from src.domain import written_grade as wg


class WrittenGradeTest(unittest.TestCase):
    def test_spoken_grades_become_numbers(self) -> None:
        cases = {
            "tám rưỡi": 8.5,
            "mười": 10.0,
            "chín chẵn": 9.0,
            "bảy hai": 7.2,
            "bảy tư": 7.4,
            "không năm": 0.5,
            "không": 0.0,
            "mười chẵn": 10.0,
            "  Tám   RƯỠI ".replace("  ", " ").strip(): 8.5,
        }
        for text, value in cases.items():
            self.assertEqual(wg.so_tu_chuoi_chu(text), value, text)

    def test_invalid_written_grades_are_none(self) -> None:
        for text in ("", "xin chào", "mười rưỡi", "tám tám tám", "mười một", "tam ruoi", "8.5", "ba", "rưỡi"):
            if text == "ba":
                self.assertEqual(wg.so_tu_chuoi_chu(text), 3.0)  # a single whole number is valid
            else:
                self.assertIsNone(wg.so_tu_chuoi_chu(text), text)

    def test_numeric_text_to_grade(self) -> None:
        cases = {"7.5": 7.5, "6": 6.0, "8.": 8.0, "10": 10.0, "10.0": 10.0, "0": 0.0, "0.0": 0.0, " 9.5 ": 9.5}
        for text, value in cases.items():
            self.assertEqual(wg.so_tu_chuoi_so(text), value, text)
        for text in ("", ".", "10.1", "11", "7.55", "a", "7,5", "-1", "7..5"):
            self.assertIsNone(wg.so_tu_chuoi_so(text), text)

    def test_zero_is_a_grade_not_missing(self) -> None:
        self.assertEqual(wg.so_tu_chuoi_so("0.0"), 0.0)
        self.assertIsNotNone(wg.so_tu_chuoi_so("0"))
        self.assertEqual(wg.grade_decimal(0.0), Decimal("0.0"))
        self.assertIsNone(wg.grade_decimal(None))
        self.assertEqual(wg.grade_decimal(7.5), Decimal("7.5"))
        self.assertEqual(wg.grade_decimal(10.0), Decimal("10.0"))

    def test_dictionary_has_133_valid_phrases(self) -> None:
        self.assertEqual(len(wg.TU_DIEN), 133)
        self.assertEqual(len(set(wg.TU_DIEN)), 133)
        for phrase in wg.TU_DIEN:
            value = wg.so_tu_chuoi_chu(phrase)
            self.assertIsNotNone(value, phrase)
            self.assertTrue(0.0 <= value <= 10.0)

    def test_original_snapping_always_maps_to_a_phrase(self) -> None:
        self.assertEqual(wg.hau_xu_ly_tu_dien("tám rưởi", list(wg.TU_DIEN)), "tám rưỡi")
        self.assertEqual(wg.hau_xu_ly_tu_dien("tám rưỡi", list(wg.TU_DIEN)), "tám rưỡi")
        self.assertEqual(wg.hau_xu_ly_tu_dien("", list(wg.TU_DIEN)), "")
        # The source algorithm turns arbitrary noise into some valid phrase; the guarded version below must not.
        self.assertIn(wg.hau_xu_ly_tu_dien("qqqq zzzz", list(wg.TU_DIEN)), wg.TU_DIEN)

    def test_guarded_snapping_does_not_invent_a_grade_from_noise(self) -> None:
        self.assertEqual(wg.nan_diem_chu("tám rưởi"), "tám rưỡi")  # one edit away
        self.assertEqual(wg.nan_diem_chu("sau hai"), "sáu hai")
        self.assertEqual(wg.nan_diem_chu("mười"), "mười")
        self.assertEqual(wg.nan_diem_chu(""), "")
        noise = "qqqq zzzz xx"
        self.assertEqual(wg.nan_diem_chu(noise), noise)
        self.assertIsNone(wg.so_tu_chuoi_chu(wg.nan_diem_chu(noise)))
        self.assertEqual(wg.nan_diem_chu("tám rưởi", khoang_cach_toi_da=0), "tám rưởi")

    def test_distance(self) -> None:
        self.assertEqual(wg.khoang_cach_sua("abc", "abc"), 0)
        self.assertEqual(wg.khoang_cach_sua("abc", "abd"), 1)
        self.assertEqual(wg.khoang_cach_sua("", "abc"), 3)

    def test_no_arbiter_branch_is_ported(self) -> None:
        with open(wg.__file__, encoding="utf-8") as handle:
            code = handle.read().split('"""', 2)[2]
        self.assertNotIn("def hop_nhat_mot_o", code)
        self.assertNotIn("hieu_chuan", code)


if __name__ == "__main__":
    unittest.main()
