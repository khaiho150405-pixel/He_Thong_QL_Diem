import base64
import contextlib
import inspect
import io
import json
import logging
import os
import re
import unittest
from decimal import Decimal
from pathlib import Path
from unittest import mock
from unittest.mock import patch

import cv2
import numpy as np
from fastapi.testclient import TestClient

from src.adapters.model import WeightsRecognitionModel
from src.adapters.vietocr_reader import TextRead
from src.api import main as api_main
from src.api.main import app
from src.domain.layout import InvalidLayoutError, parse_layout
from src.pipeline import grid as grid_module
from src.pipeline import rows as rows_module
from src.pipeline.errors import PipelineError
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
from test_weights_model import StubCrnn, StubVietOcr, build, sheet_photo

FAKE_ENV = {"APP_ENV": "test", "RECOGNITION_MODEL_MODE": "fake"}
VERSION = "crnn-dot5+vietocr-tang4+name-vgg:abcdef012345"

ROWS = 10
FILLED = (0, 1, 2, 3, 4, 5, 7)  # zero-based; row 6, 8 and 9 are blank
STRUCK = 7  # zero-based
BLANK = 6

STT_COLUMN = {"index": 0, "role": "STT"}
NAME_COLUMN = {"index": 1, "role": "HO_TEN"}
TX1 = {"index": 2, "role": "DIEM", "key": "TX1"}
GK = {"index": 6, "role": "DIEM", "key": "GK1"}
CK = {"index": 7, "role": "DIEM", "key": "CK1"}


class ThptNameReader:
    """Name model double: header cells (2-D greyscale) are answered by width like ``HeaderOcr``; STT cells are narrow."""

    sha256 = "c" * 64

    def __init__(self, stt_values=None) -> None:
        self.header = HeaderOcr(THPT_COLUMNS, THPT_OCR)
        self.stt_values = list(stt_values) if stt_values is not None else None
        self.stt_cells_read = 0
        self.header_reads = 0

    def read_cells(self, images):
        out = []
        for image in images:
            if image.ndim == 2:
                self.header_reads += 1
                out.append(TextRead(self.header(image), 0.9))
            elif image.shape[1] < 100:
                value = self.stt_values[self.stt_cells_read] if self.stt_values else None
                self.stt_cells_read += 1
                out.append(TextRead("" if value is None else str(value), 0.95))
            else:
                out.append(TextRead("Họ tên giả", 0.93))
        return out


def weights_model(crnn=None, vietocr=None, name=None, stt_check=False) -> WeightsRecognitionModel:
    return WeightsRecognitionModel(
        crnn or StubCrnn(), vietocr or StubVietOcr(), name or ThptNameReader(), VERSION, stt_check
    )


def thpt_page(**kwargs):
    return make_thpt_page(
        rows=ROWS, filled_rows=FILLED, struck_rows=(STRUCK,), **kwargs
    )[0]


def thpt_photo(**photo) -> bytes:
    return encode_png(photograph(thpt_page(), angle=2.0, perspective=0.02, **photo))


def other_photo() -> bytes:
    page, _ = make_thpt_page(
        rows=ROWS,
        columns=OTHER_COLUMNS,
        headers=OTHER_HEADERS,
        score_columns=(3, 4, 5, 6),
        name_column=2,
    )
    return encode_png(photograph(page))


def post_analyze(client: TestClient, image: bytes):
    return client.post("/v2/layout/analyze", files={"image": ("s.png", image, "image/png")})


def post_recognize(client: TestClient, image: bytes, layout):
    text = layout if isinstance(layout, str) else json.dumps(layout)
    return client.post(
        "/v2/recognize",
        data={"layout": text},
        files={"image": ("s.png", image, "image/png")},
    )


def layout_of(signature, *columns):
    return {"signature": signature, "columns": list(columns)}


