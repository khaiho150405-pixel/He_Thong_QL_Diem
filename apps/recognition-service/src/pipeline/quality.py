"""Image quality checks run on the page after perspective correction.

Nguồn gốc: label_tool/kiem_dinh_anh.py — ``do_net`` và ``danh_gia_chat_luong`` cùng các hằng số ngưỡng.
Đo trên trang A4 200 DPI đã nắn nên ngưỡng dùng chung cho mọi ảnh, không phụ thuộc kích thước tệp gốc.
(``danh_gia_la_bang_diem`` thuộc khâu dò lưới, xem ``grid.py``.)

``assess_quality`` trả cảnh báo mức ``chan`` (nên dừng) hoặc ``canh_bao`` (vẫn chạy được);
``ensure_quality`` ném ``PipelineError("IMAGE_QUALITY_LOW")`` khi có cảnh báo mức ``chan``.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Mapping, Sequence

import cv2

from .errors import PipelineError

# ── Ngưỡng (đo trên trang A4 đã nắn về 1654x2338) ─────────────────────────────
NET_KEM = 120.0  # phương sai Laplacian: dưới mức này là mờ rõ rệt
NET_CANH_BAO = 260.0  # dưới mức này thì cảnh báo "hơi mờ"
XIEN_CANH_BAO = 6.0  # độ: góc xiên của tờ giấy khi chụp
XIEN_NANG = 12.0
MEO_CANH_BAO = 0.16  # lệch bề dài hai cạnh đối diện: chụp chéo
MEO_NANG = 0.28
PHAN_GIAI_TOI_THIEU = 1.0e6  # ~1.0 MP: dưới mức này chữ viết tay vỡ nét
# Độ phân giải THỰC của tờ giấy (DPI quy đổi trên khổ A4) — chỉ số quyết định, vì trang luôn được nắn về
# 1654x2338 (200 DPI): ảnh gốc thưa hơn thì nét chữ đã mất từ trước, phóng to lên không cứu được.
DPI_CHAN = 100.0
DPI_CANH_BAO = 145.0
DIEN_TICH_A4_INCH2 = 8.268 * 11.693

CHAN = "chan"
CANH_BAO = "canh_bao"


@dataclass(frozen=True, slots=True)
class QualityReport:
    """Kết quả kiểm định: danh sách ``(mức, nội dung)`` và các chỉ số đo được."""

    warnings: tuple[tuple[str, str], ...]
    metrics: dict[str, Any] = field(default_factory=dict)

    @property
    def blocking(self) -> tuple[str, ...]:
        return tuple(text for level, text in self.warnings if level == CHAN)


def do_net(page, bang: Sequence[float] | None = None) -> float:
    """Độ nét trên vùng bảng (phương sai Laplacian, ảnh đã chuẩn hoá về A4).

    ``bang`` là hộp ``(x0, y0, x1, y1)`` của bảng nếu đã dò được; nếu không đo trên cả trang.
    """
    g = cv2.cvtColor(page, cv2.COLOR_BGR2GRAY) if page.ndim == 3 else page
    if bang:
        x0, y0, x1, y1 = [int(v) for v in bang]
        g = g[max(0, y0) : min(g.shape[0], y1), max(0, x0) : min(g.shape[1], x1)]
    if g.size < 10000:
        return 0.0
    return float(cv2.Laplacian(g, cv2.CV_64F).var())


def danh_gia_chat_luong(
    img_goc,
    page,
    kq_nan: Mapping[str, Any],
    bang: Sequence[float] | None = None,
) -> tuple[list[tuple[str, str]], dict[str, Any]]:
    """Trả ``(danh_sach_canh_bao, chi_so)``. Mỗi cảnh báo: ``(muc, noi_dung)``.

    ``muc`` = ``'chan'`` nên dừng, ``'canh_bao'`` vẫn chạy được nhưng cần lưu ý.
    ``kq_nan`` là kết quả của ``page.nan_trang`` (cần ``ty_le_quad``, ``goc_nghieng_giay``,
    ``goc_xien_bu``, ``meo_phoi_canh``, ``canh_thieu``).
    """
    cb: list[tuple[str, str]] = []
    chi_so: dict[str, Any] = {}
    h, w = img_goc.shape[:2]
    chi_so["do_phan_giai_mp"] = round(h * w / 1e6, 2)
    tl_quad = float(kq_nan.get("ty_le_quad") or 0.0)
    px_giay = (tl_quad if 0 < tl_quad <= 1 else 1.0) * h * w
    dpi = (px_giay / DIEN_TICH_A4_INCH2) ** 0.5
    chi_so["dpi_hieu_dung"] = round(dpi, 0)
    if dpi < DPI_CHAN:
        cb.append(
            (
                CHAN,
                f"ảnh quá nhỏ so với tờ giấy (chỉ ~{dpi:.0f} DPI, cần ít nhất {DPI_CHAN:.0f} DPI) — "
                f"chữ viết tay đã mất nét, hãy chụp/quét lại ở độ phân giải cao hơn",
            )
        )
    elif dpi < DPI_CANH_BAO:
        cb.append(
            (
                CANH_BAO,
                f"độ phân giải hơi thấp (~{dpi:.0f} DPI) — nên chụp gần lại hoặc quét ở 200–300 DPI",
            )
        )
    elif h * w < PHAN_GIAI_TOI_THIEU:
        cb.append(
            (
                CANH_BAO,
                f'ảnh chỉ {w}x{h} ({chi_so["do_phan_giai_mp"]}MP) — nên chụp/quét ở độ phân giải cao hơn',
            )
        )

    net = do_net(page, bang)
    chi_so["do_net"] = round(net, 1)
    if net < NET_KEM:
        cb.append(
            (
                CHAN,
                f"ảnh quá mờ (độ nét {net:.0f}, ngưỡng {NET_KEM:.0f}) — chụp lại, giữ máy chắc tay và đủ sáng",
            )
        )
    elif net < NET_CANH_BAO:
        cb.append((CANH_BAO, f"ảnh hơi mờ (độ nét {net:.0f}) — kết quả nhận dạng có thể giảm"))

    goc = max(
        abs(float(kq_nan.get("goc_nghieng_giay") or 0.0)),
        abs(float(kq_nan.get("goc_xien_bu") or 0.0)),
    )
    chi_so["goc_xien_do"] = round(goc, 2)
    if goc >= XIEN_NANG:
        cb.append(
            (
                CANH_BAO,
                f"tờ giấy bị xoay {goc:.0f}° trong ảnh — hệ thống đã tự nắn thẳng lại, "
                f"nhưng ảnh chụp xiên nhiều làm chữ bị rỗ, nên chụp thẳng hơn",
            )
        )
    elif goc >= XIEN_CANH_BAO:
        cb.append((CANH_BAO, f"tờ giấy hơi xiên {goc:.1f}° — đã tự nắn lại"))

    meo = float(kq_nan.get("meo_phoi_canh") or 0.0)
    chi_so["meo_phoi_canh"] = round(meo, 3)
    if meo >= MEO_NANG:
        cb.append(
            (
                CANH_BAO,
                f"ảnh chụp chéo khá nhiều (lệch {meo:.0%} giữa hai cạnh đối diện) — "
                f"đã nắn phối cảnh nhưng nên đặt máy vuông góc phía trên tờ giấy",
            )
        )
    elif meo >= MEO_CANH_BAO:
        cb.append((CANH_BAO, f"ảnh hơi chụp chéo (lệch {meo:.0%}) — đã tự nắn phối cảnh"))

    thieu = list(kq_nan.get("canh_thieu") or [])
    chi_so["canh_giay_ngoai_khung"] = thieu
    if thieu and thieu != ["tat_ca"]:
        ten = {"tren": "trên", "duoi": "dưới", "trai": "trái", "phai": "phải"}
        cb.append(
            (
                CANH_BAO,
                "ảnh bị cắt mất cạnh "
                + ", ".join(ten.get(t, t) for t in thieu)
                + " của tờ giấy — chụp lùi ra để thấy đủ 4 cạnh",
            )
        )
    tl = float(kq_nan.get("ty_le_quad") or 0.0)
    chi_so["ty_le_giay_trong_khung"] = round(tl, 2)
    if 0 < tl < 0.35:
        cb.append((CANH_BAO, f"tờ giấy chỉ chiếm {tl:.0%} khung hình — chụp gần lại để chữ nét hơn"))
    return cb, chi_so


def assess_quality(
    img_goc,
    page,
    kq_nan: Mapping[str, Any],
    bang: Sequence[float] | None = None,
) -> QualityReport:
    warnings, metrics = danh_gia_chat_luong(img_goc, page, kq_nan, bang)
    return QualityReport(tuple(warnings), metrics)


def ensure_quality(
    img_goc,
    page,
    kq_nan: Mapping[str, Any],
    bang: Sequence[float] | None = None,
) -> QualityReport:
    """Trả báo cáo khi ảnh dùng được; ném ``IMAGE_QUALITY_LOW`` nếu có cảnh báo mức ``chan``."""
    report = assess_quality(img_goc, page, kq_nan, bang)
    if report.blocking:
        raise PipelineError("IMAGE_QUALITY_LOW", "; ".join(report.blocking))
    return report
