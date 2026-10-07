"""Chuyển chuỗi điểm số/điểm chữ do mô hình đọc thành giá trị điểm, và nắn điểm chữ về từ điển hợp lệ.

Nguồn gốc: ``ket_hop/hop_nhat.py`` — ``so_tu_chuoi_so``, ``so_tu_chuoi_chu``, ``dinh_dang_diem``, ``khoang_cach_sua``,
``hau_xu_ly_tu_dien`` và các bảng từ; từ điển 133 cụm lấy từ ``ket_hop/cau_hinh_hop_nhat.json`` (xây từ tập
train để tránh rò rỉ). Các hàm giữ nguyên tên Việt hóa và hành vi của bản gốc.

KHÔNG mang sang nhánh "trọng tài" của ``hop_nhat`` (``hop_nhat_mot_o`` chọn một giá trị khi hai kênh bất đồng hoặc cùng
yếu): trái bất biến của dự án — Đỏ không gợi ý giá trị. Phân loại hai kênh nằm ở ``classification.py``.
"""
from __future__ import annotations

import re
import unicodedata
from decimal import Decimal

# ---------------------------------------------------------------------------
# 1. Chuẩn hoá giá trị điểm
# ---------------------------------------------------------------------------
TU_PHAN_NGUYEN = {
    "không": 0, "một": 1, "hai": 2, "ba": 3, "bốn": 4, "năm": 5,
    "sáu": 6, "bảy": 7, "tám": 8, "chín": 9, "mười": 10,
}
TU_PHAN_THAP = {
    "không": 0, "một": 1, "hai": 2, "ba": 3, "bốn": 4, "tư": 4,
    "năm": 5, "rưỡi": 5, "sáu": 6, "bảy": 7, "tám": 8, "chín": 9,
    "chẵn": 0,
}

MAU_DIEM_SO = re.compile(r"^(?:10(?:\.0)?|[0-9](?:\.[0-9])?)$")


def chuan_hoa(s: str) -> str:
    return unicodedata.normalize("NFC", (s or "").strip().lower())


def so_tu_chuoi_so(pred: str):
    """'7.5' -> 7.5 ; '6' -> 6.0 ; '8.' -> 8.0 ; trả None nếu không phải một điểm hợp lệ (0..10).

    '8.' (có dấu chấm, thiếu số thập phân) là cách viết thật của giảng viên (dữ liệu Cô Mai,
    Tầng 4) — CRNN chép đúng nét thì vẫn phải hiểu là 8.0."""
    p = chuan_hoa(pred)
    if re.fullmatch(r"\d+\.", p):
        p += "0"
    if not MAU_DIEM_SO.match(p):
        return None
    v = float(p)
    return v if 0.0 <= v <= 10.0 else None


def so_tu_chuoi_chu(pred: str):
    """'bảy rưỡi' -> 7.5 ; 'mười' -> 10.0 ; trả None nếu không giải được."""
    p = chuan_hoa(pred)
    if not p:
        return None
    tokens = p.split()
    if len(tokens) == 1:
        if tokens[0] == "mười":
            return 10.0
        if tokens[0] in TU_PHAN_NGUYEN:          # ví dụ nhãn rút gọn 'không'
            return float(TU_PHAN_NGUYEN[tokens[0]])
        return None
    if len(tokens) == 2:
        nguyen, thap = tokens
        if nguyen in TU_PHAN_NGUYEN and thap in TU_PHAN_THAP:
            v = TU_PHAN_NGUYEN[nguyen] + TU_PHAN_THAP[thap] / 10.0
            return v if 0.0 <= v <= 10.0 else None
    return None


def dinh_dang_diem(v) -> str:
    """7.5 -> '7.5' ; 10.0 -> '10.0'."""
    return "" if v is None else f"{v:.1f}"


# ---------------------------------------------------------------------------
# 2. Hậu xử lý từ điển cho nhánh chữ
# ---------------------------------------------------------------------------
def khoang_cach_sua(a: str, b: str) -> int:
    truoc = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        hien = [i]
        for j, cb in enumerate(b, 1):
            hien.append(min(hien[-1] + 1, truoc[j] + 1, truoc[j - 1] + (ca != cb)))
        truoc = hien
    return truoc[-1]


def hau_xu_ly_tu_dien(pred: str, tu_dien: list[str]) -> str:
    """Nắn dự đoán về mục gần nhất trong từ điển nhãn hợp lệ."""
    p = unicodedata.normalize("NFC", (pred or "").strip())
    if not p or not tu_dien or p in tu_dien:
        return p
    # NẾU bản thân dự đoán thô đã là một điểm chữ hợp lệ (ví dụ: 'mười', 'hai rưỡi') -> GIỮ NGUYÊN
    if so_tu_chuoi_chu(p) is not None:
        return p
    return min(tu_dien, key=lambda c: (khoang_cach_sua(p, c), abs(len(p) - len(c))))