class V2TestBase(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.client = TestClient(app)
        cls.image = thpt_photo()
        model = weights_model()
        with patch("src.api.main.configured_model", return_value=model):
            cls.analysis = post_analyze(cls.client, cls.image).json()
        cls.signature = cls.analysis["signature"]


class LayoutAnalyzeTest(V2TestBase):
    def test_returns_all_nine_columns_of_the_high_school_sheet(self) -> None:
        columns = self.analysis["columns"]
        self.assertEqual(len(columns), 9)
        self.assertEqual([c["index"] for c in columns], list(range(9)))
        self.assertEqual(len(self.signature["columnWidths"]), 9)

    def test_suggested_roles_follow_the_printed_headers(self) -> None:
        roles = [c["suggestedRole"] for c in self.analysis["columns"]]
        self.assertEqual(roles[:2], ["STT", "HO_TEN"])
        self.assertEqual(roles[2:8], ["DIEM"] * 6)
        self.assertEqual(roles[8], "BO_QUA")
        groups = [(c["suggestedGroup"], c["suggestedOrder"]) for c in self.analysis["columns"][2:8]]
        self.assertEqual(groups, [("TX", 1), ("TX", 2), ("TX", 3), ("TX", 4), ("GK", 1), ("CK", 1)])
        self.assertEqual(self.analysis["columns"][1]["headerText"], "Họ và tên")

    def test_columns_carry_ratios_and_widths_in_millimetres(self) -> None:
        columns = self.analysis["columns"]
        self.assertAlmostEqual(columns[0]["x0"], 0.0, places=3)
        self.assertAlmostEqual(columns[-1]["x1"], 1.0, places=3)
        for left, right in zip(columns, columns[1:]):
            self.assertAlmostEqual(left["x1"], right["x0"], places=3)
        # the name column is 380 px of 1430 at 200 DPI = 48.2 mm
        self.assertAlmostEqual(columns[1]["widthMm"], 48.2, delta=1.5)

    def test_preview_is_a_png_no_wider_than_1400_px(self) -> None:
        raw = base64.b64decode(self.analysis["previewPngBase64"])
        self.assertTrue(raw.startswith(b"\x89PNG"))
        preview = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
        self.assertLessEqual(preview.shape[1], 1400)
        self.assertGreater(preview.shape[1], 1000)
        # the grid is drawn in red over the (white/black) sheet
        red = (preview[..., 2] > 200) & (preview[..., 1] < 60) & (preview[..., 0] < 60)
        self.assertGreater(int(red.sum()), 2000)

    def test_without_readable_headers_the_roles_are_null(self) -> None:
        class Silent:
            sha256 = "c" * 64

            def read_cells(self, images):
                return [TextRead("", 0.0) for _ in images]

        with patch("src.api.main.configured_model", return_value=weights_model(name=Silent())):
            body = post_analyze(self.client, self.image).json()
        self.assertEqual(len(body["columns"]), 9)
        self.assertTrue(all(c["suggestedRole"] is None for c in body["columns"]))
        self.assertTrue(all(c["headerText"] == "" for c in body["columns"]))

    def test_the_fake_model_uses_real_geometry_and_no_header_ocr(self) -> None:
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            body = post_analyze(self.client, self.image).json()
        self.assertEqual(len(body["columns"]), 9)
        self.assertTrue(all(c["suggestedRole"] is None for c in body["columns"]))

    def test_unusable_images_use_the_stable_error_codes(self) -> None:
        blurred = encode_png(photograph(thpt_page(), blur=9.0))
        paper = np.full((2338, 1654, 3), 246, np.uint8)
        cv2.putText(paper, "NOTES", (200, 400), cv2.FONT_HERSHEY_SIMPLEX, 3, (30, 30, 30), 6)
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            garbage = post_analyze(self.client, b"hello")
            quality = post_analyze(self.client, blurred)
            nothing = post_analyze(self.client, encode_png(photograph(paper)))
            empty = post_analyze(self.client, b"")
        self.assertEqual(
            [r.status_code for r in (garbage, quality, nothing, empty)], [422, 422, 422, 422]
        )
        self.assertEqual(garbage.json()["detail"]["code"], "IMAGE_UNREADABLE")
        self.assertEqual(quality.json()["detail"]["code"], "IMAGE_QUALITY_LOW")
        self.assertIn(nothing.json()["detail"]["code"], {"GRID_NOT_FOUND", "IMAGE_QUALITY_LOW"})
        self.assertEqual(empty.json()["detail"]["code"], "IMAGE_UNREADABLE")

    def test_production_without_weights_is_unavailable_even_for_the_fake_mode(self) -> None:
        for env in ({"APP_ENV": "production"}, {"APP_ENV": "production", "RECOGNITION_MODEL_MODE": "fake"}):
            with patch.dict(os.environ, env, clear=True):
                self.assertEqual(post_analyze(self.client, self.image).status_code, 503)
                layout = layout_of(self.signature, STT_COLUMN, NAME_COLUMN, TX1)
                response = post_recognize(self.client, self.image, layout)
                self.assertEqual((response.status_code, response.json()["detail"]), (503, "MODEL_UNAVAILABLE"))


class RecognizeV2Test(V2TestBase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls.layout = layout_of(cls.signature, STT_COLUMN, NAME_COLUMN, TX1, GK, CK)

    def fake(self, layout=None, image=None, env=None):
        with patch.dict(os.environ, {**FAKE_ENV, **(env or {})}, clear=True):
            return post_recognize(self.client, image or self.image, layout or self.layout)

    def test_fake_returns_exactly_the_requested_keys_in_row_order(self) -> None:
        response = self.fake()
        self.assertEqual(response.status_code, 200, response.text)
        body = response.json()
        self.assertEqual(set(body), {"modelVersion", "pageStartStt", "templateMatch", "rows"})
        self.assertEqual(body["modelVersion"], "fake-dev-v2")
        self.assertEqual([r["rowIndex"] for r in body["rows"]], list(range(1, ROWS + 1)))
        for row in body["rows"]:
            self.assertEqual([g["key"] for g in row["grades"]], ["TX1", "GK1", "CK1"])
            self.assertEqual(
                set(row),
                {"rowIndex", "struck", "stt", "name", "nameCropBase64", "sttRead", "sttFromPosition", "grades"},
            )
            self.assertEqual(
                set(row["grades"][0]),
                {
                    "key",
                    "numeric",
                    "written",
                    "numericCropBase64",
                    "writtenCropBase64",
                    "comparison",
                    "reviewLevel",
                    "suggestedSource",
                },
            )
        match = body["templateMatch"]
        self.assertGreaterEqual(match["score"], 0.9)
        self.assertEqual(match["columnMap"], {str(i): i for i in range(9)})

    def test_single_channel_columns_have_no_written_and_are_never_green(self) -> None:
        body = self.fake().json()
        for row in body["rows"]:
            for grade in row["grades"]:
                self.assertIsNone(grade["written"])
                self.assertIsNone(grade["writtenCropBase64"])
                self.assertNotEqual(grade["reviewLevel"], "XANH")
                if not row["struck"]:
                    self.assertEqual(grade["comparison"], "MOT_KENH")
                    self.assertEqual(grade["reviewLevel"], "VANG")
                    self.assertEqual(grade["suggestedSource"], "SO")

    def test_a_column_with_a_written_partner_reads_two_channels_and_can_be_green(self) -> None:
        # Column 3 plays the role of the written-grade column of column 2; GK stays single-channel.
        layout = layout_of(
            self.signature,
            NAME_COLUMN,
            {**TX1, "writtenIndex": 3},
            {"index": 3, "role": "DIEM_CHU"},
            GK,
        )
        body = self.fake(layout).json()
        row = next(r for r in body["rows"] if not r["struck"])
        two, one = row["grades"]
        self.assertEqual((two["key"], one["key"]), ("TX1", "GK1"))
        self.assertIsNotNone(two["written"])
        self.assertIsNotNone(two["writtenCropBase64"])
        self.assertEqual((two["comparison"], two["reviewLevel"]), ("KHOP", "XANH"))
        self.assertIsNone(one["written"])
        self.assertNotEqual(one["reviewLevel"], "XANH")

    def test_the_stt_column_is_optional(self) -> None:
        body = self.fake(layout_of(self.signature, NAME_COLUMN, TX1)).json()
        self.assertIsNone(body["pageStartStt"])
        first = body["rows"][0]
        self.assertTrue(first["stt"]["isBlank"])
        self.assertEqual([g["key"] for g in first["grades"]], ["TX1"])

    def test_fake_configuration_start_stt_and_row_limit(self) -> None:
        body = self.fake(env={"FAKE_START_STT": "39", "FAKE_DETECTED_ROWS": "3"}).json()
        self.assertEqual(body["pageStartStt"], 39)
        self.assertEqual([r["stt"]["value"] for r in body["rows"]], [39, 40, 41])

    def test_struck_rows_come_from_the_image_and_are_red_without_a_suggestion(self) -> None:
        body = self.fake().json()
        struck = [r["struck"] for r in body["rows"]]
        self.assertEqual(struck, [i == STRUCK for i in range(ROWS)])
        for grade in body["rows"][STRUCK]["grades"]:
            self.assertEqual(grade["reviewLevel"], "DO")
            self.assertIsNone(grade["suggestedSource"])
            self.assertTrue(grade["numeric"]["isBlank"])

    def test_the_response_does_not_depend_on_the_order_of_layout_columns(self) -> None:
        reordered = layout_of(self.signature, CK, TX1, NAME_COLUMN, GK, STT_COLUMN)
        body = self.fake(reordered).json()
        self.assertEqual([g["key"] for g in body["rows"][0]["grades"]], ["CK1", "TX1", "GK1"])


class WeightsModelV2Test(V2TestBase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls.layout = layout_of(
            cls.signature,
            STT_COLUMN,
            NAME_COLUMN,
            {**TX1, "writtenIndex": 3},
            {"index": 3, "role": "DIEM_CHU"},
            GK,
        )

    def run_model(self, model=None, layout=None, env=None):
        model = model or weights_model()
        with patch("src.api.main.configured_model", return_value=model), patch.dict(
            os.environ, env or {}, clear=True
        ):
            return post_recognize(self.client, self.image, layout or self.layout)

    def test_each_row_is_read_once_and_each_column_by_its_own_model(self) -> None:
        crnn, vietocr, name = StubCrnn(), StubVietOcr(), ThptNameReader()
        response = self.run_model(weights_model(crnn, vietocr, name))
        self.assertEqual(response.status_code, 200, response.text)
        body = response.json()
        filled = [r for r in body["rows"] if not r["struck"] and r["grades"][0]["numeric"]["value"]]
        self.assertEqual(len(filled), 6)  # rows 1-6; 7 is blank, 8 struck, 9-10 blank
        self.assertEqual(body["modelVersion"], VERSION)
        first = body["rows"][0]
        self.assertEqual(first["name"]["raw"], "Họ tên giả")
        two, one = first["grades"]
        self.assertEqual(two["numeric"]["value"], "8.5")
        self.assertEqual(two["written"]["value"], "8.5")
        self.assertEqual(two["written"]["rawOutput"], "tám rưỡi")
        self.assertEqual((two["comparison"], two["reviewLevel"], two["suggestedSource"]), ("KHOP", "XANH", "SO"))
        self.assertIsNone(one["written"])
        self.assertEqual((one["comparison"], one["reviewLevel"], one["suggestedSource"]), ("MOT_KENH", "VANG", "SO"))

    def test_a_single_channel_column_is_never_green_even_when_the_model_is_certain(self) -> None:
        body = self.run_model(weights_model(StubCrnn(score_conf=0.999))).json()
        for row in body["rows"]:
            self.assertNotEqual(row["grades"][1]["reviewLevel"], "XANH")

    def test_a_weak_single_channel_reading_is_red_without_a_suggestion(self) -> None:
        body = self.run_model(weights_model(StubCrnn(score_conf=0.4))).json()
        grade = body["rows"][0]["grades"][1]
        self.assertEqual(grade["numeric"]["value"], "8.5")
        self.assertEqual((grade["reviewLevel"], grade["suggestedSource"]), ("DO", None))

    def test_blank_and_struck_rows_are_handled_like_v1(self) -> None:
        body = self.run_model().json()
        for index in (BLANK, 8, 9):
            for grade in body["rows"][index]["grades"]:
                self.assertTrue(grade["numeric"]["isBlank"], index)
                self.assertEqual((grade["comparison"], grade["reviewLevel"]), ("KHONG_DOC_DUOC", "DO"))
            self.assertTrue(body["rows"][index]["name"]["isBlank"])
        struck = body["rows"][STRUCK]
        self.assertTrue(struck["struck"])
        self.assertTrue(struck["name"]["isBlank"])
        for grade in struck["grades"]:
            self.assertEqual(grade["reviewLevel"], "DO")

    def test_invalid_numeric_text_is_unreadable_not_clamped(self) -> None:
        body = self.run_model(weights_model(StubCrnn(score_text="11"))).json()
        grade = body["rows"][0]["grades"][1]
        self.assertIsNone(grade["numeric"]["value"])
        self.assertEqual(grade["numeric"]["rawOutput"], "11")

    def test_stt_is_read_with_the_name_model_only_when_the_template_has_an_stt_column(self) -> None:
        reads = [i for i in range(1, ROWS + 1) if i != STRUCK + 1]
        crnn, name = StubCrnn(), ThptNameReader(stt_values=reads)
        body = self.run_model(weights_model(crnn, name=name, stt_check=True)).json()
        self.assertEqual(crnn.stt_calls, 0)
        self.assertEqual(name.stt_cells_read, len(reads))
        self.assertEqual(body["pageStartStt"], 1)
        self.assertEqual(body["rows"][2]["stt"]["value"], 3)
        self.assertEqual(body["rows"][2]["sttRead"], 3)
        self.assertEqual(body["rows"][2]["sttFromPosition"], 3)
        no_stt = layout_of(self.signature, NAME_COLUMN, GK)
        name = ThptNameReader(stt_values=reads)
        body = self.run_model(weights_model(name=name, stt_check=True), no_stt).json()
        self.assertEqual(name.stt_cells_read, 0)
        self.assertIsNone(body["pageStartStt"])

    def test_without_the_stt_check_the_stt_stays_unread(self) -> None:
        name = ThptNameReader(stt_values=list(range(1, 20)))
        body = self.run_model(weights_model(name=name, stt_check=False)).json()
        self.assertEqual(name.stt_cells_read, 0)
        self.assertTrue(all(r["stt"]["isBlank"] and r["stt"]["value"] is None for r in body["rows"]))

    def test_crops_are_png_for_every_channel(self) -> None:
        body = self.run_model().json()
        for row in body["rows"]:
            self.assertTrue(base64.b64decode(row["nameCropBase64"]).startswith(b"\x89PNG"))
            two, one = row["grades"]
            for crop in (two["numericCropBase64"], two["writtenCropBase64"], one["numericCropBase64"]):
                self.assertTrue(base64.b64decode(crop).startswith(b"\x89PNG"))
            self.assertIsNone(one["writtenCropBase64"])

    def test_header_ocr_uses_the_name_model_only_in_the_v2_flow(self) -> None:
        name = ThptNameReader()
        weights_model(name=name).analyze_layout(self.image)
        self.assertGreater(name.header_reads, 0)

    def test_the_prepared_page_reads_each_cell_once_per_channel(self) -> None:
        crnn, vietocr, name = StubCrnn(), StubVietOcr(), ThptNameReader()
        counts = {"numeric": 0, "written": 0}
        original_numeric, original_written = crnn.read_cells, vietocr.read_cells

        def numeric(images):
            counts["numeric"] += len(images)
            return original_numeric(images)

        def written(images):
            counts["written"] += len(images)
            return original_written(images)

        crnn.read_cells, vietocr.read_cells = numeric, written
        self.run_model(weights_model(crnn, vietocr, name))
        # 6 inked rows x 2 numeric columns (TX1, GK) and 6 x 1 written column
        self.assertEqual(counts, {"numeric": 12, "written": 6})


class TemplateMismatchTest(V2TestBase):
    def test_a_photo_of_another_form_is_rejected_with_the_score_and_no_rows(self) -> None:
        layout = layout_of(self.signature, STT_COLUMN, NAME_COLUMN, TX1, GK, CK)
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            response = post_recognize(self.client, other_photo(), layout)
        self.assertEqual(response.status_code, 422)
        detail = response.json()["detail"]
        self.assertEqual(detail["code"], "TEMPLATE_MISMATCH")
        self.assertLess(detail["details"]["score"], 0.8)
        self.assertEqual(detail["details"]["minScore"], 0.8)
        self.assertNotIn("rows", response.json())
        self.assertNotIn("rows", detail)

    def test_the_weights_model_also_refuses_before_reading_any_cell(self) -> None:
        crnn = StubCrnn()
        crnn.read_cells = mock.Mock(side_effect=AssertionError("no cell may be read"))
        layout = layout_of(self.signature, STT_COLUMN, NAME_COLUMN, TX1)
        with self.assertRaises(PipelineError) as caught:
            weights_model(crnn).recognize_v2(other_photo(), parse_layout(json.dumps(layout)), 0.8)
        self.assertEqual(caught.exception.code, "TEMPLATE_MISMATCH")
        self.assertIn("score", caught.exception.details)

    def test_the_threshold_comes_from_the_environment(self) -> None:
        layout = layout_of(self.signature, STT_COLUMN, NAME_COLUMN, TX1, GK, CK)
        # a different photo of the same form never scores exactly 1.0
        other_angle = thpt_photo(scale=0.7)
        with patch.dict(os.environ, {**FAKE_ENV, "RECOGNITION_TEMPLATE_MIN_SCORE": "1"}, clear=True):
            strict = post_recognize(self.client, other_angle, layout)
        self.assertEqual(strict.status_code, 422)
        self.assertEqual(strict.json()["detail"]["code"], "TEMPLATE_MISMATCH")
        self.assertEqual(strict.json()["detail"]["details"]["minScore"], 1.0)
        with patch.dict(os.environ, {**FAKE_ENV, "RECOGNITION_TEMPLATE_MIN_SCORE": "0.5"}, clear=True):
            relaxed = post_recognize(self.client, self.image, layout)
        self.assertEqual(relaxed.status_code, 200)
        with patch.dict(os.environ, {**FAKE_ENV, "RECOGNITION_TEMPLATE_MIN_SCORE": "abc"}, clear=True):
            broken = post_recognize(self.client, self.image, layout)
        self.assertEqual((broken.status_code, broken.json()["detail"]), (503, "MODEL_UNAVAILABLE"))

    def test_a_low_threshold_does_not_let_a_different_form_through_when_columns_are_unmapped(self) -> None:
        layout = layout_of(self.signature, STT_COLUMN, NAME_COLUMN, TX1, GK, CK)
        with patch.dict(os.environ, {**FAKE_ENV, "RECOGNITION_TEMPLATE_MIN_SCORE": "0.1"}, clear=True):
            response = post_recognize(self.client, other_photo(), layout)
        self.assertEqual(response.status_code, 422)
        detail = response.json()["detail"]
        self.assertEqual(detail["code"], "TEMPLATE_MISMATCH")
        self.assertTrue(detail["details"]["unmappedColumns"])

    def test_a_lost_vertical_rule_only_matters_for_columns_that_are_requested(self) -> None:
        # The rule between TX3 and TX4 is missing, so template columns 4 and 5 cannot be cut apart.
        page, _ = make_thpt_page(
            rows=ROWS, filled_rows=FILLED, struck_rows=(STRUCK,), missing_lines=(5,)
        )
        image = encode_png(photograph(page, angle=2.0, perspective=0.02))
        wanted = layout_of(self.signature, STT_COLUMN, NAME_COLUMN, TX1, GK, CK)
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            ok = post_recognize(self.client, image, wanted)
            merged = post_recognize(
                self.client, image, layout_of(self.signature, NAME_COLUMN, {"index": 5, "role": "DIEM", "key": "TX4"})
            )
        self.assertEqual(ok.status_code, 200, ok.text)
        self.assertEqual(ok.json()["templateMatch"]["columnMap"], {"0": 0, "1": 1, "2": 2, "3": 3, "6": 5, "7": 6, "8": 7})
        self.assertEqual(merged.status_code, 422)
        self.assertEqual(merged.json()["detail"]["code"], "TEMPLATE_MISMATCH")
        self.assertEqual(merged.json()["detail"]["details"]["unmappedColumns"], [5])


class InvalidLayoutTest(V2TestBase):
    def valid(self):
        return layout_of(
            self.signature,
            STT_COLUMN,
            NAME_COLUMN,
            {**TX1, "writtenIndex": 3},
            {"index": 3, "role": "DIEM_CHU"},
            GK,
        )

    def broken_layouts(self):
        base = self.valid()

        def with_columns(*columns):
            return {**base, "columns": list(columns)}

        def without(role):
            return with_columns(*[c for c in base["columns"] if c["role"] != role])

        return {
            "not json": "{nope",
            "json array": "[]",
            "no signature": {"columns": base["columns"]},
            "empty signature": {**base, "signature": {}},
            "bad signature version": {**base, "signature": {**self.signature, "version": 2}},
            "non numeric widths": {**base, "signature": {**self.signature, "columnWidths": ["a", 1]}},
            "zero width": {**base, "signature": {**self.signature, "columnWidths": [0.5, 0.0, 0.5]}},
            "no columns": with_columns(),
            "no HO_TEN": without("HO_TEN"),
            "two HO_TEN": with_columns(*base["columns"], {"index": 8, "role": "HO_TEN"}),
            "no DIEM": with_columns(NAME_COLUMN, STT_COLUMN),
            "two STT": with_columns(*base["columns"], {"index": 8, "role": "STT"}),
            "duplicate key": with_columns(NAME_COLUMN, TX1, {**GK, "key": "TX1"}),
            "missing key": with_columns(NAME_COLUMN, {"index": 2, "role": "DIEM"}),
            "malformed key": with_columns(NAME_COLUMN, {**TX1, "key": "tx 1/x"}),
            "key too long": with_columns(NAME_COLUMN, {**TX1, "key": "K" * 33}),
            "key on a non grade column": with_columns({**NAME_COLUMN, "key": "X"}, TX1),
            "duplicate index": with_columns(NAME_COLUMN, TX1, {**GK, "index": 2}),
            "index out of range": with_columns(NAME_COLUMN, {**TX1, "index": 9}),
            "negative index": with_columns(NAME_COLUMN, {**TX1, "index": -1}),
            "float index": with_columns(NAME_COLUMN, {**TX1, "index": 2.0}),
            "bool index": with_columns(NAME_COLUMN, {**TX1, "index": True}),
            "unknown role": with_columns(NAME_COLUMN, TX1, {"index": 8, "role": "GHI_CHU"}),
            "writtenIndex not in layout": with_columns(NAME_COLUMN, {**TX1, "writtenIndex": 3}),
            "writtenIndex points to a DIEM": with_columns(NAME_COLUMN, {**TX1, "writtenIndex": 6}, GK),
            "writtenIndex out of range": with_columns(NAME_COLUMN, {**TX1, "writtenIndex": 99}),
            "writtenIndex shared": with_columns(
                NAME_COLUMN,
                {**TX1, "writtenIndex": 3},
                {**GK, "writtenIndex": 3},
                {"index": 3, "role": "DIEM_CHU"},
            ),
            "writtenIndex not an int": with_columns(NAME_COLUMN, {**TX1, "writtenIndex": "3"}),
        }

    def test_the_valid_layout_is_accepted_by_the_parser(self) -> None:
        layout = parse_layout(json.dumps(self.valid()))
        self.assertEqual([c.key for c in layout.grade_columns], ["TX1", "GK1"])

    def test_every_broken_layout_is_a_422_invalid_layout_before_the_model_is_touched(self) -> None:
        model = mock.Mock()
        for name, layout in self.broken_layouts().items():
            with patch("src.api.main.configured_model", return_value=model):
                response = post_recognize(self.client, self.image, layout)
            self.assertEqual(response.status_code, 422, name)
            detail = response.json()["detail"]
            self.assertEqual(detail["code"], "INVALID_LAYOUT", name)
            self.assertTrue(detail["message"], name)
        model.recognize_v2.assert_not_called()

    def test_the_parser_raises_its_own_error(self) -> None:
        for name, layout in self.broken_layouts().items():
            text = layout if isinstance(layout, str) else json.dumps(layout)
            with self.assertRaises(InvalidLayoutError, msg=name):
                parse_layout(text)

    def test_the_layout_field_is_required_by_the_endpoint(self) -> None:
        response = self.client.post("/v2/recognize", files={"image": ("s.png", self.image, "image/png")})
        self.assertEqual(response.status_code, 422)

    def test_an_oversized_layout_is_rejected(self) -> None:
        huge = json.dumps({**self.valid(), "padding": "x" * 70_000})
        with self.assertRaises(InvalidLayoutError):
            parse_layout(huge)


class V1UnchangedTest(unittest.TestCase):
    def test_v1_never_reads_headers_it_still_passes_no_ocr(self) -> None:
        with mock.patch.object(rows_module, "analyze_page", wraps=rows_module.analyze_page) as spy:
            build().recognize(sheet_photo())
        self.assertEqual(spy.call_count, 1)
        self.assertIsNone(spy.call_args.args[1])

    def test_v2_passes_a_header_ocr(self) -> None:
        name = ThptNameReader()
        with mock.patch.object(grid_module, "dinh_danh_cot", wraps=grid_module.dinh_danh_cot) as spy:
            weights_model(name=name).analyze_layout(thpt_photo())
        self.assertTrue(callable(spy.call_args.args[2]))

    def test_the_v1_route_is_still_registered_with_its_original_form_fields(self) -> None:
        schema = app.openapi()
        self.assertIn("/v1/recognize", schema["paths"])
        body = schema["components"]["schemas"]["Body_recognize_v1_recognize_post"]
        self.assertEqual(set(body["properties"]), {"image", "declaredRows"})

    def test_v1_response_has_no_v2_fields(self) -> None:
        with patch.dict(os.environ, FAKE_ENV, clear=True):
            body = TestClient(app).post(
                "/v1/recognize", files={"image": ("s.png", b"png", "image/png")}
            ).json()
        self.assertEqual(set(body), {"modelVersion", "pageStartStt", "rows"})
        self.assertEqual(body["modelVersion"], "fake-dev-v1")


class PrivacyAndSafetyTest(V2TestBase):
    def test_the_service_accepts_no_class_roster(self) -> None:
        self.assertEqual(
            list(inspect.signature(api_main.recognize_v2).parameters), ["image", "layout"]
        )
        self.assertEqual(
            list(inspect.signature(api_main.analyze_layout).parameters), ["image"]
        )

    def test_names_read_from_the_paper_are_never_logged_or_printed(self) -> None:
        records: list[logging.LogRecord] = []

        class Collect(logging.Handler):
            def emit(self, record: logging.LogRecord) -> None:
                records.append(record)

        handler, root = Collect(level=logging.DEBUG), logging.getLogger()
        previous_level = root.level
        root.addHandler(handler)
        root.setLevel(logging.DEBUG)
        out, err = io.StringIO(), io.StringIO()
        layout = layout_of(self.signature, STT_COLUMN, NAME_COLUMN, GK)
        try:
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                with patch("src.api.main.configured_model", return_value=weights_model()), patch.dict(
                    os.environ, {}, clear=True
                ):
                    response = post_recognize(self.client, self.image, layout)
        finally:
            root.removeHandler(handler)
            root.setLevel(previous_level)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["rows"][0]["name"]["raw"], "Họ tên giả")
        self.assertNotIn("Họ tên giả", out.getvalue() + err.getvalue())
        self.assertFalse([r for r in records if r.name.startswith("src")])
        self.assertFalse([r for r in records if "Họ tên giả" in r.getMessage()])

    def test_the_new_modules_do_not_touch_the_network_and_torch_load_is_weights_only(self) -> None:
        root = Path(__file__).resolve().parents[1] / "src"
        for name in ("pipeline/template_match.py", "pipeline/layout.py", "domain/layout.py"):
            text = (root / name).read_text(encoding="utf-8")
            self.assertIsNone(re.search(r"\b(urllib|requests|httpx|socket|http\.client)\b", text), name)
            self.assertIsNone(re.search(r"^\s*(import|from)\s+torch", text, re.M), name)
        for path in root.rglob("*.py"):
            for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
                if "torch.load(" in line:
                    self.assertIn("weights_only=True", line, f"{path.name}:{number}")


class ModelOutputTypesTest(V2TestBase):
    def test_values_are_decimal_strings_on_the_wire(self) -> None:
        with patch("src.api.main.configured_model", return_value=weights_model()):
            body = post_recognize(
                self.client, self.image, layout_of(self.signature, NAME_COLUMN, GK)
            ).json()
        value = body["rows"][0]["grades"][0]["numeric"]["value"]
        self.assertIsInstance(value, str)
        self.assertEqual(Decimal(value), Decimal("8.5"))


if __name__ == "__main__":
    unittest.main()
