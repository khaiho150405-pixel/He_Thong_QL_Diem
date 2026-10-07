"""Nắn ảnh bảng điểm về trang A4 chuẩn cho MẪU BẤT KỲ (không neo theo biểu mẫu).

Nguồn gốc: label_tool/tien_xu_ly_v3.py (dự án huấn luyện, ngoài repo). Các hàm được giữ nguyên
thuật toán và tên Việt hóa để dễ đối chiếu với bản gốc:

- ``_mat_na_giay``, ``_khop_canh_hough``, ``_quad_hop_le``, ``do_to_giay_chi_tiet``: dò 4 góc tờ giấy theo
  màu (Lab) + Hough từng cạnh;
- ``_nhi_phan``, ``_do_vach``, ``_diem_tu``, ``_H_nan_theo_diem_tu``, ``_H_chinh_theo_luoi``,
  ``nan_theo_luoi``: nắn theo chính lưới bảng bằng homography (điểm tụ);
- ``_mau_trung_vi``, ``_truong_lech``, ``nan_anh``: nắn cong cục bộ;
- ``_diem_luoi_tho``, ``nan_trang``, ``_do_tu_the_giay``: quy trình tổng cho mẫu bất kỳ.

Khác bản gốc: bỏ ``QUAD_OVERRIDES`` (góc chỉnh tay theo tên file) và mọi tham số ``ten_file``; đọc ảnh từ
bytes (không đọc HEIC, không đọc đường dẫn). Chỉ dùng OpenCV + NumPy, tất định, không truy cập mạng.
"""
from __future__ import annotations

import math

import cv2
import numpy as np

from .errors import PipelineError

# Hằng số biểu mẫu (giống v2/v3 để kết quả so sánh được).
DPI = 200
A4 = (int(8.27 * DPI), int(11.69 * DPI))  # 1654 x 2338
PX_MM = A4[0] / 210.0
MAU_VIEN = (255, 255, 255)  # tô phần nằm ngoài ảnh gốc (giấy thiếu góc) bằng trắng
SO_VONG_NAN = 3  # số vòng lặp nắn theo lưới
LECH_CONG_TOI_DA = 12.0  # px — độ cong tối đa chấp nhận khi nắn cục bộ

MAX_IMAGE_PIXELS = 100_000_000


def doc_anh(content: bytes):
    """Giải mã ảnh PNG/JPEG từ bytes thành mảng BGR; lỗi → PipelineError(IMAGE_UNREADABLE)."""
    if not content:
        raise PipelineError("IMAGE_UNREADABLE", "Ảnh rỗng.")
    buf = np.frombuffer(content, dtype=np.uint8)
    img = cv2.imdecode(buf, cv2.IMREAD_COLOR)
    if img is None:
        raise PipelineError("IMAGE_UNREADABLE", "Không giải mã được ảnh (cần PNG hoặc JPEG).")
    if img.shape[0] * img.shape[1] > MAX_IMAGE_PIXELS:
        raise PipelineError("IMAGE_UNREADABLE", "Ảnh quá lớn.")
    return img


def _sap_xep_4_goc(p):
    p = np.asarray(p, np.float32).reshape(4, 2)
    s = p.sum(1); d = np.diff(p, axis=1).ravel()
    return np.array([p[np.argmin(s)], p[np.argmin(d)],
                     p[np.argmax(s)], p[np.argmax(d)]], np.float32)


