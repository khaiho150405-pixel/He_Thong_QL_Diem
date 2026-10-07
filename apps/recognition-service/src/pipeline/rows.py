"""Tách dòng dữ liệu của bảng điểm: ô STT / Họ tên / Đ.số / Điểm chữ, dòng gạch, ô trống.

Nguồn gốc:
- ``label_tool/nhan_dang_ca_to.py``: ``_la_gach_ngang`` (dòng bị gạch bỏ), ``_suy_stt_bat_dau`` (STT của dòng đầu
  trang, bỏ phiếu để chịu lỗi OCR) và tinh thần của ``phan_tich_trang`` (nắn → dò lưới → định danh cột → kiểm định);
- ``label_tool/tien_xu_ly_v3.py``: ``do_dam_muc`` (tỉ lệ mực thật trong ô).

Module này chỉ dùng OpenCV + NumPy. Nó KHÔNG đọc chữ: STT/họ tên/điểm được đọc bởi mô hình ở tầng adapter
(BE-17–BE-19), nên ``suy_stt_bat_dau`` nhận STT đã đọc được làm tham số.

``analyze_page`` gom BE-13 (nắn trang + kiểm định ảnh), BE-14 (dò lưới, định danh cột) và BE-15 (tách dòng).
Dịch vụ KHÔNG nhận danh sách học sinh; việc ghép dòng với học sinh do API đảm nhiệm (ADR-0015).
"""
from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from typing import Any, Callable, Mapping

import cv2
import numpy as np

from . import grid as grid_module
from .errors import PipelineError
from .page import doc_anh, nan_trang
from .quality import QualityReport, assess_quality

# Ô có tỉ lệ mực dưới mức này (đơn vị %) coi là trống.
NGUONG_TRONG = 1.0
# Ô họ tên in sẵn: ngưỡng mực riêng, thấp hơn vì chữ in mảnh.
NGUONG_TEN_TRONG = 0.8
MAX_STT = 500


def do_dam_muc(o, le: int = 4) -> float:
    """Tỉ lệ % điểm ảnh là nét mực thật trong ô (giống ``tien_xu_ly_v3.do_dam_muc``)."""
    if o is None or o.size == 0:
        return 0.0
    g = cv2.cvtColor(o, cv2.COLOR_BGR2GRAY) if o.ndim == 3 else o
    h, w = g.shape[:2]
    if h > 2 * le and w > 2 * le:
        g = g[le : h - le, le : w - le]
    g = cv2.medianBlur(g, 3)
    nen = float(np.median(g))
    m = (g.astype(np.int16) < nen - 45).astype(np.uint8)
    n, _, st, _ = cv2.connectedComponentsWithStats(m, 8)
    muc = sum(
        int(st[i, cv2.CC_STAT_AREA]) for i in range(1, n) if st[i, cv2.CC_STAT_AREA] >= 8
    )
    return round(muc / m.size * 100, 2)


def la_gach_ngang(o) -> bool:
    """Ô có nét gạch ngang dài (dòng vắng/không thi bị gạch bỏ)? (``_la_gach_ngang`` gốc)."""
    if o is None or o.size == 0:
        return False
    g = cv2.cvtColor(o, cv2.COLOR_BGR2GRAY) if o.ndim == 3 else o
    h, w = g.shape[:2]
    if h < 8 or w < 20:
        return False
    t = cv2.adaptiveThreshold(
        g, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 31, 10
    )
    giua = t[int(0.25 * h) : int(0.8 * h), :]
    if giua.size == 0:
        return False
    k = cv2.getStructuringElement(cv2.MORPH_RECT, (max(12, int(0.5 * w)), 1))
    return bool(cv2.morphologyEx(giua, cv2.MORPH_OPEN, k).any())


def suy_stt_bat_dau(
    stt_theo_dong: Mapping[int, int], so_dong_du_lieu: int
) -> int | None:
    """STT của dòng dữ liệu đầu tiên trên trang, suy từ STT đọc được bằng bỏ phiếu.

    ``stt_theo_dong``: ``{rowIndex (từ 1): STT đọc được}`` (có thể sót vài dòng hoặc đọc sai). Mỗi dòng bỏ một phiếu
    cho ``STT − (rowIndex − 1)``; chỉ nhận khi phiếu thắng đủ nhiều (như ``_suy_stt_bat_dau`` của bản gốc), nên
    một vài giá trị đọc sai không làm lệch cả trang. Trả ``None`` khi không đủ chắc chắn.
    """
    lech = [v - (k - 1) for k, v in stt_theo_dong.items() if 0 < v < MAX_STT]
    if not lech:
        return None
    gia_tri, so_lan = Counter(lech).most_common(1)[0]
    can = 2 if max(1, so_dong_du_lieu) <= 5 else 3  # trang sau chỉ có vài dòng
    if so_lan < can or so_lan < 0.35 * len(lech) or gia_tri < 1:
        return None
    return int(gia_tri)


