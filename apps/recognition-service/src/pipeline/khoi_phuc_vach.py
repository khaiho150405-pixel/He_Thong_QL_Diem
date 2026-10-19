"""Tìm lại MỘT vạch dọc thật của bảng tại vị trí mẫu kỳ vọng (ADR-0016 mục 2, phase P7).

Ảnh điện thoại có khi mất vạch dọc ở bước dò lưới (``grid.trich_luoi``): vạch mờ, đứt từng đoạn ngắn hoặc dính mực. Khi
mẫu cho biết một cột cần đọc nằm ở đâu, ta chỉ tìm vạch trong một khoảng hẹp quanh vị trí kỳ vọng và chỉ nhận khi có
bằng chứng mực thật: một đường thẳng gần đứng mà phần lớn các dòng dữ liệu đều có nét tối liên tục gần hết chiều cao dòng
nằm đúng trên đó. Nét chữ số, chữ in hoặc bóng đổ không đạt (cao chưa hết dòng, lệch nhau giữa các dòng hoặc rộng cả
mảng). Có hai đường thẳng ứng viên tách biệt thì cũng từ chối: không đoán. Không có bằng chứng thì trả ``None`` và tầng
trên từ chối (``TEMPLATE_MISMATCH``); hàm KHÔNG bao giờ vẽ vạch giả hay nội suy vị trí.

Chỉ dùng OpenCV + NumPy, tất định, không đọc chữ.
"""
from __future__ import annotations

from typing import Any, Sequence

import cv2
import numpy as np

# Đo trên gần TRỌN chiều cao từng dòng dữ liệu, chỉ chừa bề dày (kể cả viền mờ) của vạch ngang ở hai đầu: nếu để viền mờ
# lọt vào dải thì bước lấp khe nối nó với chữ số thành một "vạch" liền. Vạch dọc thật phủ ~100% chiều cao dòng; chữ số
# viết tay hoặc chữ in (kể cả "8", STT "10"–"19") chỉ chiếm 55–75% chiều cao dòng nên không đạt PHU_DOC_TOI_THIEU.
LE_DONG = 0.11
LE_DONG_TOI_THIEU_PX = 4
DONG_TOI_THIEU_PX = 6
# Điểm ảnh coi là mực khi tối hơn nền cục bộ của dải (trung vị) ngần này mức xám.
DO_TUONG_PHAN = 30
# Khe dọc nhỏ hơn mức này (px) trong một nét tối được lấp trước khi đo (vạch đứt do mờ, chữ đè).
KHE_LAP_TOI_DA = 11
# Vạch mảnh: các x0 cùng đạt ngưỡng quanh đường tốt nhất không rộng quá ngần này px (loại mảng tối như bóng đổ).
BE_RONG_VACH_TOI_DA = 14
# Một dòng "ủng hộ" tại x khi nét tối phủ ít nhất ngần này chiều cao dải ở x đó.
PHU_DOC_TOI_THIEU = 0.90
LECH_NGANG_TOI_DA = 2
# Đường thẳng x = x0 + độ_dốc·(y − y_giữa): thử các độ dốc trong ±DOC_NGHIENG_TOI_DA (trang đã nắn phẳng nên rất nhỏ).
DOC_NGHIENG_TOI_DA = 0.03
SO_DOC_NGHIENG = 13
# Phần dòng tối thiểu cùng ủng hộ một đường thẳng, và độ trải theo chiều dọc của các dòng đó.
PHAN_DONG_TOI_THIEU = 0.6
SO_DONG_TOI_THIEU = 3
TRAI_DOC_TOI_THIEU = 0.5
# Hai ứng viên cách nhau hơn mức này (px) là hai đường khác nhau → mơ hồ, từ chối.
KHOANG_TACH_UNG_VIEN = 6
# Quanh các vạch đã dò được (đã có trong lưới) bỏ ngần này px: chúng là vạch khác, không phải vạch cần tìm lại.
LOAI_TRU_QUANH_VACH = 6
# Lề trang: sát mép giấy thường là mép bàn/bóng đổ, không phải vạch bảng.
LE_TRANG = 0.015


def _xam(page: Any) -> np.ndarray:
    return cv2.cvtColor(page, cv2.COLOR_BGR2GRAY) if page.ndim == 3 else page


