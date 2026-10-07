import math
import unittest

import numpy as np

from src.pipeline import page as pg
from src.pipeline.errors import PipelineError
from src.pipeline.quality import (
    CHAN,
    NET_KEM,
    assess_quality,
    do_net,
    ensure_quality,
)
from synthetic import encode_png, make_page, photograph


def horizontal_slopes(flat: np.ndarray) -> list[float]:
    bw = pg._nhi_phan(flat)
    lines = pg._do_vach(bw, "ngang", nhan_mo=61, dai_toi_thieu=int(0.30 * bw.shape[1]))
    return [abs(line["a"]) for line in lines]


def vertical_slopes(flat: np.ndarray) -> list[float]:
    bw = pg._nhi_phan(flat)
    lines = pg._do_vach(bw, "doc", nhan_mo=61, dai_toi_thieu=200)
    return [abs(line["a"]) for line in lines]


class PageFlatteningTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.layout_page, cls.layout = make_page()
        cls.photo = photograph(cls.layout_page, angle=5.0, perspective=0.025)
        cls.result = pg.nan_trang(cls.photo)

    def test_flat_page_has_a4_size_and_straight_ruled_lines(self) -> None:
        flat = self.result["page"]
        self.assertEqual(flat.shape[:2], (pg.A4[1], pg.A4[0]))
        horizontal = horizontal_slopes(flat)
        vertical = vertical_slopes(flat)
        # 38 data rows + header + closing line, all ruled lines almost perfectly horizontal.
        self.assertGreaterEqual(len(horizontal), 38)
        self.assertGreaterEqual(len(vertical), 6)
        limit = math.tan(math.radians(0.3))
        self.assertLess(float(np.median(horizontal)), limit)
        self.assertLess(max(horizontal), math.tan(math.radians(0.6)))
        self.assertLess(float(np.median(vertical)), limit)

    def test_measures_the_posture_of_the_paper(self) -> None:
        self.assertFalse(self.result["cham_bien"])
        self.assertEqual(self.result["canh_thieu"], [])
        self.assertAlmostEqual(self.result["goc_nghieng_giay"], 5.0, delta=1.5)
        self.assertGreater(self.result["meo_phoi_canh"], 0.0)
        self.assertGreater(self.result["ty_le_quad"], 0.2)

    def test_other_pose_is_also_straightened(self) -> None:
        photo = photograph(self.layout_page, angle=-4.0, perspective=0.05, scale=0.78)
        flat = pg.nan_trang(photo)["page"]
        self.assertLess(
            float(np.median(horizontal_slopes(flat))), math.tan(math.radians(0.3))
        )

    def test_is_deterministic(self) -> None:
        again = pg.nan_trang(self.photo)
        self.assertTrue(np.array_equal(again["page"], self.result["page"]))
        self.assertEqual(again["quad"], self.result["quad"])

    def test_decodes_png_bytes_and_rejects_garbage(self) -> None:
        image = pg.doc_anh(encode_png(self.layout_page))
        self.assertEqual(image.shape, self.layout_page.shape)
        for content in (b"", b"not an image", b"\x89PNG\r\n\x1a\n" + b"\x00" * 16):
            with self.assertRaises(PipelineError) as caught:
                pg.doc_anh(content)
            self.assertEqual(caught.exception.code, "IMAGE_UNREADABLE")

    def test_no_file_name_hooks_remain(self) -> None:
        with open(pg.__file__, encoding="utf-8") as handle:
            code = handle.read().split('"""', 2)[2]  # everything after the module docstring
        # The hand-tuned quads of the training project must never reach production code.
        for forbidden in ("QUAD_OVERRIDES", "ten_file", "R05_T01", "P06_S01", "pillow_heif"):
            self.assertNotIn(forbidden, code)


class QualityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.layout_page, _ = make_page()

    def test_sharp_photo_passes(self) -> None:
        photo = photograph(self.layout_page)
        result = pg.nan_trang(photo)
        report = ensure_quality(photo, result["page"], result)
        self.assertEqual(report.blocking, ())
        self.assertGreater(report.metrics["do_net"], NET_KEM)
        self.assertGreater(report.metrics["dpi_hieu_dung"], 100)
        self.assertEqual(report.metrics["canh_giay_ngoai_khung"], [])

    def test_blurred_photo_is_rejected_as_image_quality_low(self) -> None:
        photo = photograph(self.layout_page, blur=9.0)
        result = pg.nan_trang(photo)
        report = assess_quality(photo, result["page"], result)
        self.assertLess(report.metrics["do_net"], NET_KEM)
        self.assertTrue(any(level == CHAN for level, _ in report.warnings))
        with self.assertRaises(PipelineError) as caught:
            ensure_quality(photo, result["page"], result)
        self.assertEqual(caught.exception.code, "IMAGE_QUALITY_LOW")
        self.assertIn("mờ", caught.exception.detail)

    def test_tiny_photo_is_rejected_for_resolution(self) -> None:
        photo = photograph(self.layout_page, canvas=(1100, 800), scale=0.30)
        result = pg.nan_trang(photo)
        with self.assertRaises(PipelineError) as caught:
            ensure_quality(photo, result["page"], result)
        self.assertEqual(caught.exception.code, "IMAGE_QUALITY_LOW")
        self.assertIn("DPI", caught.exception.detail)

    def test_warnings_do_not_block(self) -> None:
        photo = photograph(self.layout_page, angle=9.0, perspective=0.07)
        result = pg.nan_trang(photo)
        report = ensure_quality(photo, result["page"], result)
        self.assertTrue(report.warnings)
        self.assertTrue(all(level != CHAN for level, _ in report.warnings))

    def test_sharpness_uses_the_table_box_when_given(self) -> None:
        page, layout = self.layout_page, make_page()[1]
        box = (layout["xs"][0], layout["ys"][0], layout["xs"][-1], layout["ys"][-1])
        self.assertGreater(do_net(page, box), do_net(page))
        self.assertEqual(do_net(np.zeros((50, 50, 3), np.uint8)), 0.0)


class ErrorCodeTest(unittest.TestCase):
    def test_only_stable_codes_are_allowed(self) -> None:
        with self.assertRaises(ValueError):
            PipelineError("SOMETHING_ELSE")
        error = PipelineError("GRID_NOT_FOUND", "x")
        self.assertEqual((error.code, error.detail), ("GRID_NOT_FOUND", "x"))


if __name__ == "__main__":
    unittest.main()
