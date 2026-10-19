"""Test nhỏ cho ``make_thpt_form.py`` (AC-4, phase P6). Chạy bằng venv của dịch vụ nhận dạng (cần OpenCV, Pillow):

    .local/venv-ml/Scripts/python.exe -m unittest discover -s scripts/recognition/tests

Không thuộc gate ``py`` (chỉ chạy ``apps/recognition-service/tests``), nên chạy riêng khi sửa ``make_thpt_form.py``
hoặc ``layouts/thpt_tt22.json``.
"""
import json
import sys
import unittest
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts" / "recognition"))
sys.path.insert(0, str(ROOT / "apps" / "recognition-service"))

import make_thpt_form as form  # noqa: E402
from src.domain.layout import parse_layout  # noqa: E402
from src.pipeline.layout import chuan_bi_doc, cot_can_doc, phan_tich_bo_cuc  # noqa: E402
from src.pipeline.template_match import khop_mau  # noqa: E402

LAYOUT_PATH = ROOT / "scripts" / "recognition" / "layouts" / "thpt_tt22.json"


def skewed(png: bytes, angle: float) -> bytes:
    """Ảnh quét hơi nghiêng, giấy xám và có nhiễu (như máy quét thật)."""
    image = cv2.imdecode(np.frombuffer(png, np.uint8), cv2.IMREAD_COLOR)
    height, width = image.shape[:2]
    matrix = cv2.getRotationMatrix2D((width / 2.0, height / 2.0), angle, 1.0)
    out = cv2.warpAffine(image, matrix, (width, height), flags=cv2.INTER_AREA, borderValue=(246, 246, 242))
    noise = np.random.RandomState(3).normal(0, 5.0, out.shape)
    out = np.clip(out.astype(np.float32) * 0.93 + noise, 0, 255).astype(np.uint8)
    ok, buffer = cv2.imencode(".png", cv2.GaussianBlur(out, (0, 0), 0.8))
    assert ok
    return buffer.tobytes()


class ThptFormTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.names = form.fake_names(form.N_ROWS, 20261019)
        cls.png = form.png_bytes(form.render_form(cls.names))
        cls.layout = parse_layout(LAYOUT_PATH.read_text(encoding="utf-8"))

    def test_fake_names_are_deterministic_and_distinct(self) -> None:
        self.assertEqual(self.names, form.fake_names(form.N_ROWS, 20261019))
        self.assertNotEqual(self.names, form.fake_names(form.N_ROWS, 1))
        self.assertEqual(len(set(self.names)), form.N_ROWS)

    def test_the_layout_is_valid_with_one_channel_columns(self) -> None:
        self.assertEqual(len(self.layout.signature["columnWidths"]), 9)
        self.assertEqual([c.key for c in self.layout.grade_columns], ["TX1", "TX2", "TX3", "TX4", "GK1", "CK1"])
        self.assertTrue(all(c.written_index is None for c in self.layout.grade_columns))
        self.assertEqual(self.layout.by_role("DIEM_CHU"), ())

    def test_the_layout_matches_its_own_generated_png(self) -> None:
        signature = phan_tich_bo_cuc(self.png, None).signature
        score, column_map = khop_mau(signature, self.layout.signature)
        self.assertGreaterEqual(score, 0.9)
        self.assertTrue(all(i in column_map for i in cot_can_doc(self.layout)))

    def test_the_layout_matches_a_slightly_skewed_scan(self) -> None:
        for angle in (0.4, -0.8):
            signature = phan_tich_bo_cuc(skewed(self.png, angle), None).signature
            score, column_map = khop_mau(signature, self.layout.signature)
            self.assertGreaterEqual(score, 0.9, angle)
            self.assertTrue(all(i in column_map for i in cot_can_doc(self.layout)), angle)

    def test_the_committed_layout_is_in_sync_with_the_generator(self) -> None:
        committed = json.loads(LAYOUT_PATH.read_text(encoding="utf-8"))
        fresh = form.thpt_layout(self.png)
        self.assertEqual(committed["columns"], fresh["columns"])
        for old, new in zip(committed["signature"]["columnWidths"], fresh["signature"]["columnWidths"]):
            self.assertAlmostEqual(old, new, delta=0.002)

    def test_rows_are_cut_for_all_forty_lines(self) -> None:
        page = chuan_bi_doc(self.png, self.layout, None, 0.8)
        self.assertEqual(len(page.rows), form.N_ROWS)
        self.assertTrue(page.has_stt)

    def test_another_template_is_rejected(self) -> None:
        from src.pipeline.errors import PipelineError

        other = parse_layout(
            json.dumps(
                {
                    "signature": {"version": 1, "columnWidths": [0.05, 0.12, 0.27, 0.1, 0.13, 0.055, 0.11, 0.08, 0.09]},
                    "columns": [
                        {"index": 0, "role": "STT"},
                        {"index": 2, "role": "HO_TEN"},
                        {"index": 5, "role": "DIEM", "key": "CK1", "writtenIndex": 6},
                        {"index": 6, "role": "DIEM_CHU"},
                    ],
                }
            )
        )
        with self.assertRaises(PipelineError) as raised:
            chuan_bi_doc(self.png, other, None, 0.8)
        self.assertEqual(raised.exception.code, "TEMPLATE_MISMATCH")

    def test_png_and_pdf_are_written(self) -> None:
        import tempfile

        with tempfile.TemporaryDirectory() as directory:
            image = form.render_form(self.names[:5])
            self.assertEqual(image.size, form.PAGE_PX)
            pdf = Path(directory) / "form.pdf"
            image.save(pdf, "PDF", resolution=float(form.DPI))
            self.assertTrue(pdf.read_bytes().startswith(b"%PDF"))


if __name__ == "__main__":
    unittest.main()