def tim_vach_doc(
    page: Any,
    hang_y: Sequence[float],
    hang_dau: int,
    x_ky_vong: float,
    dung_sai: float,
    tranh: Sequence[float] = (),
) -> float | None:
    """x (px, trên trang đã nắn) của vạch dọc thật gần ``x_ky_vong`` (±``dung_sai``), hoặc ``None`` khi không có bằng chứng.

    ``hang_y``: các đường ngang của bảng; chỉ dùng các dòng dữ liệu từ ``hang_dau``. ``tranh``: x của các vạch đã có trong
    lưới (không tính lại chúng). Trả về x tại giữa vùng dữ liệu.
    """
    gray = _xam(page)
    height, width = gray.shape[:2]
    le = int(LE_TRANG * width)
    xa = max(le, int(np.floor(x_ky_vong - dung_sai)))
    xb = min(width - le, int(np.ceil(x_ky_vong + dung_sai)) + 1)
    if xb - xa < 5:
        return None
    bands = []
    for i in range(max(hang_dau, 0), len(hang_y) - 1):
        y0, y1 = float(hang_y[i]), float(hang_y[i + 1])
        inset = max(LE_DONG_TOI_THIEU_PX, int(round(LE_DONG * (y1 - y0))))
        top, bottom = max(0, int(round(y0)) + inset), min(height, int(round(y1)) - inset)
        if bottom - top >= DONG_TOI_THIEU_PX:
            bands.append((top, bottom))
    if len(bands) < SO_DONG_TOI_THIEU:
        return None
    columns = np.arange(xa, xb)
    excluded = np.zeros(len(columns), bool)
    for x in tranh:
        excluded |= np.abs(columns - x) <= LOAI_TRU_QUANH_VACH
    closing = cv2.getStructuringElement(cv2.MORPH_RECT, (1, KHE_LAP_TOI_DA))
    support = np.zeros((len(bands), len(columns)), bool)  # support[b, k]: dòng b có nét tối phủ gần hết dải tại x = xa + k
    for b, (top, bottom) in enumerate(bands):
        band = gray[top:bottom, xa:xb]
        dark = (band.astype(np.int16) < int(np.median(band)) - DO_TUONG_PHAN).astype(np.uint8)
        # Đệm dòng trống trước khi lấp khe: mặc định OpenCV coi ngoài biên là mực nên phép đóng lan mực ra tận mép dải.
        padded = cv2.copyMakeBorder(dark, KHE_LAP_TOI_DA, KHE_LAP_TOI_DA, 0, 0, cv2.BORDER_CONSTANT, value=0)
        closed = cv2.morphologyEx(padded, cv2.MORPH_CLOSE, closing)[KHE_LAP_TOI_DA:-KHE_LAP_TOI_DA]
        covered = closed.mean(axis=0) >= PHU_DOC_TOI_THIEU
        for shift in range(1, LECH_NGANG_TOI_DA + 1):  # vạch hơi cong sau khi nắn: chịu lệch ±LECH_NGANG_TOI_DA px
            covered = covered | np.roll(covered, shift) | np.roll(covered, -shift)
        covered[:LECH_NGANG_TOI_DA] = covered[-LECH_NGANG_TOI_DA:] = False  # np.roll quấn vòng: bỏ hai đầu
        support[b] = covered & ~excluded
    middle = np.array([(top + bottom) / 2.0 for top, bottom in bands])
    reference = (middle[0] + middle[-1]) / 2.0
    need = max(SO_DONG_TOI_THIEU, int(np.ceil(PHAN_DONG_TOI_THIEU * len(bands))))
    # Đếm số dòng ủng hộ từng đường thẳng (độ dốc, x0): x_b = x0 + độ_dốc·(y_b − y_giữa).
    slopes = np.linspace(-DOC_NGHIENG_TOI_DA, DOC_NGHIENG_TOI_DA, SO_DOC_NGHIENG)
    rows = np.arange(len(bands))[:, None]
    counts = np.zeros((len(slopes), len(columns)), int)
    for s, slope in enumerate(slopes):
        shift = np.round(slope * (middle - reference)).astype(int)[:, None]
        index = np.arange(len(columns))[None, :] + shift
        valid = (index >= 0) & (index < len(columns))
        counts[s] = (support[rows, np.clip(index, 0, len(columns) - 1)] & valid).sum(axis=0)
    good = counts >= need
    if not good.any():
        return None
    # Gom các ứng viên thành nhóm theo x0; hơn một nhóm tách biệt → mơ hồ.
    candidate_x = np.flatnonzero(good.any(axis=0))
    groups = np.split(candidate_x, np.flatnonzero(np.diff(candidate_x) > KHOANG_TACH_UNG_VIEN) + 1)
    if len(groups) != 1:
        return None
    best = counts[:, groups[0]].max()
    cells = np.argwhere(counts[:, groups[0]] == best)
    slope = float(np.mean(slopes[cells[:, 0]]))
    x0 = float(np.mean(groups[0][cells[:, 1]]))
    if int((counts[int(cells[0, 0])] >= need).sum()) > BE_RONG_VACH_TOI_DA:
        return None  # mảng tối rộng (bóng đổ, mép bàn), không phải nét kẻ
    # Các dòng ủng hộ phải trải theo chiều dọc bảng (không dồn vào một góc).
    shift = np.round(slope * (middle - reference)).astype(int)
    supported = [
        middle[b]
        for b in range(len(bands))
        if 0 <= int(round(x0)) + shift[b] < len(columns) and support[b, int(round(x0)) + shift[b]]
    ]
    if len(supported) < need:
        return None
    if max(supported) - min(supported) < TRAI_DOC_TOI_THIEU * (bands[-1][1] - bands[0][0]):
        return None
    return float(xa + x0)
