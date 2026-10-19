"""Test nhỏ cho phép chấm AC-1 của ``evaluate_pages.py`` (phase P6). Chạy bằng venv của dịch vụ nhận dạng:

    .local/venv-ml/Scripts/python.exe -m unittest discover -s scripts/recognition/tests
"""
import collections
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts" / "recognition"))

import evaluate_pages as ev  # noqa: E402


def counts(labelled: int, read: int, num_ok: int, txt_ok: int, **extra: int) -> collections.Counter:
    return collections.Counter(labelled=labelled, read=read, num_ok=num_ok, txt_ok=txt_ok, **extra)


class RegressionChecksTest(unittest.TestCase):
    def test_same_accuracy_on_same_rows_passes(self) -> None:
        v1 = counts(1000, 1000, 990, 988)
        v2 = counts(1000, 1000, 990, 988)
        self.assertTrue(all(ev.regression_checks(v1, v2).values()))

    def test_rejected_pages_cannot_hide_a_regression(self) -> None:
        # v2 từ chối trang nên chỉ đọc 900/1000 dòng; trên dòng đọc được còn chính xác hơn v1, nhưng trên cùng tập thì tụt ~9 điểm %.
        v1 = counts(1000, 1000, 990, 988)
        v2 = counts(1000, 900, 895, 890)
        self.assertGreaterEqual(100 * v2["num_ok"] / v2["read"], 100 * v1["num_ok"] / v1["read"])
        checks = ev.regression_checks(v1, v2)
        failed = [label for label, ok in checks.items() if not ok]
        self.assertEqual(len(failed), 2)
        self.assertTrue(all("trên mọi dòng có nhãn" in label for label in failed))

    def test_tolerance_is_half_a_percentage_point(self) -> None:
        v1 = counts(1000, 1000, 990, 990)
        self.assertTrue(all(ev.regression_checks(v1, counts(1000, 1000, 985, 985)).values()))
        self.assertFalse(all(ev.regression_checks(v1, counts(1000, 1000, 984, 985)).values()))

    def test_wrong_match_or_wrong_green_fails(self) -> None:
        v1 = counts(100, 100, 99, 99)
        self.assertFalse(all(ev.regression_checks(v1, counts(100, 100, 99, 99, match_wrong=1)).values()))
        self.assertFalse(all(ev.regression_checks(v1, counts(100, 100, 99, 99, green_wrong=1)).values()))
        self.assertFalse(all(ev.regression_checks(v1, counts(100, 100, 99, 99, final_green_wrong=1)).values()))

    def test_no_labelled_rows_never_passes(self) -> None:
        empty = counts(0, 0, 0, 0)
        self.assertFalse(all(ev.regression_checks(empty, empty).values()))


if __name__ == "__main__":
    unittest.main()
