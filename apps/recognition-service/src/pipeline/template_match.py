"""Chữ ký lưới của một tờ bảng điểm và khớp ảnh với mẫu (ADR-0016 mục 1–2).

``tinh_chu_ky`` rút từ một trang đã nắn một chữ ký nhỏ, tất định: tỉ lệ bề rộng từng cột dữ liệu, chữ tiêu đề đã bỏ
dấu, số hàng tiêu đề, bước dòng và bề rộng bảng. ``khop_mau`` căn dãy bề rộng cột của ảnh với dãy của mẫu bằng quy hoạch
động (ảnh chụp có thể mất một vạch dọc hoặc thừa một vạch giả) rồi cho điểm 0–1; dùng điểm đó để chặn ảnh của MỘT TỜ
KHÁC trước khi đọc điểm. Mô-đun chỉ dùng thư viện chuẩn, không đọc ảnh nên chạy được mà không cần OpenCV/torch.

Nguyên tắc an toàn: cột nào bị gộp hoặc tách trong phép căn, hoặc nằm ngoài lưới dò được, thì KHÔNG có trong
``column_map`` (không thể cắt ô đúng), nên tầng trên phải từ chối thay vì đoán sang cột khác. Riêng cột bị gộp/nằm ngoài
mép, ``khop_mau_chi_tiet`` cho biết vị trí để ``layout.khoi_phuc_vach_thieu`` thử tìm lại vạch kẻ THẬT trong ảnh (P7);
không có nét kẻ thì vẫn từ chối.
"""
from __future__ import annotations

import difflib
import math
from collections.abc import Mapping, Sequence
from typing import Any, NamedTuple

from .grid import bo_dau
from .page import PX_MM

SIGNATURE_VERSION = 1

# Ngưỡng điểm khớp tối thiểu để nhận ảnh (D-04 trong decisions.md): ảnh cùng mẫu chụp nghiêng/phối cảnh nhẹ đạt ≥ 0,9,
# mẫu khác có số cột/bề rộng khác xa dưới 0,8. Đổi bằng biến môi trường, không sửa mã.
ENV_MIN_SCORE = "RECOGNITION_TEMPLATE_MIN_SCORE"
DEFAULT_MIN_SCORE = 0.80

# Điểm bề rộng = 1 − (tổng sai lệch tỉ lệ bề rộng + các khoản phạt): tỉ lệ bề rộng đã chuẩn hóa về tổng 1 nên tổng
# sai lệch (chuẩn L1) nằm trong 0–2; hai tờ cùng mẫu lệch vài phần nghìn mỗi cột, hai tờ khác mẫu lệch hàng chục %.
# Phạt khi MỘT cột ảnh bằng hai cột mẫu (mất một vạch dọc: chữ viết đè, vạch mờ). Đủ nhỏ để một vạch mất vẫn khớp.
PHAT_GOP_COT = 0.04
# Phạt khi HAI cột ảnh bằng một cột mẫu (có vạch giả: nét gạch hoặc nếp gấp bị nhận như vạch kẻ).
PHAT_TACH_COT = 0.04
# Tỉ trọng của hai thành phần khi có đủ chữ tiêu đề để so (chữ tiêu đề do OCR đọc nên nhiễu: chỉ là phần phụ).
TRONG_SO_BE_RONG = 0.75
TRONG_SO_TIEU_DE = 0.25
# Số cặp cột 1–1 cùng có chữ tiêu đề tối thiểu để chữ tiêu đề được tính vào điểm (ít hơn thì chỉ xét bề rộng).
SO_CAP_TIEU_DE_TOI_THIEU = 2
SO_CHU_SO = 4

