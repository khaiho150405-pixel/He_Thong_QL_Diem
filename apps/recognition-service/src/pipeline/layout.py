"""Phân tích bố cục MỘT tờ có kẻ ô bất kỳ và cắt ô theo mẫu (contract v2, ADR-0016 mục 2).

Khác ``rows.analyze_page`` (v1: tự chọn MỘT cột điểm chính), mô-đun này không chọn cột điểm nào:

* ``phan_tich_bo_cuc``: nắn trang, dò lưới, đọc tiêu đề cột (``ocr`` tùy chọn), tính chữ ký và gợi ý vai trò từng cột.
  Dùng cho ``/v2/layout/analyze`` (tạo mẫu) và là bước đầu của ``/v2/recognize``;
* ``chuan_bi_doc``: khớp chữ ký với mẫu (``template_match.khop_mau_chi_tiet``), từ chối bằng ``TEMPLATE_MISMATCH`` khi
  điểm thấp hoặc một cột cần đọc không ánh xạ được (KHÔNG đoán sang cột khác), rồi cắt ô từng dòng theo cột đã ánh xạ.
  Cột cần đọc không ánh xạ được vì lưới mất vạch dọc thì ``khoi_phuc_vach_thieu`` tìm lại vạch bằng bằng chứng mực
  (``khoi_phuc_vach.tim_vach_doc``) trước khi từ chối; không có nét kẻ thật thì vẫn từ chối (P7).

Mô-đun chỉ dùng OpenCV + NumPy; việc đọc chữ do mô hình ở tầng adapter đảm nhiệm. Không đưa họ tên vào log.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, replace
from typing import Any, Callable

import cv2
import numpy as np

from src.domain.layout import Layout, LayoutColumn

from . import grid as grid_module
from .errors import PipelineError
from .khoi_phuc_vach import tim_vach_doc
from .page import PX_MM, doc_anh, nan_trang
from .quality import QualityReport, assess_quality
from .rows import NGUONG_TEN_TRONG, chuan_hoa_hang_y, compact_name_cell, do_dam_muc, la_gach_ngang
from .template_match import KetQuaKhop, khop_mau_chi_tiet, tinh_chu_ky

PREVIEW_MAX_WIDTH = 1400
_MAU_LUOI = (0, 0, 255)  # BGR
_MAU_SO = (0, 90, 0)
_SO_CHU_SO = 4
# Khoảng tìm lại một vạch dọc quanh vị trí kỳ vọng: 30% bề rộng cột nhỏ hơn trong hai cột kề, chặn 10–40 px (P7).
DUNG_SAI_VACH = 0.3
DUNG_SAI_VACH_TOI_THIEU_PX = 10.0
DUNG_SAI_VACH_TOI_DA_PX = 40.0

# Vai trò từ khóa tiêu đề (``grid.TU_KHOA``) → vai trò gợi ý của mẫu; cột còn lại là BO_QUA. Cột không đọc được tiêu đề
# hoặc tiêu đề không khớp từ khóa nào thì KHÔNG gợi ý (None) — người khai báo mẫu tự chọn.
_VAI_TRO_GOI_Y = {
    "stt": "STT",
    "ho_ten": "HO_TEN",
    "diem_so": "DIEM",
    "diem_qua_trinh": "DIEM",
    "diem_chu": "DIEM_CHU",
    "ma_sv": "BO_QUA",
    "ma_hs": "BO_QUA",
    "ngay_sinh": "BO_QUA",
    "lop": "BO_QUA",
    "ky_ten": "BO_QUA",
    "ghi_chu": "BO_QUA",
}
# Nhóm hệ số suy từ chữ tiêu đề (đã bỏ dấu). GK/CK xét trước vì "ddggk"/"ddgck" cũng chứa "gk"/"ck".
_NHOM_TU_KHOA = (
    ("GK", ("gk", "giuaky")),
    ("CK", ("ck", "cuoiky")),
    ("TX", ("tx", "thuongxuyen", "mieng", "kiemtra", "15phut")),
)
# Tiêu đề chỉ gồm ký hiệu nhóm hệ số (TX1, GK, ĐĐGck...) nhưng ``grid.khop_tu_khoa`` không nhận ra: vẫn là cột điểm.
_TIEU_DE_NHOM = re.compile(r"(?:ddg)?(?:tx|gk|ck)\d{0,2}")


@dataclass(frozen=True, slots=True)
class CotBoCuc:
    index: int
    x0: float  # tỉ lệ 0–1 theo bề rộng bảng
    x1: float
    width_mm: float
    header_text: str
    suggested_role: str | None
    suggested_group: str | None
    suggested_order: int | None
    # Biên cột trên trang đã nắn (px) để cắt ô.
    px0: float
    px1: float


@dataclass(frozen=True, slots=True)
class BoCuc:
    page: Any
    grid: dict[str, Any]
    dinh_danh: dict[str, Any]
    quality: QualityReport
    signature: dict[str, Any]
    columns: tuple[CotBoCuc, ...]


def _nhom_he_so(text: str) -> str | None:
    t = grid_module.bo_dau(text)
    for nhom, tu_khoa in _NHOM_TU_KHOA:
        if any(k in t for k in tu_khoa):
            return nhom
    return None


def goi_y_cot(dinh_danh: dict[str, Any]) -> list[tuple[str | None, str | None, int | None]]:
    """``(vai trò, nhóm hệ số, thứ tự trong nhóm)`` gợi ý cho từng cột dữ liệu, theo thứ tự trái → phải."""
    out: list[tuple[str | None, str | None, int | None]] = []
    dem: dict[str, int] = {}
    for cot in dinh_danh["cot"]:
        text = cot.get("nhan", "")
        role = _VAI_TRO_GOI_Y.get(cot.get("vai_tro") or "")
        if role is None and _TIEU_DE_NHOM.fullmatch(grid_module.bo_dau(text)):
            role = "DIEM"
        group = order = None
        if role == "DIEM":
            group = _nhom_he_so(text)
            if group is None and cot.get("vai_tro") == "diem_qua_trinh":
                group = "TX"
            if group is not None:
                dem[group] = dem.get(group, 0) + 1
                order = dem[group]
        out.append((role, group, order))
    return out


def phan_tich_bo_cuc(
    image_bytes: bytes, ocr: Callable[[Any], str] | None = None
) -> BoCuc:
    """Ảnh PNG/JPEG → trang nắn phẳng, lưới, cột (kèm tiêu đề/vai trò gợi ý) và chữ ký lưới.

    Ném ``PipelineError``: ``IMAGE_UNREADABLE``, ``IMAGE_QUALITY_LOW``, ``GRID_NOT_FOUND``. Không kiểm "có phải bảng
    điểm" và không chọn cột điểm (mẫu do người khai báo quyết định).
    """
    original = doc_anh(image_bytes)
    kq_nan = nan_trang(original)
    page = kq_nan["page"]
    luoi = grid_module.trich_luoi(page)
    if luoi is not None:
        luoi = chuan_hoa_hang_y(luoi)
    report = assess_quality(original, page, kq_nan, luoi["bang"] if luoi else None)
    if report.blocking:
        raise PipelineError("IMAGE_QUALITY_LOW", "; ".join(report.blocking))
    if luoi is None:
        raise PipelineError(
            "GRID_NOT_FOUND",
            "Không tìm thấy bảng kẻ ô trong ảnh — chụp thẳng, đủ sáng và thấy trọn bảng.",
        )
    dinh_danh = grid_module.dinh_danh_cot(page, luoi, ocr)
    signature = tinh_chu_ky(page, luoi, dinh_danh)
    x0, width = luoi["bang"][0], luoi["rong_bang"]
    columns = tuple(
        CotBoCuc(
            index=i,
            x0=round((cot["x0"] - x0) / width, _SO_CHU_SO),
            x1=round((cot["x1"] - x0) / width, _SO_CHU_SO),
            width_mm=cot["rong_mm"],
            header_text=cot.get("nhan", ""),
            suggested_role=role,
            suggested_group=group,
            suggested_order=order,
            px0=cot["x0"],
            px1=cot["x1"],
        )
        for i, (cot, (role, group, order)) in enumerate(zip(dinh_danh["cot"], goi_y_cot(dinh_danh)))
    )
    return BoCuc(page, dict(luoi), dinh_danh, report, signature, columns)


def ve_xem_truoc(bo_cuc: BoCuc, rong_toi_da: int = PREVIEW_MAX_WIDTH) -> bytes:
    """PNG của trang đã nắn với lưới và số thứ tự cột (khớp ``index`` của ``columns``), rộng tối đa ``rong_toi_da`` px."""
    canvas = bo_cuc.page.copy()
    luoi = bo_cuc.grid
    x_trai, y_tren, x_phai, y_duoi = (int(round(v)) for v in luoi["bang"])
    for y in luoi["hang_y"]:
        cv2.line(canvas, (x_trai, int(round(y))), (x_phai, int(round(y))), _MAU_LUOI, 2)
    for x in bo_cuc.dinh_danh["cot_du_lieu"]:
        cv2.line(canvas, (int(round(x)), y_tren), (int(round(x)), y_duoi), _MAU_LUOI, 2)
    for cot in bo_cuc.columns:
        label = str(cot.index)
        (w, h), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 1.1, 3)
        cx = int(round((cot.px0 + cot.px1) / 2))
        top = max(0, y_tren - h - baseline - 10)
        cv2.rectangle(canvas, (cx - w // 2 - 6, top), (cx + w // 2 + 6, top + h + baseline + 8), (255, 255, 255), -1)
        cv2.putText(canvas, label, (cx - w // 2, top + h + 3), cv2.FONT_HERSHEY_SIMPLEX, 1.1, _MAU_SO, 3, cv2.LINE_AA)
    height, width = canvas.shape[:2]
    if width > rong_toi_da:
        scale = rong_toi_da / width
        canvas = cv2.resize(canvas, (rong_toi_da, max(1, int(round(height * scale)))), interpolation=cv2.INTER_AREA)
    ok, buffer = cv2.imencode(".png", canvas)
    if not ok:
        raise PipelineError("IMAGE_UNREADABLE", "Không mã hóa được ảnh xem trước.")
    return buffer.tobytes()


@dataclass(frozen=True, slots=True)
class OGiaTri:
    """Ô điểm của một cột ``DIEM`` trong một dòng. ``written_cell`` None khi cột chỉ có kênh số."""

    key: str
    numeric_cell: Any
    numeric_ink: float
    has_written_column: bool
    written_cell: Any
    written_ink: float


@dataclass(frozen=True, slots=True)
class DongDoc:
    """Một dòng dữ liệu theo vị trí từ trên xuống (``row_index`` từ 1) với ô đã cắt theo mẫu."""

    row_index: int
    struck: bool
    stt_cell: Any
    name_cell: Any
    has_name_ink: bool
    grades: tuple[OGiaTri, ...]


@dataclass(frozen=True, slots=True)
class TrangDoc:
    bo_cuc: BoCuc
    score: float
    column_map: dict[int, int]
    rows: tuple[DongDoc, ...]
    has_stt: bool


def cot_can_doc(layout: Layout) -> list[int]:
    """Chỉ số cột mẫu phải ánh xạ được: STT, HO_TEN, mọi DIEM và các DIEM_CHU được cột DIEM trỏ tới."""
    needed = [c.index for c in layout.columns if c.role in ("STT", "HO_TEN", "DIEM")]
    needed += [c.written_index for c in layout.grade_columns if c.written_index is not None]
    return sorted(set(needed))


def _cat(page: Any, luoi: dict[str, Any], hang: int, cot: Any, le: int) -> Any:
    return grid_module.cat_o(page, luoi, hang, cot.px0, cot.px1, le=le)


def cat_dong_theo_mau(bo_cuc: BoCuc, layout: Layout, column_map: dict[int, int]) -> tuple[DongDoc, ...]:
    """Cắt ô từng dòng dữ liệu theo cột đã ánh xạ; đo mực và nhận biết dòng gạch bỏ (như ``rows.extract_rows``)."""
    page, luoi = bo_cuc.page, bo_cuc.grid
    stt_column = next(iter(layout.by_role("STT")), None)
    name_column = layout.by_role("HO_TEN")[0]
    stt = bo_cuc.columns[column_map[stt_column.index]] if stt_column else None
    name = bo_cuc.columns[column_map[name_column.index]]
    grade_columns: list[tuple[LayoutColumn, Any, Any]] = [
        (
            c,
            bo_cuc.columns[column_map[c.index]],
            bo_cuc.columns[column_map[c.written_index]] if c.written_index is not None else None,
        )
        for c in layout.grade_columns
    ]
    rows: list[DongDoc] = []
    first = bo_cuc.dinh_danh["hang_du_lieu_dau"]
    for position, hang in enumerate(range(first, luoi["so_hang"]), start=1):
        grades: list[OGiaTri] = []
        for column, numeric, written in grade_columns:
            numeric_cell = _cat(page, luoi, hang, numeric, 0)
            written_cell = _cat(page, luoi, hang, written, 0) if written is not None else None
            grades.append(
                OGiaTri(
                    key=column.key or "",
                    numeric_cell=numeric_cell,
                    numeric_ink=do_dam_muc(numeric_cell),
                    has_written_column=written is not None,
                    written_cell=written_cell,
                    written_ink=do_dam_muc(written_cell) if written_cell is not None else 0.0,
                )
            )
        if all(g.numeric_cell is None for g in grades):
            continue
        name_cell = _cat(page, luoi, hang, name, 2)
        stt_cell = _cat(page, luoi, hang, stt, 2) if stt else None
        # Gạch bỏ cắt qua ô họ tên VÀ ít nhất một ô điểm/ô chữ: nét ngang ngắn của chữ số (thanh ngang số 7) không làm
        # mất một dòng có điểm (cùng nguyên tắc với v1).
        struck = la_gach_ngang(name_cell) and any(
            la_gach_ngang(g.numeric_cell) or la_gach_ngang(g.written_cell) for g in grades
        )
        rows.append(
            DongDoc(
                row_index=position,
                struck=bool(struck),
                stt_cell=stt_cell,
                name_cell=name_cell if struck else compact_name_cell(name_cell),
                has_name_ink=do_dam_muc(name_cell) >= NGUONG_TEN_TRONG,
                grades=tuple(grades),
            )
        )
    return tuple(rows)


def _khoang_tim_vach(rong_cot: float, ti_le_nho: float) -> float:
    """Sai số cho phép (px) quanh vị trí kỳ vọng của một vạch: một phần ba cột nhỏ hơn trong hai cột kề, 10–40 px."""
    return float(min(max(DUNG_SAI_VACH * rong_cot * ti_le_nho, DUNG_SAI_VACH_TOI_THIEU_PX), DUNG_SAI_VACH_TOI_DA_PX))


def _bo_cuc_sau_khoi_phuc(bo_cuc: BoCuc, bounds: list[float]) -> BoCuc:
    """``BoCuc`` với các ranh giới cột mới (đã gồm vạch tìm lại); cột nguyên vẹn giữ tiêu đề, cột mới/được tách để trống."""
    old = {(round(c.px0, 1), round(c.px1, 1)): c for c in bo_cuc.columns}
    left, right = bounds[0], bounds[-1]
    width = max(right - left, 1.0)
    columns, texts, cells = [], [], []
    for i, (x0, x1) in enumerate(zip(bounds[:-1], bounds[1:])):
        kept = old.get((round(x0, 1), round(x1, 1)))
        text = kept.header_text if kept else ""
        columns.append(
            CotBoCuc(
                index=i,
                x0=round((x0 - left) / width, _SO_CHU_SO),
                x1=round((x1 - left) / width, _SO_CHU_SO),
                width_mm=round((x1 - x0) / PX_MM, 1),
                header_text=text,
                suggested_role=kept.suggested_role if kept else None,
                suggested_group=kept.suggested_group if kept else None,
                suggested_order=kept.suggested_order if kept else None,
                px0=float(x0),
                px1=float(x1),
            )
        )
        texts.append(grid_module.bo_dau(text))
        cells.append(
            dict(x0=float(x0), x1=float(x1), vai_tro=None, nhan=text, diem=0.0, tu_o_gop=False, rong_mm=round((x1 - x0) / PX_MM, 1))
        )
    signature = {
        **bo_cuc.signature,
        "columnWidths": [round((x1 - x0) / width, _SO_CHU_SO) for x0, x1 in zip(bounds[:-1], bounds[1:])],
        "headerTexts": texts,
        "tableWidthMm": round(width / PX_MM, _SO_CHU_SO),
    }
    dinh_danh = {**bo_cuc.dinh_danh, "cot_du_lieu": [float(x) for x in bounds], "cot": cells}
    return replace(bo_cuc, dinh_danh=dinh_danh, signature=signature, columns=tuple(columns))


def khoi_phuc_vach_thieu(
    bo_cuc: BoCuc, ket_qua: KetQuaKhop, layout: Layout, min_score: float
) -> tuple[BoCuc, KetQuaKhop] | None:
    """Tìm lại các vạch dọc mà lưới bỏ sót để ánh xạ được MỌI cột cần đọc, hoặc ``None`` (khi đó tầng trên từ chối).

    Hai tình huống, đều chỉ nhận khi ``khoi_phuc_vach.tim_vach_doc`` thấy nét kẻ thật tại vị trí mẫu kỳ vọng:
    * một cột ảnh bằng hai cột mẫu kề nhau (mất một vạch giữa) → tách tại vạch tìm được;
    * lưới chỉ phủ một đoạn của mẫu (mất vạch mép) → thêm các cột ngoài mép, từng vạch một từ mép lưới ra ngoài; mỗi vạch
      mới dựa trên vạch tìm được trước đó chứ không nội suy.
    Cột cần đọc không thuộc hai tình huống (bị tách bởi vạch giả, mẫu khác...) hoặc thiếu bằng chứng → ``None``. Kết quả
    được khớp lại với mẫu: điểm phải đạt ``min_score`` và mọi cột cần đọc phải ánh xạ được.
    """
    needed = cot_can_doc(layout)
    missing = [i for i in needed if i not in ket_qua.column_map]
    if not missing or not bo_cuc.columns:
        return None
    total = float(sum(layout.signature["columnWidths"]))
    widths = [float(w) / total for w in layout.signature["columnWidths"]]
    count = len(widths)
    bounds = [bo_cuc.columns[0].px0] + [c.px1 for c in bo_cuc.columns]
    added: list[float] = []
    handled: set[int] = set()
    hang_y, hang_dau, page = bo_cuc.grid["hang_y"], bo_cuc.dinh_danh["hang_du_lieu_dau"], bo_cuc.page

    def find(expected: float, span: float, ratio: float) -> float | None:
        return tim_vach_doc(page, hang_y, hang_dau, expected, _khoang_tim_vach(span, ratio), tranh=bounds + added)

    for image_index, first in ket_qua.gop:  # một cột ảnh = hai cột mẫu kề nhau
        pair = (first, first + 1)
        if not any(j in missing for j in pair):
            continue
        x0, x1 = bo_cuc.columns[image_index].px0, bo_cuc.columns[image_index].px1
        share = widths[first] / (widths[first] + widths[first + 1])
        x = find(x0 + share * (x1 - x0), x1 - x0, min(share, 1.0 - share))
        if x is None or not x0 < x < x1:
            return None
        added.append(x)
        handled.update(pair)

    scale = (bounds[-1] - bounds[0]) / max(sum(widths[ket_qua.cat_trai : count - ket_qua.cat_phai]), 1e-9)
    for cut, direction in ((ket_qua.cat_trai, -1), (ket_qua.cat_phai, +1)):
        edge = bounds[0] if direction < 0 else bounds[-1]
        column_ids = (
            list(range(ket_qua.cat_trai - 1, -1, -1)) if direction < 0 else list(range(count - ket_qua.cat_phai, count))
        )
        wanted = [j for j in column_ids if j in missing]  # column_ids đi từ mép lưới ra ngoài
        if not cut or not wanted:
            continue
        for j in column_ids[: column_ids.index(wanted[-1]) + 1]:
            span = scale * widths[j]
            x = find(edge + direction * span, span, 1.0)
            if x is None or (x - edge) * direction < 0.5 * span:
                return None
            added.append(x)
            edge = x
            handled.add(j)
    if not set(missing) <= handled:
        return None
    ordered = sorted(set(bounds) | set(added))
    rebuilt = _bo_cuc_sau_khoi_phuc(bo_cuc, ordered)
    matched = khop_mau_chi_tiet(rebuilt.signature, layout.signature)
    if matched.score < min_score or any(i not in matched.column_map for i in needed):
        return None
    return rebuilt, matched


def chuan_bi_doc(
    image_bytes: bytes,
    layout: Layout,
    ocr: Callable[[Any], str] | None,
    min_score: float,
) -> TrangDoc:
    """Phân tích ảnh, khớp với mẫu của ``layout`` và cắt ô; ``TEMPLATE_MISMATCH`` nếu không khớp (không trả dòng nào).

    Cột cần đọc không ánh xạ được vì lưới mất vạch dọc thì thử tìm lại vạch bằng bằng chứng mực
    (``khoi_phuc_vach_thieu``); không tìm thấy nét kẻ thật thì từ chối như cũ, không đoán cột.
    """
    bo_cuc = phan_tich_bo_cuc(image_bytes, ocr)
    ket_qua = khop_mau_chi_tiet(bo_cuc.signature, layout.signature)
    score, column_map = ket_qua.score, ket_qua.column_map
    unmapped = [i for i in cot_can_doc(layout) if i not in column_map]
    if unmapped and score >= min_score:
        recovered = khoi_phuc_vach_thieu(bo_cuc, ket_qua, layout, min_score)
        if recovered is not None:
            bo_cuc, ket_qua = recovered
            score, column_map = ket_qua.score, ket_qua.column_map
            unmapped = []
    if score < min_score or unmapped:
        raise PipelineError(
            "TEMPLATE_MISMATCH",
            "Ảnh không khớp mẫu đã chọn — kiểm tra đã chọn đúng mẫu và chụp thấy trọn bảng.",
            {
                "score": score,
                "minScore": min_score,
                "unmappedColumns": unmapped,
                "imageColumns": len(bo_cuc.columns),
                "templateColumns": len(layout.signature["columnWidths"]),
            },
        )
    return TrangDoc(
        bo_cuc=bo_cuc,
        score=score,
        column_map=column_map,
        rows=cat_dong_theo_mau(bo_cuc, layout, column_map),
        has_stt=bool(layout.by_role("STT")),
    )


__all__ = [
    "BoCuc",
    "CotBoCuc",
    "DongDoc",
    "OGiaTri",
    "PREVIEW_MAX_WIDTH",
    "TrangDoc",
    "cat_dong_theo_mau",
    "chuan_bi_doc",
    "cot_can_doc",
    "goi_y_cot",
    "khoi_phuc_vach_thieu",
    "phan_tich_bo_cuc",
    "ve_xem_truoc",
]