@dataclass(frozen=True, slots=True)
class PageRow:
    """Một dòng dữ liệu của bảng, theo vị trí từ trên xuống (``row_index`` bắt đầu từ 1)."""

    row_index: int
    stt_cell: Any
    name_cell: Any
    score_cell: Any
    written_cell: Any
    struck: bool
    has_grade_ink: bool
    has_name_ink: bool
    score_ink: float
    written_ink: float
    name_ink: float


@dataclass(frozen=True, slots=True)
class PageAnalysis:
    page: Any
    grid: dict[str, Any]
    columns: dict[str, Any]
    selection: dict[str, Any]
    rows: tuple[PageRow, ...]
    quality: QualityReport
    # Cột điểm được suy đoán bằng hình học vì không đọc được tiêu đề: tầng trên phải hạ độ tin cậy.
    guessed_columns: bool

    def page_start_stt(self, stt_theo_dong: Mapping[int, int]) -> int | None:
        return suy_stt_bat_dau(stt_theo_dong, len(self.rows))


def _buoc_dong(hang_y: list[float]) -> float:
    """Bước dòng điển hình: khoảng cách được nhiều dòng "ủng hộ" nhất (sai lệch ≤ 12%), hòa thì lấy bước lớn hơn.

    Không dùng trung vị vì bảng ngắn (trang cuối chỉ 3 dòng) có ít khoảng cách và vài vạch giả từ nét chữ làm
    trung vị rơi vào nửa bước dòng; dòng thật luôn là khoảng cách lớn hơn khi hòa số phiếu.
    """
    khoang = [float(d) for d in np.diff(hang_y) if d > 0]
    if not khoang:
        return 0.0
    best = max(
        khoang,
        key=lambda c: (sum(abs(d - c) <= 0.12 * c for d in khoang), c),
    )
    return best


def chuan_hoa_hang_y(luoi: Mapping[str, Any]) -> dict[str, Any]:
    """Gỡ vạch ngang giả khỏi lưới: nét gạch bỏ dòng và nét chữ/đường gạch chân kéo dài.

    Nét gạch đi suốt bề ngang bảng, còn nét viết tay/chữ in dài có thể có độ phủ cộng dồn đủ lớn, nên ``trich_luoi``
    coi chúng như đường kẻ và cắt một dòng thật thành hai dòng thấp. Một vạch bị gỡ khi hai dòng kề nó đều thấp hơn
    75% bước dòng (``_buoc_dong``) và tổng chiều cao nằm trong 85%–115% bước dòng, tức là hai nửa ghép lại đúng
    một dòng. Mỗi vòng chỉ gỡ ứng viên có tổng sát bước dòng nhất (tiêu đề cao hơn dòng nên vạch dưới tiêu đề không
    bao giờ bị gỡ nhầm); mép trên/dưới bảng không bao giờ bị gỡ.
    """
    hang_y = [float(y) for y in luoi["hang_y"]]
    if len(hang_y) < 4:
        return dict(luoi)
    pitch = _buoc_dong(hang_y)
    if pitch <= 0:
        return dict(luoi)
    ra = list(hang_y)
    while len(ra) >= 4:
        tot = None
        for i in range(1, len(ra) - 1):
            truoc, sau = ra[i] - ra[i - 1], ra[i + 1] - ra[i]
            tong = truoc + sau
            if truoc < 0.75 * pitch and sau < 0.75 * pitch and 0.85 * pitch <= tong <= 1.15 * pitch:
                lech = abs(tong - pitch)
                if tot is None or lech < tot[0]:
                    tot = (lech, i)
        if tot is None:
            break
        del ra[tot[1]]
    ket = dict(luoi)
    ket["hang_y"] = ra
    ket["so_hang"] = len(ra) - 1
    ket["buoc_dong"] = float(np.median(np.diff(ra))) if len(ra) > 2 else 0.0
    return ket


def _column(dinh_danh: Mapping[str, Any], role: str):
    return next((c for c in dinh_danh["cot"] if c["vai_tro"] == role), None)