# Cắt mép (P7): ảnh điện thoại có thể mất vạch ngoài cùng nên lưới dò được chỉ phủ một đoạn liên tiếp của mẫu (các cột đầu
# hoặc cuối của mẫu nằm ngoài lưới). DEV: hai trang cắt cột cuối (điểm 0,80/0,83 theo phép căn cũ), một trang cắt cột STT,
# một trang cắt hai cột trái. Mỗi cột bỏ phạt 0,05 (đắt hơn một vạch mất giữa bảng) để ảnh của mẫu khác không "tìm" được
# đoạn nào đó khớp; phép căn cắt mép phải rẻ hơn phép căn toàn bộ ít nhất 0,03 và hơn cách cắt khác ít nhất 0,02.
# Ngoài ra các cột nhìn thấy phải khớp đoạn mẫu gần như chính xác (sai lệch bề rộng ≤ 0,03, chưa tính phạt): bốn trang
# DEV cắt mép có sai lệch 0,0009–0,0046 còn cách cắt tốt thứ hai ≥ 0,13; tờ mẫu khác (tổng hợp) ≥ 0,12.
SAI_LECH_CAT_BIEN_TOI_DA = 0.03
PHAT_MAT_COT_BIEN = 0.05
SO_COT_BIEN_TOI_DA = 3
PHU_MAU_TOI_THIEU = 0.6
CAI_THIEN_CAT_BIEN_TOI_THIEU = 0.03
BIEN_PHAN_BIET_CAT_BIEN = 0.02


def nguong_khop_mau(env: Mapping[str, str]) -> float:
    """Ngưỡng ``RECOGNITION_TEMPLATE_MIN_SCORE`` (mặc định 0,80); sai định dạng hoặc ngoài 0–1 thì ``ValueError``."""
    raw = env.get(ENV_MIN_SCORE)
    if raw is None or not raw.strip():
        return DEFAULT_MIN_SCORE
    try:
        value = float(raw)
    except ValueError as error:
        raise ValueError(f"{ENV_MIN_SCORE} must be a number") from error
    if not math.isfinite(value) or not 0.0 <= value <= 1.0:
        raise ValueError(f"{ENV_MIN_SCORE} must be between 0 and 1")
    return value


def tinh_chu_ky(page: Any, luoi: Mapping[str, Any], dinh_danh: Mapping[str, Any]) -> dict[str, Any]:
    """Chữ ký lưới của trang đã nắn (ADR-0016 mục 1), làm tròn 4 chữ số.

    ``columnWidths`` là tỉ lệ bề rộng từng cột dữ liệu trên bề rộng bảng, ``headerTexts`` là chữ tiêu đề đã bỏ dấu
    ("" khi không đọc được), ``headerRows`` là số hàng phía trên dòng dữ liệu đầu tiên. ``page`` hiện chưa dùng: chữ ký
    chỉ phụ thuộc lưới nên cùng một tờ chụp ở hai điều kiện sáng khác nhau cho cùng một chữ ký.
    """
    del page
    width = float(luoi["rong_bang"])
    if width <= 0:
        raise ValueError("Grid has no width")
    columns = dinh_danh["cot"]
    return {
        "version": SIGNATURE_VERSION,
        "columnWidths": [round((c["x1"] - c["x0"]) / width, SO_CHU_SO) for c in columns],
        "headerTexts": [bo_dau(c.get("nhan", "")) for c in columns],
        "headerRows": int(dinh_danh["hang_du_lieu_dau"]),
        "rowHeightMm": round(float(luoi["buoc_dong"]) / PX_MM, SO_CHU_SO),
        "tableWidthMm": round(width / PX_MM, SO_CHU_SO),
    }


def _chuan_hoa(widths: Sequence[float]) -> list[float]:
    total = float(sum(widths))
    if not widths or total <= 0:
        return []
    return [float(w) / total for w in widths]