def nan_diem_chu(pred: str, tu_dien=None, khoang_cach_toi_da: int = 2) -> str:
    """Như ``hau_xu_ly_tu_dien`` nhưng CHỈ nắn khi dự đoán gần một cụm hợp lệ (≤ ``khoang_cach_toi_da`` ký tự sửa).

    Bản gốc luôn nắn về cụm gần nhất, kể cả khi chuỗi đọc ra là rác — biến nhiễu thành một điểm hợp lệ có vẻ chắc
    chắn. Ở đây chuỗi quá xa từ điển được giữ nguyên (không giải được ra điểm) để kênh chữ được coi là không đọc được
    và dòng không bị gợi ý giá trị tùy tiện (bất biến 4 trong AGENTS.md).
    """
    p = unicodedata.normalize("NFC", (pred or "").strip())
    dic = list(TU_DIEN if tu_dien is None else tu_dien)
    if not p or p in dic or so_tu_chuoi_chu(p) is not None:
        return p
    gan_nhat = min(dic, key=lambda c: (khoang_cach_sua(p, c), abs(len(p) - len(c))))
    return gan_nhat if khoang_cach_sua(p, gan_nhat) <= khoang_cach_toi_da else p


def grade_decimal(value: float | None) -> Decimal | None:
    """Điểm float hợp lệ (0..10, một chữ số thập phân) -> ``Decimal('7.5')``; ``None`` giữ nguyên."""
    if value is None:
        return None
    return Decimal(f"{value:.1f}")


# Từ điển 133 cụm điểm chữ hợp lệ.
TU_DIEN: tuple[str, ...] = (
    "ba ba",
    "ba bảy",
    "ba bốn",
    "ba chín",
    "ba chẵn",
    "ba hai",
    "ba không",
    "ba một",
    "ba năm",
    "ba rưỡi",
    "ba sáu",
    "ba tám",
    "ba tư",
    "bảy ba",
    "bảy bảy",
    "bảy bốn",
    "bảy chín",
    "bảy chẵn",
    "bảy hai",
    "bảy không",
    "bảy một",
    "bảy năm",
    "bảy rưỡi",
    "bảy sáu",
    "bảy tám",
    "bảy tư",
    "bốn ba",
    "bốn bảy",
    "bốn bốn",
    "bốn chín",
    "bốn chẵn",
    "bốn hai",
    "bốn không",
    "bốn một",
    "bốn năm",
    "bốn rưỡi",
    "bốn sáu",
    "bốn tám",
    "bốn tư",
    "chín ba",
    "chín bảy",
    "chín bốn",
    "chín chín",
    "chín chẵn",
    "chín hai",
    "chín không",
    "chín một",
    "chín năm",
    "chín rưỡi",
    "chín sáu",
    "chín tám",
    "chín tư",
    "hai ba",
    "hai bảy",
    "hai bốn",
    "hai chín",
    "hai chẵn",
    "hai hai",
    "hai không",
    "hai một",
    "hai năm",
    "hai rưỡi",
    "hai sáu",
    "hai tám",
    "hai tư",
    "không ba",
    "không bảy",
    "không bốn",
    "không chín",
    "không chẵn",
    "không hai",
    "không không",
    "không một",
    "không năm",
    "không rưỡi",
    "không sáu",
    "không tám",
    "không tư",
    "mười",
    "mười chẵn",
    "mười không",
    "một ba",
    "một bảy",
    "một bốn",
    "một chín",
    "một chẵn",
    "một hai",
    "một không",
    "một một",
    "một năm",
    "một rưỡi",
    "một sáu",
    "một tám",
    "một tư",
    "năm ba",
    "năm bảy",
    "năm bốn",
    "năm chín",
    "năm chẵn",
    "năm hai",
    "năm không",
    "năm một",
    "năm năm",
    "năm rưỡi",
    "năm sáu",
    "năm tám",
    "năm tư",
    "sáu ba",
    "sáu bảy",
    "sáu bốn",
    "sáu chín",
    "sáu chẵn",
    "sáu hai",
    "sáu không",
    "sáu một",
    "sáu năm",
    "sáu rưỡi",
    "sáu sáu",
    "sáu tám",
    "sáu tư",
    "tám ba",
    "tám bảy",
    "tám bốn",
    "tám chín",
    "tám chẵn",
    "tám hai",
    "tám không",
    "tám một",
    "tám năm",
    "tám rưỡi",
    "tám sáu",
    "tám tám",
    "tám tư",
)