# ═══════════════════ 1. Dò tờ giấy theo màu + Hough từng cạnh ══════════════════
def _mat_na_giay(img, canh_dai=1000):
    """Mặt nạ giấy trên ảnh thu nhỏ. Trả (mask uint8 0/255, hệ số thu, thông tin)."""
    h, w = img.shape[:2]
    s = canh_dai / float(max(h, w))
    nho = cv2.resize(img, None, fx=s, fy=s, interpolation=cv2.INTER_AREA)
    lab = cv2.cvtColor(nho, cv2.COLOR_BGR2LAB).astype(np.float32)
    L, A, B = lab[..., 0], lab[..., 1] - 128.0, lab[..., 2] - 128.0
    H, W = L.shape
    y0, y1, x0, x1 = int(H * .3), int(H * .7), int(W * .3), int(W * .7)
    Lg = L[y0:y1, x0:x1]
    L_giay = max(float(np.percentile(Lg, 75)), 1.0)       # độ sáng nền giấy (bỏ qua mực)
    la_giay = Lg > 0.85 * L_giay
    a_giay = float(np.median(A[y0:y1, x0:x1][la_giay]))
    b_giay = float(np.median(B[y0:y1, x0:x1][la_giay]))
    lech_mau = np.hypot(A - a_giay, B - b_giay)             # khác sắc độ so với giấy
    ty_sang = L / L_giay
    manh = ((ty_sang > 0.72) & (lech_mau < 10)).astype(np.uint8)
    yeu = ((ty_sang > 0.42) & (lech_mau < 9)).astype(np.uint8)   # vùng giấy bị bóng đổ
    manh = cv2.morphologyEx(manh, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    hop = cv2.morphologyEx(cv2.bitwise_or(manh, yeu), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, nhan, _, _ = cv2.connectedComponentsWithStats(hop, connectivity=8)
    if n < 2:
        return None, s, dict(L_giay=L_giay)
    dem = np.bincount(nhan[manh > 0].ravel(), minlength=n)
    dem[0] = 0
    k = int(np.argmax(dem))
    if dem[k] == 0:
        return None, s, dict(L_giay=L_giay)
    m = (nhan == k).astype(np.uint8) * 255
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((15, 15), np.uint8))
    cnts, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if not cnts:
        return None, s, dict(L_giay=L_giay)
    c = max(cnts, key=cv2.contourArea)
    day = np.zeros_like(m)
    cv2.drawContours(day, [c], -1, 255, -1)                 # lấp lỗ (chữ, bảng)
    return day, s, dict(L_giay=L_giay, a_giay=a_giay, b_giay=b_giay, contour=c)



def _giao_diem(l1, l2):
    """Giao điểm hai đường (điểm, vector chỉ phương)."""
    (p, u), (q, v) = l1, l2
    M = np.array([[u[0], -v[0]], [u[1], -v[1]]], np.float64)
    if abs(np.linalg.det(M)) < 1e-9:
        return None
    t = np.linalg.solve(M, np.asarray(q, np.float64) - np.asarray(p, np.float64))
    return np.asarray(p, np.float64) + t[0] * np.asarray(u, np.float64)



def _khop_canh_hough(pts, goc0, bin_px=2.0, dai_toi_thieu=60):
    """Hough 1 chiều cho MỘT cạnh giấy: tìm đường thẳng có nhiều điểm biên nhất.
    Quét góc thô ±10° (bước 0.5°) rồi tinh ±0.5° (bước 0.1°).
    Trả (điểm, vector chỉ phương, độ dài phần thấy được) hoặc None."""
    if len(pts) < 20:
        return None

    def quet(goc_tam, cua_so, buoc):
        tot = None
        for dg in np.arange(-cua_so, cua_so + 1e-9, buoc):
            th = goc_tam + np.radians(dg)
            n = np.array([-np.sin(th), np.cos(th)])
            rho = pts @ n
            lo = float(rho.min())
            so_bin = int((rho.max() - lo) / bin_px) + 3
            hist = np.bincount(((rho - lo) / bin_px).astype(np.int64), minlength=so_bin).astype(np.float64)
            hist = np.convolve(hist, [1, 2, 1], mode='same')
            i = int(np.argmax(hist))
            if tot is None or hist[i] > tot[0]:
                tot = (hist[i], th, lo + (i + 0.5) * bin_px)
        return tot

    _, th, _ = quet(goc0, 10.0, 0.5)
    _, th, rho0 = quet(th, 0.5, 0.1)
    n = np.array([-np.sin(th), np.cos(th)])
    trong = pts[np.abs(pts @ n - rho0) <= 3.0]
    if len(trong) < 15:
        return None
    for _ in range(2):                                     # tinh chỉnh bằng PCA + cắt ngoại lai
        tb = trong.mean(0)
        _, vec = np.linalg.eigh(np.cov((trong - tb).T))
        u, nn = vec[:, 1], vec[:, 0]
        du = np.abs((trong - tb) @ nn)
        giu = du <= max(1.5, 2.5 * float(np.median(du)))
        if giu.sum() < 15:
            break
        trong = trong[giu]
    tb = trong.mean(0)
    _, vec = np.linalg.eigh(np.cov((trong - tb).T))
    u = vec[:, 1]
    t = (trong - tb) @ u
    dai = float(t.max() - t.min())
    if dai < dai_toi_thieu:
        return None
    return tb, u, dai



def _quad_hop_le(q, W, H, dien_tich_mask=None):
    q = np.asarray(q, np.float64)
    if not np.all(np.isfinite(q)):
        return False
    if (q[:, 0] < -0.35 * W).any() or (q[:, 0] > 1.35 * W).any() or \
       (q[:, 1] < -0.35 * H).any() or (q[:, 1] > 1.35 * H).any():
        return False
    if not cv2.isContourConvex(q.astype(np.float32).reshape(-1, 1, 2)):
        return False
    rong = (np.linalg.norm(q[1] - q[0]) + np.linalg.norm(q[2] - q[3])) / 2
    cao = (np.linalg.norm(q[3] - q[0]) + np.linalg.norm(q[2] - q[1])) / 2
    if rong < 0.25 * W or cao < 0.25 * H:
        return False
    if not (1.10 <= cao / max(rong, 1e-6) <= 1.80):
        return False
    if dien_tich_mask:
        dt = cv2.contourArea(q.astype(np.float32))
        if not (0.80 <= dt / dien_tich_mask <= 1.60):
            return False
    return True



def do_to_giay_chi_tiet(img):
    """Dò 4 góc tờ giấy. Trả dict(quad, ty_le, cham_bien, nguon, canh_thieu)."""
    h, w = img.shape[:2]
    mask, s, tt = _mat_na_giay(img)
    khung = np.array([[0, 0], [w - 1, 0], [w - 1, h - 1], [0, h - 1]], np.float32)
    if mask is None:
        return dict(quad=khung, ty_le=1.0, cham_bien=True, nguon='khung_anh', canh_thieu=['tat_ca'])
    H, W = mask.shape
    ty_le = float((mask > 0).mean())
    c = tt['contour'].reshape(-1, 2).astype(np.float64)
    N = len(c)
    tren_mep = (c[:, 0] <= 1) | (c[:, 0] >= W - 2) | (c[:, 1] <= 1) | (c[:, 1] >= H - 2)
    cham_bien = bool(tren_mep.mean() > 0.02)
    if ty_le > 0.97 or N < 100:                       # giấy phủ kín khung (ảnh đã crop sẵn)
        return dict(quad=khung, ty_le=ty_le, cham_bien=True, nguon='khung_anh', canh_thieu=['tat_ca'])

    # hướng tiếp tuyến tại mỗi điểm biên
    k = 5
    tiep = c[(np.arange(N) + k) % N] - c[(np.arange(N) - k) % N]
    goc = np.mod(np.arctan2(tiep[:, 1], tiep[:, 0]), np.pi)
    hop_le = ~tren_mep
    # hướng trục ngang của tờ giấy: trung bình vòng theo 4θ (gập mọi cạnh về một hướng)
    g4 = 4.0 * goc[hop_le]
    alpha = float(np.arctan2(np.sin(g4).sum(), np.cos(g4).sum()) / 4.0) if hop_le.any() else 0.0
    ux = np.array([np.cos(alpha), np.sin(alpha)])
    uy = np.array([-np.sin(alpha), np.cos(alpha)])
    M = cv2.moments(mask, binaryImage=True)
    tam = np.array([M['m10'] / M['m00'], M['m01'] / M['m00']])
    rel = c - tam
    px, py = rel @ ux, rel @ uy
    lech = np.abs(np.mod(goc - alpha + np.pi / 2, np.pi) - np.pi / 2)   # 0 = song song trục ngang
    ngang = hop_le & (lech < np.radians(30))
    doc = hop_le & (lech > np.radians(60))

    canh = {}
    nhom = {'tren': ngang & (py < 0), 'duoi': ngang & (py > 0),
            'trai': doc & (px < 0), 'phai': doc & (px > 0)}
    rong_mask = float(np.ptp(px)) if len(px) else W
    cao_mask = float(np.ptp(py)) if len(py) else H
    for ten, chon in nhom.items():
        goc0 = alpha if ten in ('tren', 'duoi') else alpha + np.pi / 2
        dai_ky_vong = rong_mask if ten in ('tren', 'duoi') else cao_mask
        kq = _khop_canh_hough(c[chon], goc0, dai_toi_thieu=max(60.0, 0.22 * dai_ky_vong))
        canh[ten] = None if kq is None else (kq[0], kq[1])

    # cạnh không thấy (nằm ngoài khung) -> dùng mép khung ảnh phía đó
    mep = {'tren': (np.array([0., 0.]), np.array([1., 0.])),
           'duoi': (np.array([0., H - 1.]), np.array([1., 0.])),
           'trai': (np.array([0., 0.]), np.array([0., 1.])),
           'phai': (np.array([W - 1., 0.]), np.array([0., 1.]))}
    canh_thieu = [t for t, v in canh.items() if v is None]
    for t in canh_thieu:
        canh[t] = mep[t]
    goc_q = [_giao_diem(canh['tren'], canh['trai']), _giao_diem(canh['tren'], canh['phai']),
             _giao_diem(canh['duoi'], canh['phai']), _giao_diem(canh['duoi'], canh['trai'])]
    dt_mask = float((mask > 0).sum())
    if all(g is not None for g in goc_q):
        q = np.array(goc_q, np.float32)
        if _quad_hop_le(q, W, H, dt_mask):
            return dict(quad=q / s, ty_le=ty_le, cham_bien=cham_bien or bool(canh_thieu),
                        nguon='mau_giay_hough', canh_thieu=canh_thieu)

    # dự phòng: xấp xỉ đa giác lồi 4 đỉnh
    hull = cv2.convexHull(tt['contour'])
    peri = cv2.arcLength(hull, True)
    for eps in np.arange(0.010, 0.12, 0.004):
        ap = cv2.approxPolyDP(hull, eps * peri, True)
        if len(ap) == 4:
            q = _sap_xep_4_goc(ap.reshape(4, 2))
            if _quad_hop_le(q, W, H, dt_mask):
                return dict(quad=q / s, ty_le=ty_le, cham_bien=cham_bien, nguon='mau_giay_da_giac',
                            canh_thieu=canh_thieu)
            break
    q = _sap_xep_4_goc(cv2.boxPoints(cv2.minAreaRect(hull)))
    return dict(quad=q / s, ty_le=ty_le, cham_bien=cham_bien, nguon='mau_giay_hop_bao',
                canh_thieu=canh_thieu)



def H_ve_a4(quad):
    dst = np.array([[0, 0], [A4[0] - 1, 0], [A4[0] - 1, A4[1] - 1], [0, A4[1] - 1]], np.float32)
    return cv2.getPerspectiveTransform(np.asarray(quad, np.float32), dst).astype(np.float64)



def _nhi_phan(page):
    g = cv2.createCLAHE(2.0, (8, 8)).apply(cv2.cvtColor(page, cv2.COLOR_BGR2GRAY))
    return cv2.adaptiveThreshold(g, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                 cv2.THRESH_BINARY_INV, 41, 13)



def _do_vach(bw, huong, nhan_mo=41, dai_toi_thieu=250, bien=0.015):
    """Các vạch kẻ dài theo một hướng, mỗi vạch khớp thành đường thẳng.

    huong='ngang': y = a·x + b ; huong='doc': x = a·y + b.
    Mỗi phần tử: dict(a, b, t0, t1, dai, rms, t, v) với (t, v) là tâm vạch theo
    từng cột (ngang) / từng hàng (dọc) — dùng lại khi đo độ cong.
    """
    Hh, Ww = bw.shape
    k = cv2.getStructuringElement(cv2.MORPH_RECT, (nhan_mo, 1) if huong == 'ngang' else (1, nhan_mo))
    m = cv2.morphologyEx(bw, cv2.MORPH_OPEN, k)
    n, nhan, st, _ = cv2.connectedComponentsWithStats(m, connectivity=8)
    ra = []
    gioi_han = Hh if huong == 'ngang' else Ww
    for i in range(1, n):
        x, y, w, h, _ = st[i]
        if (w if huong == 'ngang' else h) < dai_toi_thieu:
            continue
        ys, xs = np.nonzero(nhan[y:y + h, x:x + w] == i)
        if huong == 'ngang':
            t, v = xs + x, ys + y
        else:
            t, v = ys + y, xs + x
        tu, inv = np.unique(t, return_inverse=True)
        dem = np.bincount(inv)
        vm = np.bincount(inv, weights=v) / dem
        tt = tu.astype(np.float64)
        giu = np.ones(len(tt), bool)
        p = None
        for _ in range(3):
            if giu.sum() < 30:
                break
            p = np.polyfit(tt[giu], vm[giu], 1)
            du = vm - np.polyval(p, tt)
            sd = 1.4826 * float(np.median(np.abs(du[giu]))) + 0.3
            giu = np.abs(du) < max(1.5, 3.0 * sd)
        if p is None or giu.sum() < 30:
            continue
        p = np.polyfit(tt[giu], vm[giu], 1)
        du = vm[giu] - np.polyval(p, tt[giu])
        t0, t1 = float(tt[giu].min()), float(tt[giu].max())
        v_giua = float(np.polyval(p, (t0 + t1) / 2))
        if v_giua < bien * gioi_han or v_giua > (1 - bien) * gioi_han:
            continue                                        # mép giấy / mép trang
        if abs(p[0]) > np.tan(np.radians(12)):
            continue
        ra.append(dict(a=float(p[0]), b=float(p[1]), t0=t0, t1=t1, dai=t1 - t0,
                       rms=float(np.sqrt(np.mean(du ** 2))), t=tt[giu], v=vm[giu]))
    return ra



def _diem_tu(vach, huong, cx, cy, S=1000.0):
    """Điểm tụ (toạ độ thuần nhất, đã chuẩn hoá quanh tâm trang) của một họ vạch."""
    L, w = [], []
    for d in vach:
        a, b = d['a'], d['b']
        if huong == 'ngang':      # a·x − y + b = 0
            l = np.array([a, -1.0, (a * cx + b - cy) / S])
        else:                     # −x + a·y + b = 0
            l = np.array([-1.0, a, (a * cy + b - cx) / S])
        L.append(l / np.hypot(l[0], l[1]))
        w.append(d['dai'] / (1.0 + d['rms']))
    L, w = np.array(L), np.array(w)
    giu = np.ones(len(L), bool)
    v = None
    for _ in range(4):
        M = (L[giu] * w[giu, None]).T @ L[giu]
        _, vec = np.linalg.eigh(M)
        v = vec[:, 0]
        du = np.abs(L @ v) / (np.linalg.norm(v) + 1e-12)
        giu2 = du <= max(3.0 * float(np.median(du[giu])), 2e-4)
        if giu2.sum() < max(2, int(0.5 * len(L))) or (giu2 == giu).all():
            break
        giu = giu2
    return v, giu



def _H_nan_theo_diem_tu(vp_ngang, vp_doc):
    """Homography (toạ độ chuẩn hoá) đưa 2 điểm tụ về vô cực theo trục x, y."""
    l = np.cross(vp_ngang, vp_doc)
    if abs(l[2]) < 1e-12:
        return None
    l = l / l[2]
    Hp = np.array([[1, 0, 0], [0, 1, 0], [l[0], l[1], 1.0]])
    dn = (Hp @ vp_ngang)[:2]
    dd = (Hp @ vp_doc)[:2]
    if np.linalg.norm(dn) < 1e-12 or np.linalg.norm(dd) < 1e-12:
        return None
    if dn[0] < 0:
        dn = -dn
    if dd[1] < 0:
        dd = -dd
    B = np.column_stack([dn / np.linalg.norm(dn), dd / np.linalg.norm(dd)])
    if abs(np.linalg.det(B)) < 0.5:          # hai họ vạch gần song song nhau: vô lý
        return None
    Ha = np.eye(3)
    Ha[:2, :2] = np.linalg.inv(B)
    return Ha @ Hp, float(np.hypot(l[0], l[1]))



def _H_chinh_theo_luoi(page, nhan_ngang=41, nhan_doc=41):
    """Một vòng nắn tinh theo vạch kẻ bảng. Trả (H 3x3 trên toạ độ trang | None, info)."""
    bw = _nhi_phan(page)
    Hh, Ww = bw.shape
    vn = _do_vach(bw, 'ngang', nhan_mo=nhan_ngang, dai_toi_thieu=int(0.25 * Ww))
    vd = _do_vach(bw, 'doc', nhan_mo=nhan_doc, dai_toi_thieu=100)
    info = dict(so_vach_ngang=len(vn), so_vach_doc=len(vd))
    if len(vn) < 2 or len(vd) < 2:
        info['ly_do'] = 'không đủ vạch kẻ'
        return None, info
    cx, cy, S = Ww / 2.0, Hh / 2.0, 1000.0
    vp_n, giu_n = _diem_tu(vn, 'ngang', cx, cy, S)
    vp_d, giu_d = _diem_tu(vd, 'doc', cx, cy, S)
    vn_g = [d for d, g in zip(vn, giu_n) if g]
    vd_g = [d for d, g in zip(vd, giu_d) if g]
    # Họ vạch ngắn/ít (trang sau chỉ 3 dòng) không đo nổi độ hội tụ -> coi như song song
    # (điểm tụ ở vô cực theo hướng trung bình), tránh khuếch đại nhiễu thành phối cảnh ảo.
    def ve_vo_cuc(vach, huong):
        w = np.array([d['dai'] for d in vach])
        a = float(np.sum(w * np.array([d['a'] for d in vach])) / w.sum())
        return np.array([1.0, a, 0.0]) if huong == 'ngang' else np.array([a, 1.0, 0.0])
    phoi_canh = True
    if len(vn_g) < 4 or max(d['dai'] for d in vn_g) < 600:
        vp_n, phoi_canh = ve_vo_cuc(vn_g, 'ngang'), False
    if len(vd_g) < 3 or max(d['dai'] for d in vd_g) < 450:
        vp_d, phoi_canh = ve_vo_cuc(vd_g, 'doc'), False
    kq = _H_nan_theo_diem_tu(vp_n, vp_d)
    if kq is None:
        info['ly_do'] = 'điểm tụ suy biến'
        return None, info
    Hn, do_lon_pc = kq
    if do_lon_pc > 0.25:                     # phối cảnh ảo quá mạnh -> chỉ nắn affine
        kq = _H_nan_theo_diem_tu(ve_vo_cuc(vn_g, 'ngang'), ve_vo_cuc(vd_g, 'doc'))
        if kq is None:
            return None, info
        Hn, do_lon_pc = kq
        phoi_canh = False
    Nm = np.array([[1 / S, 0, -cx / S], [0, 1 / S, -cy / S], [0, 0, 1]])
    Hpx = np.linalg.inv(Nm) @ Hn @ Nm

    # Giữ nguyên vị trí + kích thước bảng: 4 góc bảng = giao 2 vạch ngang ngoài cùng
    # với 2 vạch dọc ngoài cùng.
    vn_g.sort(key=lambda d: d['a'] * cx + d['b'])
    vd_g.sort(key=lambda d: d['a'] * cy + d['b'])
    def giao(dn, dd):
        a1, b1, a2, b2 = dn['a'], dn['b'], dd['a'], dd['b']
        y = (a1 * b2 + b1) / (1.0 - a1 * a2)
        return np.array([a2 * y + b2, y])
    tren, duoi, trai, phai = vn_g[0], vn_g[-1], vd_g[0], vd_g[-1]
    C0 = np.array([giao(tren, trai), giao(tren, phai), giao(duoi, phai), giao(duoi, trai)])
    C1 = cv2.perspectiveTransform(C0[None], Hpx)[0]
    w0 = (np.linalg.norm(C0[1] - C0[0]) + np.linalg.norm(C0[2] - C0[3])) / 2
    h0 = (np.linalg.norm(C0[3] - C0[0]) + np.linalg.norm(C0[2] - C0[1])) / 2
    w1 = ((C1[1, 0] - C1[0, 0]) + (C1[2, 0] - C1[3, 0])) / 2
    h1 = ((C1[3, 1] - C1[0, 1]) + (C1[2, 1] - C1[1, 1])) / 2
    if w0 < 50 or h0 < 20 or w1 < 50 or h1 < 20:
        info['ly_do'] = 'bảng quá nhỏ'
        return None, info
    sx, sy = w0 / w1, h0 / h1
    t0, t1 = C0.mean(0), C1.mean(0)
    Hs = np.array([[sx, 0, t0[0] - sx * t1[0]], [0, sy, t0[1] - sy * t1[1]], [0, 0, 1]])
    Hf = Hs @ Hpx
    goc = float(np.degrees(np.arctan2(np.sum([d['a'] * d['dai'] for d in vn_g]),
                                      np.sum([d['dai'] for d in vn_g]))))
    info.update(vach_ngang_dung=len(vn_g), vach_doc_dung=len(vd_g), phoi_canh=phoi_canh,
                goc_ngang_do=round(goc, 3))
    return Hf, info



def nan_theo_luoi(img, H0):
    """Lặp nắn tinh theo lưới bảng, bắt đầu từ H0 (ảnh gốc -> trang A4)."""
    H = np.asarray(H0, np.float64)
    nhat_ky, goc_dau = [], None
    moc = np.array([[[150., 450.], [1500., 450.], [1500., 2250.], [150., 2250.]]])
    for vong in range(SO_VONG_NAN):
        page = cv2.warpPerspective(img, H, A4, flags=cv2.INTER_LINEAR,
                                   borderMode=cv2.BORDER_CONSTANT, borderValue=MAU_VIEN)
        Hf, info = _H_chinh_theo_luoi(page, nhan_ngang=41 if vong == 0 else 61)
        if Hf is None:
            nhat_ky.append(info)
            break
        dich = float(np.abs(cv2.perspectiveTransform(moc, Hf) - moc).max())
        info['dich_px'] = round(dich, 2)
        nhat_ky.append(info)
        if dich > 250:                        # vòng nắn làm biến dạng quá lớn -> bỏ
            info['ly_do'] = 'dịch chuyển quá lớn, bỏ vòng này'
            break
        if goc_dau is None:
            goc_dau = info.get('goc_ngang_do', 0.0)
        H = Hf @ H
        if dich < 0.3:
            break
    return H, dict(vong=nhat_ky, goc_xien_bu=round(goc_dau or 0.0, 3))



def _mau_trung_vi(t, v, buoc=32.0):
    """Gom tâm vạch theo từng khung buoc px -> (toạ độ khung, trung vị)."""
    k = np.floor(t / buoc).astype(np.int64)
    ra_t, ra_v = [], []
    for kk in np.unique(k):
        chon = k == kk
        if chon.sum() >= 0.4 * buoc:
            ra_t.append(float(t[chon].mean()))
            ra_v.append(float(np.median(v[chon])))
    if len(ra_v) >= 3:                                  # làm trơn 3 điểm
        vv = np.array(ra_v)
        tron = vv.copy()
        tron[1:-1] = (vv[:-2] + 2 * vv[1:-1] + vv[2:]) / 4.0
        ra_v = tron.tolist()
    return np.array(ra_t), np.array(ra_v)



def _truong_lech(page, buoc=16, doan_mo=150.0):
    """Đo độ cong còn lại của vạch kẻ -> trường lệch (dx, dy) cỡ trang, hoặc None."""
    bw = _nhi_phan(page)
    Hh, Ww = bw.shape
    nx, ny = Ww // buoc, Hh // buoc
    xc = (np.arange(nx) + 0.5) * Ww / nx - 0.5        # tâm ô lưới thô (khớp quy ước cv2.resize)
    yc = (np.arange(ny) + 0.5) * Hh / ny - 0.5

    def lay_duong(huong):
        vach = _do_vach(bw, huong, nhan_mo=61,
                        dai_toi_thieu=int(0.35 * Ww) if huong == 'ngang' else 150)
        ra = []
        for d in vach:
            tk, vk = _mau_trung_vi(d['t'], d['v'])
            if len(tk) < 5:
                continue
            goc = float(np.median(vk))
            lech = vk - goc
            if np.abs(lech).max() > LECH_CONG_TOI_DA:
                continue
            ra.append((goc, tk, lech))
        ra.sort(key=lambda r: r[0])
        # loại vạch có dạng cong khác hẳn hai vạch kề (vạch lạ, nét gạch tay...)
        tot = []
        for i, (goc, tk, lech) in enumerate(ra):
            ke = [ra[j] for j in (i - 1, i + 1) if 0 <= j < len(ra)]
            if ke:
                sai = [float(np.sqrt(np.mean((lech - np.interp(tk, r[1], r[2])) ** 2))) for r in ke]
                if min(sai) > 3.0:
                    continue
            tot.append((goc, tk, lech))
        return tot

    ngang = lay_duong('ngang')
    doc = lay_duong('doc')

    def dung_truong(duong, truc_doc, truc_ngang):
        """duong: [(vị trí, t_mẫu, lệch)]; nội suy theo truc_doc (hướng vuông góc vạch)
        tại mỗi toạ độ truc_ngang (dọc theo vạch)."""
        F = np.full((len(truc_doc), len(truc_ngang)), np.nan, np.float32)
        if len(duong) < 2:
            return None
        for j, t in enumerate(truc_ngang):
            vt, gt = [], []
            for goc, tk, lech in duong:
                if tk[0] - 48 <= t <= tk[-1] + 48:
                    vt.append(goc)
                    gt.append(float(np.interp(t, tk, lech)))
            if len(vt) < 2:
                continue
            vt, gt = np.array(vt), np.array(gt)
            col = np.interp(truc_doc, vt, gt)
            tren = truc_doc < vt[0]
            duoi = truc_doc > vt[-1]
            col[tren] *= np.clip(1.0 - (vt[0] - truc_doc[tren]) / doan_mo, 0.0, 1.0)
            col[duoi] *= np.clip(1.0 - (truc_doc[duoi] - vt[-1]) / doan_mo, 0.0, 1.0)
            F[:, j] = col
        co = np.where(np.isfinite(F[0]))[0]
        if len(co) == 0:
            return None
        for j in range(len(truc_ngang)):                   # cột thiếu -> lấy cột gần nhất, giảm dần
            if not np.isfinite(F[0, j]):
                jj = co[np.argmin(np.abs(co - j))]
                kc = abs(truc_ngang[jj] - truc_ngang[j])
                F[:, j] = F[:, jj] * max(0.0, 1.0 - kc / doan_mo)
        return F

    Fy = dung_truong(ngang, yc, xc)                         # (ny, nx): lệch dọc do vạch ngang cong
    Fx = dung_truong(doc, xc, yc)                           # (nx, ny): lệch ngang do vạch dọc cong
    if Fy is None and Fx is None:
        return None
    dy = cv2.resize(Fy, (Ww, Hh), interpolation=cv2.INTER_LINEAR) if Fy is not None \
        else np.zeros((Hh, Ww), np.float32)
    dx = cv2.resize(Fx.T.copy(), (Ww, Hh), interpolation=cv2.INTER_LINEAR) if Fx is not None \
        else np.zeros((Hh, Ww), np.float32)
    np.clip(dx, -LECH_CONG_TOI_DA, LECH_CONG_TOI_DA, out=dx)
    np.clip(dy, -LECH_CONG_TOI_DA, LECH_CONG_TOI_DA, out=dy)
    return dict(dx=dx, dy=dy, so_vach_ngang=len(ngang), so_vach_doc=len(doc),
                lech_max=round(float(max(np.abs(dx).max(), np.abs(dy).max())), 2))



def nan_anh(img, H, truong=None):
    """Nắn ảnh gốc về trang A4 trong MỘT lần nội suy: homography H (+ trường lệch)."""
    if truong is None:
        return cv2.warpPerspective(img, H, A4, flags=cv2.INTER_LINEAR,
                                   borderMode=cv2.BORDER_CONSTANT, borderValue=MAU_VIEN)
    Ww, Hh = A4
    px = truong['dx'] + np.arange(Ww, dtype=np.float32)[None, :]      # toạ độ trên trang đã nắn homography
    py = truong['dy'] + np.arange(Hh, dtype=np.float32)[:, None]
    Hi = np.linalg.inv(H).astype(np.float32)                           # trang -> ảnh gốc
    den = Hi[2, 0] * px + Hi[2, 1] * py + Hi[2, 2]
    mx = (Hi[0, 0] * px + Hi[0, 1] * py + Hi[0, 2]) / den
    my = (Hi[1, 0] * px + Hi[1, 1] * py + Hi[1, 2]) / den
    del px, py, den
    return cv2.remap(img, mx.astype(np.float32), my.astype(np.float32), interpolation=cv2.INTER_LINEAR,
                     borderMode=cv2.BORDER_CONSTANT, borderValue=MAU_VIEN)



def _diem_luoi_tho(page):
    """Chất lượng lưới bảng trên trang đã nắn, KHÔNG dùng kích thước mẫu E0330113.

    Dùng cho ảnh bảng điểm mẫu lạ: chỉ cần vạch kẻ nhiều, dài và đã thẳng hàng.
    """
    bw = _nhi_phan(page)
    Ww = bw.shape[1]
    vn = _do_vach(bw, 'ngang', nhan_mo=61, dai_toi_thieu=int(0.30 * Ww))
    vd = _do_vach(bw, 'doc', nhan_mo=61, dai_toi_thieu=200)
    if len(vn) < 3 or len(vd) < 2:
        return -1.0, dict(so_vach_ngang=len(vn), so_vach_doc=len(vd))
    goc = float(np.median([abs(d['a']) for d in vn] + [abs(d['a']) for d in vd]))
    cong = float(np.median([d['rms'] for d in vn] + [d['rms'] for d in vd]))
    diem = min(len(vn), 45) + 2.0 * min(len(vd), 15) - 400.0 * goc - 8.0 * cong
    return float(diem), dict(so_vach_ngang=len(vn), so_vach_doc=len(vd),
                             goc_con_lai_do=round(float(np.degrees(np.arctan(goc))), 3),
                             do_cong_px=round(cong, 2))



def nan_trang(img, nan_cong=True):
    """Nắn ảnh về trang A4 chuẩn cho BẢNG ĐIỂM BẤT KỲ (không cần đúng mẫu E0330113).

    Dùng chung khâu dò giấy + nắn theo lưới + nắn cong của v3, nhưng chấm điểm
    phương án bằng chất lượng lưới chung (số vạch, độ thẳng) thay vì khớp kích
    thước cột của biểu mẫu. Trả dict(page, H, nguon_quad, ty_le, cham_bien,
    canh_thieu, goc_xien_bu, thong_so).
    """
    h, w = img.shape[:2]
    ung_vien = []
    gi = do_to_giay_chi_tiet(img)
    ung_vien.append((gi['nguon'], gi['quad'], gi))
    tot = None
    for nguon, quad, gi in ung_vien:
        try:
            H, info_nan = nan_theo_luoi(img, H_ve_a4(quad))
            page = nan_anh(img, H)
        except Exception:
            continue
        diem, ts = _diem_luoi_tho(page)
        pa = dict(page=page, H=H, nguon_quad=nguon, giay=gi, diem=diem, thong_so=ts,
                  info_nan=info_nan, nan_cong=False)
        if nan_cong and diem > 0:
            try:
                truong = _truong_lech(page)
            except Exception:
                truong = None
            if truong is not None and truong['lech_max'] >= 0.75:
                page2 = nan_anh(img, H, truong)
                d2, ts2 = _diem_luoi_tho(page2)
                if d2 >= diem:
                    pa = dict(page=page2, H=H, nguon_quad=nguon, giay=gi, diem=d2, thong_so=ts2,
                              info_nan=info_nan, nan_cong=True, lech_cong_max=truong['lech_max'])
        if tot is None or pa['diem'] > tot['diem']:
            tot = pa
        if tot['diem'] > 25:              # lưới đã rõ, không cần thử phương án khác
            break
    if tot is None:
        raise PipelineError(
            'GRID_NOT_FOUND', 'Không nắn được ảnh về trang A4 — kiểm tra lại ảnh đầu vào.'
        )
    gi = tot['giay']
    q = np.asarray(gi.get('quad'), np.float32) if gi.get('quad') is not None else None
    ty_le_quad = float(cv2.contourArea(q) / float(h * w)) if q is not None else 0.0
    nghieng, meo = _do_tu_the_giay(q)
    return dict(page=tot['page'], H=tot['H'], nguon_quad=tot['nguon_quad'],
                ty_le=float(gi.get('ty_le') or 0.0), ty_le_quad=round(ty_le_quad, 3),
                cham_bien=bool(gi.get('cham_bien')),
                canh_thieu=gi.get('canh_thieu', []),
                goc_xien_bu=tot['info_nan'].get('goc_xien_bu', 0.0),
                quad=q.tolist() if q is not None else None,
                goc_nghieng_giay=nghieng, meo_phoi_canh=meo,
                nan_cong_cuc_bo=tot['nan_cong'], diem_luoi=round(tot['diem'], 1),
                thong_so=tot['thong_so'])



def _do_tu_the_giay(quad):
    """Tư thế tờ giấy trong ảnh gốc -> (góc nghiêng độ, độ méo phối cảnh 0..1).

    - góc nghiêng: tờ giấy bị xoay bao nhiêu độ so với phương ngang (xoay trong mặt
      phẳng ảnh — cầm máy lệch tay).
    - méo phối cảnh: chụp chéo làm hai cạnh đối diện dài ngắn khác nhau; 0 = chụp
      vuông góc, càng lớn càng nghiêng máy.
    """
    if quad is None or len(quad) != 4:
        return 0.0, 0.0
    p = np.asarray(quad, np.float64)
    tren, phai, duoi, trai = p[1] - p[0], p[2] - p[1], p[2] - p[3], p[3] - p[0]

    def goc_ngang(v):
        a = math.degrees(math.atan2(v[1], v[0]))
        while a > 45:
            a -= 90
        while a < -45:
            a += 90
        return a
    nghieng = float(np.mean([goc_ngang(tren), goc_ngang(duoi)]))
    d = [float(np.linalg.norm(v)) for v in (tren, duoi, trai, phai)]
    meo = max(abs(d[0] - d[1]) / max(d[0], d[1], 1.0),
              abs(d[2] - d[3]) / max(d[2], d[3], 1.0))
    return round(nghieng, 2), round(float(meo), 3)