def _can_chinh(
    image: Sequence[float], template: Sequence[float]
) -> tuple[float, list[tuple[tuple[int, ...], tuple[int, ...]]]] | None:
    """Căn hai dãy bề rộng đã chuẩn hóa bằng quy hoạch động.

    Mỗi bước nối một nhóm cột ảnh với một nhóm cột mẫu: 1–1 (sai lệch bề rộng), 1 ảnh–2 mẫu (gộp, ``PHAT_GOP_COT``) hoặc
    2 ảnh–1 mẫu (tách, ``PHAT_TACH_COT``). Trả ``(tổng chi phí, các nhóm theo thứ tự trái → phải)``; ``None`` khi không có
    cách căn nào dùng hết mọi cột (số cột chênh quá nhiều). Thứ tự thử cố định và chỉ cập nhật khi chi phí giảm hẳn nên kết
    quả tất định.
    """
    m, n = len(image), len(template)
    inf = float("inf")
    cost = [[inf] * (n + 1) for _ in range(m + 1)]
    back: list[list[tuple[int, int] | None]] = [[None] * (n + 1) for _ in range(m + 1)]
    cost[0][0] = 0.0

    def relax(i: int, j: int, to_i: int, to_j: int, extra: float) -> None:
        candidate = cost[i][j] + extra
        if candidate < cost[to_i][to_j]:
            cost[to_i][to_j] = candidate
            back[to_i][to_j] = (i, j)

    for i in range(m + 1):
        for j in range(n + 1):
            if cost[i][j] == inf:
                continue
            if i < m and j < n:
                relax(i, j, i + 1, j + 1, abs(image[i] - template[j]))
            if i < m and j + 1 < n:
                relax(i, j, i + 1, j + 2, abs(image[i] - template[j] - template[j + 1]) + PHAT_GOP_COT)
            if i + 1 < m and j < n:
                relax(i, j, i + 2, j + 1, abs(image[i] + image[i + 1] - template[j]) + PHAT_TACH_COT)
    if cost[m][n] == inf:
        return None
    groups: list[tuple[tuple[int, ...], tuple[int, ...]]] = []
    i, j = m, n
    while (i, j) != (0, 0):
        previous = back[i][j]
        assert previous is not None
        pi, pj = previous
        groups.append((tuple(range(pi, i)), tuple(range(pj, j))))
        i, j = pi, pj
    groups.reverse()
    return cost[m][n], groups


class KetQuaKhop(NamedTuple):
    """Kết quả khớp mẫu kèm thông tin để tầng trên biết cột nào có thể khôi phục bằng bằng chứng hình học.

    ``cat_trai``/``cat_phai``: số cột đầu/cuối của MẪU nằm ngoài lưới dò được (vạch mép bị mất hoặc ảnh cắt mép);
    ``gop``: các cặp ``(chỉ số cột ảnh, chỉ số cột mẫu đầu)`` mà MỘT cột ảnh bằng HAI cột mẫu kề nhau (mất một vạch giữa).
    """

    score: float
    column_map: dict[int, int]
    cat_trai: int = 0
    cat_phai: int = 0
    gop: tuple[tuple[int, int], ...] = ()


def _chon_can_chinh(
    image: Sequence[float], template: Sequence[float]
) -> tuple[float, list[tuple[tuple[int, ...], tuple[int, ...]]], int, int] | None:
    """Chọn phép căn: toàn bộ mẫu (như P6), hoặc chỉ một đoạn liên tiếp của mẫu khi lưới ảnh bị cắt ở mép.

    Phép căn cắt mép bỏ tối đa ``SO_COT_BIEN_TOI_DA`` cột đầu/cuối của mẫu, chịu phạt ``PHAT_MAT_COT_BIEN`` mỗi cột. Chỉ
    được chọn khi (1) rẻ hơn hẳn phép căn toàn bộ (``CAI_THIEN_CAT_BIEN_TOI_THIEU``) và (2) hơn hẳn mọi cách cắt khác
    (``BIEN_PHAN_BIET_CAT_BIEN``): hai cách cắt gần ngang nhau nghĩa là chưa biết ảnh thiếu cột nào, khi đó giữ phép căn
    toàn bộ (không đoán). Trả ``(chi phí tổng, nhóm, số cột mẫu bỏ ở trái, số cột bỏ ở phải)``.
    """
    n = len(template)
    full = _can_chinh(image, template)
    inf = float("inf")
    full_cost = full[0] if full else inf
    candidates: list[tuple[float, int, int, list[tuple[tuple[int, ...], tuple[int, ...]]]]] = []
    for left in range(SO_COT_BIEN_TOI_DA + 1):
        for right in range(SO_COT_BIEN_TOI_DA + 1 - left):
            kept = n - left - right
            if left + right == 0 or kept < 2 or sum(template[left : n - right]) < PHU_MAU_TOI_THIEU:
                continue
            aligned = _can_chinh(image, _chuan_hoa(template[left : n - right]))
            if aligned is None or aligned[0] > SAI_LECH_CAT_BIEN_TOI_DA:
                continue
            candidates.append((aligned[0] + PHAT_MAT_COT_BIEN * (left + right), left, right, aligned[1]))
    candidates.sort(key=lambda c: (c[0], c[1] + c[2], c[1]))
    if candidates:
        best = candidates[0]
        runner_up = candidates[1][0] if len(candidates) > 1 else inf
        if best[0] <= full_cost - CAI_THIEN_CAT_BIEN_TOI_THIEU and runner_up - best[0] >= BIEN_PHAN_BIET_CAT_BIEN:
            return best[0], best[3], best[1], best[2]
    if full is None:
        return None
    return full[0], full[1], 0, 0