def _name_column(
    dinh_danh: Mapping[str, Any], score: Mapping[str, Any], stt: Mapping[str, Any] | None
):
    """Cột họ tên: theo tiêu đề; nếu không có thì cột rộng nhất nằm bên trái cột điểm (không phải STT)."""
    found = _column(dinh_danh, "ho_ten")
    if found:
        return found
    left = [
        c
        for c in dinh_danh["cot"]
        if c["x1"] <= score["x0"] + 1 and not (stt and c["x0"] == stt["x0"])
    ]
    return max(left, key=lambda c: c["x1"] - c["x0"], default=None)


def extract_rows(
    page,
    luoi: Mapping[str, Any],
    dinh_danh: Mapping[str, Any],
    chon: Mapping[str, Any],
) -> tuple[PageRow, ...]:
    """Cắt các ô của từng dòng dữ liệu và đo mực/gạch."""
    score = chon["cot_diem_chinh"]
    written = chon["cot_diem_chu"]
    stt = _column(dinh_danh, "stt") or (
        {"x0": dinh_danh["cot_du_lieu"][0], "x1": dinh_danh["cot_du_lieu"][1]}
        if len(dinh_danh["cot_du_lieu"]) > 1
        else None
    )
    name = _name_column(dinh_danh, score, stt)
    rows: list[PageRow] = []
    first = dinh_danh["hang_du_lieu_dau"]
    for position, i in enumerate(range(first, luoi["so_hang"]), start=1):
        score_cell = grid_module.cat_o(page, luoi, i, score["x0"], score["x1"], le=0)
        if score_cell is None:
            continue
        written_cell = (
            grid_module.cat_o(page, luoi, i, written["x0"], written["x1"], le=0)
            if written
            else None
        )
        name_cell = (
            grid_module.cat_o(page, luoi, i, name["x0"], name["x1"], le=2) if name else None
        )
        stt_cell = (
            grid_module.cat_o(page, luoi, i, stt["x0"], stt["x1"], le=2) if stt else None
        )
        score_ink = do_dam_muc(score_cell)
        written_ink = do_dam_muc(written_cell) if written_cell is not None else 0.0
        name_ink = do_dam_muc(name_cell) if name_cell is not None else 0.0
        # Gạch bỏ phải cắt qua ô điểm VÀ ô họ tên/điểm chữ: nét ngang ngắn của chữ viết tay (thanh ngang của số 7,
        # 5...) không được làm mất một dòng có điểm.
        struck = la_gach_ngang(score_cell) and (
            la_gach_ngang(name_cell) or la_gach_ngang(written_cell)
        )
        has_grade_ink = (
            not struck and max(score_ink, written_ink) >= NGUONG_TRONG
        )
        has_name_ink = name_ink >= NGUONG_TEN_TRONG
        rows.append(
            PageRow(
                row_index=position,
                stt_cell=stt_cell,
                name_cell=name_cell,
                score_cell=score_cell,
                written_cell=written_cell,
                struck=bool(struck),
                has_grade_ink=bool(has_grade_ink),
                has_name_ink=bool(has_name_ink),
                score_ink=score_ink,
                written_ink=written_ink,
                name_ink=name_ink,
            )
        )
    return tuple(rows)


def analyze_flat_page(
    page,
    kq_nan: Mapping[str, Any],
    original,
    ocr: Callable[[Any], str] | None = None,
) -> PageAnalysis:
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
    grid_module.bao_dam_la_bang_diem(luoi, dinh_danh)
    chon = grid_module.chon_cot_diem_bat_buoc(luoi, dinh_danh)
    rows = extract_rows(page, luoi, dinh_danh, chon)
    return PageAnalysis(
        page=page,
        grid=dict(luoi),
        columns=dinh_danh,
        selection=chon,
        rows=rows,
        quality=report,
        guessed_columns=bool(chon.get("suy_doan_hinh_hoc")),
    )


def analyze_page(
    image_bytes: bytes, ocr: Callable[[Any], str] | None = None
) -> PageAnalysis:
    """Ảnh PNG/JPEG → trang nắn phẳng, lưới, cột đã định danh và các dòng dữ liệu.

    ``ocr``: hàm chữ in tùy chọn (ảnh xám → chuỗi) để đọc tiêu đề cột; ``None`` thì dùng đường lui hình học.
    Ném ``PipelineError`` với mã ổn định: ``IMAGE_UNREADABLE``, ``IMAGE_QUALITY_LOW``, ``GRID_NOT_FOUND``,
    ``NOT_A_GRADEBOOK``, ``SCORE_COLUMN_NOT_FOUND``.
    """
    image = doc_anh(image_bytes)
    kq_nan = nan_trang(image)
    return analyze_flat_page(kq_nan["page"], kq_nan, image, ocr)