def khop_mau_chi_tiet(chu_ky_anh: Mapping[str, Any], chu_ky_mau: Mapping[str, Any]) -> KetQuaKhop:
    """Như ``khop_mau`` nhưng trả thêm cột mẫu bị cắt mép và cột bị gộp (để khôi phục vạch có bằng chứng).

    Cột mẫu nằm ngoài lưới (cắt mép) hoặc bị gộp/tách KHÔNG có trong ``column_map``. Hàm thuần và tất định.
    """
    image = _chuan_hoa(chu_ky_anh.get("columnWidths") or [])
    template = _chuan_hoa(chu_ky_mau.get("columnWidths") or [])
    if not image or not template:
        return KetQuaKhop(0.0, {})
    chosen = _chon_can_chinh(image, template)
    if chosen is None:
        return KetQuaKhop(0.0, {})
    cost, groups, left, right = chosen
    column_map = {
        template_group[0] + left: image_group[0]
        for image_group, template_group in groups
        if len(image_group) == 1 and len(template_group) == 1
    }
    merged = tuple(
        (image_group[0], template_group[0] + left)
        for image_group, template_group in groups
        if len(image_group) == 1 and len(template_group) == 2
    )
    score = max(0.0, 1.0 - cost)
    image_texts = list(chu_ky_anh.get("headerTexts") or [])
    template_texts = list(chu_ky_mau.get("headerTexts") or [])
    ratios = []
    for template_index, image_index in column_map.items():
        if image_index >= len(image_texts) or template_index >= len(template_texts):
            continue
        image_text, template_text = bo_dau(image_texts[image_index]), bo_dau(template_texts[template_index])
        if image_text and template_text:
            ratios.append(difflib.SequenceMatcher(None, image_text, template_text).ratio())
    if len(ratios) >= SO_CAP_TIEU_DE_TOI_THIEU:
        score = TRONG_SO_BE_RONG * score + TRONG_SO_TIEU_DE * (sum(ratios) / len(ratios))
    return KetQuaKhop(round(min(max(score, 0.0), 1.0), SO_CHU_SO), column_map, left, right, merged)


def khop_mau(
    chu_ky_anh: Mapping[str, Any], chu_ky_mau: Mapping[str, Any]
) -> tuple[float, dict[int, int]]:
    """Điểm khớp (0–1, 4 chữ số) giữa chữ ký ảnh và chữ ký mẫu, cùng ánh xạ cột ``{chỉ số cột mẫu: chỉ số cột ảnh}``.

    Chỉ các cột được căn 1–1 mới có trong ánh xạ; cột mẫu bị gộp với cột kề (mất vạch), bị tách (vạch giả) hoặc nằm
    ngoài lưới dò được (cắt mép, P7) vắng mặt, tầng trên coi đó là không đọc được. Hai tờ không căn được (số cột chênh quá
    nhiều) cho ``(0.0, {})``. Hàm thuần và tất định: cùng đầu vào luôn cho cùng kết quả.
    """
    ket_qua = khop_mau_chi_tiet(chu_ky_anh, chu_ky_mau)
    return ket_qua.score, ket_qua.column_map
