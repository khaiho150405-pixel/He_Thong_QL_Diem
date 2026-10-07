"""Dò lưới bảng cho MẪU BẢNG ĐIỂM BẤT KỲ và định danh cột bằng chữ in ở hàng tiêu đề.

Nguồn gốc: label_tool/luoi_tong_quat.py. Giữ nguyên thuật toán và tên Việt hóa của các hàm:
``bo_dau``, ``khop_tu_khoa`` (+ ``_luat_vai_tro``), ``_doan_vach``, ``_gop_vach``, ``_cum_bang``, ``trich_luoi``,
``cot_cua_hang``, ``cat_o``, ``doc_hang_tieu_de``, ``dinh_danh_cot``, ``chon_cot_diem``,
``kiem_tra_la_bang_diem``.

Khác bản gốc:
- OCR tiêu đề nhận qua tham số hàm (``ocr_ham``: ảnh xám -> chuỗi). Module này KHÔNG import easyocr/tesseract/vietocr
  và không tải gì từ mạng; không có OCR thì dùng đường lui hình học (``chon_cot_diem_hinh_hoc``).
- Từ khóa tiêu đề cấp 3: ``ma_hs`` (mahs, mahocsinh), ``diem_qua_trinh`` (kiemtra15phut, mieng, ddgtx),
  ``diem_so`` (ddggk, ddgck, giuaky, cuoiky), ``ho_ten`` (hotenhocsinh). "Điểm giữa kỳ" chuyển từ
  ``diem_qua_trinh`` sang ``diem_so`` theo quy ước cấp 3 (cột điểm giữa kỳ/cuối kỳ là cột điểm chính).
- Bỏ ``chu_ky_mau``/``so_sanh_chu_ky`` (đối chiếu hai mặt của một tờ, ngoài phạm vi).
- THAY ĐỔI THUẬT TOÁN (chủ dự án chốt ở BE-16, ADR-0015): ``trich_luoi`` dựng bảng từ các vạch DỌC cột trước
  (``_luoi_theo_vach_doc``: ≥ 4 vạch dọc cùng khoảng y xác định khoảng y/bề ngang của bảng, vạch ngang được nhận theo
  độ phủ cộng dồn của các đoạn nằm trong khoảng đó, chỉ cần ≥ 3 vạch ngang) rồi mới quay về thuật toán gốc
  (``_trich_luoi_goc``: cụm ≥ 4 vạch ngang suốt bề ngang). Lý do: trang cuối của lớp chỉ có tiêu đề + vài dòng nên
  thuật toán gốc không tìm thấy bảng (``GRID_NOT_FOUND``). Tệp này vì vậy không còn sinh lại được từ bản gốc bằng
  script trích xuất; sửa trực tiếp ở đây.
- Lỗi trả bằng ``PipelineError``: ``GRID_NOT_FOUND``, ``NOT_A_GRADEBOOK``, ``SCORE_COLUMN_NOT_FOUND``
  (xem ``phat_hien_luoi``, ``bao_dam_la_bang_diem``, ``chon_cot_diem_bat_buoc``).
"""
from __future__ import annotations

import difflib
import re
import unicodedata

import cv2
import numpy as np

from .errors import PipelineError
from .page import A4, PX_MM, _do_vach, _nhi_phan  # noqa: F401  (A4 giữ để đối chiếu với bản gốc)

# ── Từ khoá tiêu đề (đã bỏ dấu, bỏ khoảng trắng) ─────────────────────────────
TU_KHOA = {
    'diem_so':        ['dtk', 'diemtk', 'diemtongket', 'dso', 'diemso', 'diemthi', 'diemck',
                       'diemcuoiky', 'diemtb', 'diemtrungbinh', 'tbmh', 'diemketthuc',
                       # cấp 3
                       'ddggk', 'ddgck', 'giuaky', 'diemgiuaky', 'cuoiky'],
    'diem_chu':       ['diemchu', 'bangchu', 'diembangchu', 'ghibangchu'],
    'diem_qua_trinh': ['diemquatrinh', 'diemthanhphan', 'diemtp', 'diemqt', 'diemthuongky',
                       'diemkiemtra', 'diemkt', 'diemchuyencan',
                       # cấp 3
                       'kiemtra15phut', 'mieng', 'ddgtx'],
    'stt':            ['stt', 'sott', 'tt'],
    'ma_sv':          ['masv', 'mssv', 'masosv', 'maso', 'masinhvien'],
    'ma_hs':          ['mahs', 'mahocsinh'],
    'ho_ten':         ['hovaten', 'hoten', 'hovatendem', 'hovatenlot', 'tensinhvien', 'hotenhocsinh'],
    'ngay_sinh':      ['ngsinh', 'ngaysinh', 'ngythsinh'],
    'lop':            ['tenlop', 'malop', 'lop', 'lophoc'],
    'ky_ten':         ['kyten', 'chuky', 'kytensv'],
    'ghi_chu':        ['ghichu', 'ghichep'],
}
VAI_TRO_DIEM = ('diem_so', 'diem_qua_trinh')
NGUONG_GIONG = 0.76          # ngưỡng giống nhau tối thiểu khi khớp mờ



# ═══════════════════════ 1. Chuẩn hoá & khớp từ khoá ═══════════════════════
def bo_dau(s):
    """'Điểm Chữ' -> 'diemchu' (bỏ dấu, bỏ khoảng trắng và ký tự lạ)."""
    if not s:
        return ''
    s = unicodedata.normalize('NFD', str(s))
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    s = s.replace('Đ', 'D').replace('đ', 'd').replace('Ð', 'D').replace('ð', 'd')
    s = unicodedata.normalize('NFC', s).lower()
    return re.sub(r'[^a-z0-9]', '', s)


# Nhầm lẫn chữ/số hay gặp của OCR: "Đ.số" -> "D.s6", "Điểm" -> "Dlém"
_LEET = str.maketrans('0163458', 'oibeasg')
_DAU_DIEM = ('diem', 'dlem', 'diern', 'dienm', 'dtem', 'dem', 'dinm', 'dim')


def _duoi_sau_diem(t):
    """Bỏ chữ 'điểm' ở đầu -> phần đuôi ('chu', 'so', 'quatrinh'...) hoặc None."""
    for p in _DAU_DIEM:
        if t.startswith(p):
            return t[len(p):]
    if t.startswith('d') and len(t) <= 6:          # 'dtk', 'dso', 'dsd', 'ds6'...
        return t[1:]
    return None


def _luat_vai_tro(t):
    """Luật đọc tiêu đề cột điểm — chịu được lỗi OCR, chạy TRƯỚC khớp mờ."""
    t = t.translate(_LEET)
    duoi = _duoi_sau_diem(t)
    if duoi is None:
        return None, 0.0
    if duoi.startswith('ch') or duoi.startswith('bangchu') or duoi.startswith('chu'):
        return 'diem_chu', 0.95                                   # Điểm chữ / bằng chữ
    for k in ('quatrinh', 'thanhphan', 'thuongky', 'chuyencan', 'kiemtra'):
        if k in duoi:
            return 'diem_qua_trinh', 0.95
    if duoi in ('qt', 'tp', 'kt', 'tx') or duoi.startswith('qt'):
        return 'diem_qua_trinh', 0.9
    if duoi.startswith('tk') or 'tongket' in duoi or duoi.startswith('tb') or 'trungbinh' in duoi:
        return 'diem_so', 0.95                                    # ĐTK / điểm trung bình
    if duoi.startswith('so') or 'sothap' in duoi:
        return 'diem_so', 0.95                                    # Đ.số / Điểm số
    if duoi.startswith('thi') or duoi.startswith('ck') or 'cuoiky' in duoi or 'ketthuc' in duoi:
        return 'diem_so', 0.9
    if duoi[:1] == 's' and len(duoi) <= 3:                        # 'sd', 's6' — OCR hỏng của 'số'
        return 'diem_so', 0.85
    return None, 0.0



def khop_tu_khoa(text, nguong=NGUONG_GIONG):
    """Khớp chuỗi OCR với bảng từ khoá -> (vai_tro, do_giong) hoặc (None, 0)."""
    t = bo_dau(text)
    if len(t) < 2:
        return None, 0.0
    tot = _luat_vai_tro(t)
    if tot[0] is None:                       # thử từng từ (ô tiêu đề nhiều dòng/chữ)
        for tu in re.split(r'[\s/|,;:.]+', str(text)):
            r = _luat_vai_tro(bo_dau(tu))
            if r[1] > tot[1]:
                tot = (r[0], r[1] * 0.95)
    if tot[0] is not None:
        return tot
    for vai_tro, ds in TU_KHOA.items():
        for k in ds:
            if k in t:                                   # khớp thẳng
                diem = 1.0 if len(t) <= len(k) + 4 else 0.92
            else:
                diem = difflib.SequenceMatcher(None, t, k).ratio()
                if len(t) > len(k) + 2:                  # khớp cửa sổ trượt (tiêu đề dài)
                    for i in range(0, len(t) - len(k) + 1):
                        diem = max(diem, difflib.SequenceMatcher(None, t[i:i + len(k)], k).ratio())
                if diem < nguong or len(k) < 3:
                    continue
                diem *= 0.9
            # từ khoá dài khớp được thì tin hơn từ khoá ngắn
            diem += 0.01 * len(k)
            if diem > tot[1]:
                tot = (vai_tro, diem)
    return tot



def _anh_cho_ocr(o, phong=2.0):
    """Ô tiêu đề -> ảnh xám phóng to, tăng tương phản cho OCR chữ in nhỏ."""
    if o is None or o.size == 0:
        return None
    g = cv2.cvtColor(o, cv2.COLOR_BGR2GRAY) if o.ndim == 3 else o
    if min(g.shape[:2]) < 8:
        return None
    g = cv2.resize(g, None, fx=phong, fy=phong, interpolation=cv2.INTER_CUBIC)
    g = cv2.createCLAHE(2.0, (8, 8)).apply(g)
    return cv2.copyMakeBorder(g, 8, 8, 8, 8, cv2.BORDER_CONSTANT, value=255)



# ═══════════════════════════ 3. Trích lưới bảng ════════════════════════════
def _doan_vach(bw, huong, nhan_mo=41, dai_toi_thieu=120):
    """Vạch kẻ -> list dict(vi_tri, t0, t1, dai) (vi_tri = y nếu ngang, x nếu dọc)."""
    ra = []
    for d in _do_vach(bw, huong, nhan_mo=nhan_mo, dai_toi_thieu=dai_toi_thieu, bien=0.004):
        giua = d['a'] * (d['t0'] + d['t1']) / 2.0 + d['b']
        ra.append(dict(vi_tri=float(giua), t0=d['t0'], t1=d['t1'], dai=d['dai'], a=d['a']))
    return sorted(ra, key=lambda d: d['vi_tri'])


def _gop_vach(vach, sai_vi_tri=7.0, khe_toi_da=90.0):
    """Gộp vạch trùng vị trí (vạch đứt đoạn, vạch kẻ đúp) thành một vạch dài."""
    ra = []
    for v in sorted(vach, key=lambda d: d['vi_tri']):
        gop = None
        for u in ra:
            if abs(u['vi_tri'] - v['vi_tri']) <= sai_vi_tri and \
               v['t0'] <= u['t1'] + khe_toi_da and u['t0'] <= v['t1'] + khe_toi_da:
                gop = u
                break
        if gop is None:
            ra.append(dict(v))
        else:
            tong = gop['dai'] + v['dai']
            gop['vi_tri'] = (gop['vi_tri'] * gop['dai'] + v['vi_tri'] * v['dai']) / max(tong, 1e-6)
            gop['t0'] = min(gop['t0'], v['t0'])
            gop['t1'] = max(gop['t1'], v['t1'])
            gop['dai'] = gop['t1'] - gop['t0']
    return sorted(ra, key=lambda d: d['vi_tri'])


def _cum_bang(ngang, rong_trang):
    """Chọn cụm vạch ngang cùng bề ngang -> thân bảng (các dòng của bảng)."""
    dai = [v for v in ngang if v['dai'] >= 0.25 * rong_trang]
    if len(dai) < 4:
        return None
    tot = None
    for moc in dai:                                   # thử từng vạch làm chuẩn bề ngang
        nhom = [v for v in dai
                if abs(v['t0'] - moc['t0']) < 0.06 * rong_trang and
                   abs(v['t1'] - moc['t1']) < 0.06 * rong_trang]
        if len(nhom) < 4:
            continue
        diem = len(nhom) * float(np.mean([v['dai'] for v in nhom]))
        if tot is None or diem > tot[0]:
            tot = (diem, nhom)
    return tot[1] if tot else None


# ── THAY ĐỔI SO VỚI THUẬT TOÁN GỐC (chủ dự án chốt cho BE-16, ADR-0015) ──────────────────────────────────────
# Bản gốc chỉ nhận bảng khi có ≥ 4 vạch ngang suốt bề ngang cùng nằm trong một cụm (``_cum_bang``). Trang cuối
# của một lớp chỉ có tiêu đề + vài dòng nên chỉ còn 4–5 vạch ngang, thường đứt thành nhiều đoạn (chữ in/viết đè lên
# vạch) → không có cụm bảng → ``GRID_NOT_FOUND``; hoặc lấy nhầm vạch ngoài bảng → thừa/thiếu dòng.
# ``_luoi_theo_vach_doc`` đảo thứ tự suy luận: các vạch DỌC cột đủ dài cùng khoảng y xác định khoảng y và bề ngang
# của bảng (≥ 4 vạch dọc), rồi nhận vạch ngang NẰM TRONG khoảng đó theo độ phủ cộng dồn của các đoạn (không đòi một
# đoạn liền suốt bề ngang) — nên chỉ cần ≥ 3 vạch ngang. Mép trên/dưới bảng được suy từ đầu mút các vạch dọc khi
# thiếu. Không tìm được theo cách này thì quay về thuật toán gốc (``_trich_luoi_goc``).
PHU_NGANG_TOI_THIEU = 0.55      # độ phủ cộng dồn tối thiểu của một vạch ngang trên bề ngang bảng
SO_VACH_DOC_TOI_THIEU = 4       # số vạch dọc cùng khoảng y để coi là một bảng


def _nhom_vach_doc(doc, W, H):
    """Nhóm ≥ 4 vạch dọc cùng khoảng y (±1.2% chiều cao trang), trải ≥ 25% bề ngang trang."""
    dung_sai = 0.012 * H
    tot = None
    for moc in doc:
        nhom = [v for v in doc
                if abs(v['t0'] - moc['t0']) <= dung_sai and abs(v['t1'] - moc['t1']) <= dung_sai]
        if len(nhom) < SO_VACH_DOC_TOI_THIEU:
            continue
        if max(v['vi_tri'] for v in nhom) - min(v['vi_tri'] for v in nhom) < 0.25 * W:
            continue
        diem = len(nhom) * float(np.mean([v['dai'] for v in nhom]))
        if tot is None or diem > tot[0]:
            tot = (diem, nhom)
    return tot[1] if tot else None


def _phu_ngang(doan, x0, x1):
    """Độ phủ cộng dồn (0..1) của các đoạn [t0, t1] trên [x0, x1]."""
    khoang = sorted((max(d['t0'], x0), min(d['t1'], x1)) for d in doan)
    tong, cuoi = 0.0, x0
    for a, b in khoang:
        if b <= a:
            continue
        a = max(a, cuoi)
        if b > a:
            tong += b - a
            cuoi = b
    return tong / max(x1 - x0, 1.0)


def _cot_trong_bang(doc, x0, x1, y_bang0, y_bang1):
    cao_bang = y_bang1 - y_bang0
    cot = []
    for v in doc:
        if not (x0 - 12 <= v['vi_tri'] <= x1 + 12):
            continue
        phu = (min(v['t1'], y_bang1) - max(v['t0'], y_bang0)) / cao_bang
        if phu < 0.15:
            continue
        cot.append(dict(x=v['vi_tri'], y0=max(v['t0'], y_bang0), y1=min(v['t1'], y_bang1), phu=phu))
    cot.sort(key=lambda c: c['x'])
    if not cot or cot[0]['x'] > x0 + 12:
        cot.insert(0, dict(x=x0, y0=y_bang0, y1=y_bang1, phu=1.0))
    if cot[-1]['x'] < x1 - 12:
        cot.append(dict(x=x1, y0=y_bang0, y1=y_bang1, phu=1.0))
    return cot


def _luoi_theo_vach_doc(bw, doc):
    H, W = bw.shape[:2]
    nhom = _nhom_vach_doc(doc, W, H)
    if nhom is None:
        return None
    x0 = float(min(v['vi_tri'] for v in nhom))
    x1 = float(max(v['vi_tri'] for v in nhom))
    y_bang0 = float(np.median([v['t0'] for v in nhom]))
    y_bang1 = float(np.median([v['t1'] for v in nhom]))
    cao_bang, rong_bang = y_bang1 - y_bang0, x1 - x0
    if cao_bang < 60 or rong_bang < 0.25 * W:
        return None
    # đoạn vạch ngang ngắn hơn bản gốc (đoạn đứt vẫn tính), chỉ trong khoảng y của bảng
    doan = [v for v in _doan_vach(bw, 'ngang', nhan_mo=max(25, W // 40), dai_toi_thieu=int(0.08 * W))
            if y_bang0 - 10 <= v['vi_tri'] <= y_bang1 + 10]
    nhom_y = []
    for v in sorted(doan, key=lambda d: d['vi_tri']):
        if nhom_y and abs(nhom_y[-1][0] - v['vi_tri']) <= 7.0:
            nhom_y[-1][1].append(v)
            nhom_y[-1][0] = float(np.mean([d['vi_tri'] for d in nhom_y[-1][1]]))
        else:
            nhom_y.append([v['vi_tri'], [v]])
    hang_y = sorted(y for y, ds in nhom_y if _phu_ngang(ds, x0, x1) >= PHU_NGANG_TOI_THIEU)
    # mép trên/dưới bảng: đầu mút các vạch dọc (vạch ngang mép có thể mờ hoặc dính chữ)
    if not hang_y or hang_y[0] - y_bang0 > 12:
        hang_y.insert(0, y_bang0)
    if hang_y[-1] < y_bang1 - 12:
        hang_y.append(y_bang1)
    gop = [hang_y[0]]
    for y in hang_y[1:]:
        if y - gop[-1] < 12:
            gop[-1] = (gop[-1] + y) / 2.0
        else:
            gop.append(y)
    hang_y = [y for y in gop if y_bang0 - 12 <= y <= y_bang1 + 12]
    if len(hang_y) < 3:
        return None
    cot = _cot_trong_bang(doc, x0, x1, y_bang0, y_bang1)
    if len(cot) < 3:
        return None
    buoc = float(np.median(np.diff(hang_y))) if len(hang_y) > 2 else 0.0
    return dict(hang_y=[float(y) for y in hang_y], cot=cot, bang=(x0, float(y_bang0), x1, float(y_bang1)),
                buoc_dong=buoc, so_hang=len(hang_y) - 1, rong_bang=float(rong_bang), cao_bang=float(cao_bang),
                so_vach_ngang=len(doan), so_vach_doc=len(doc), kich_thuoc_trang=(int(W), int(H)),
                nguon_luoi='vach_doc')


def trich_luoi(page, bw=None):
    """Dò bảng trên trang đã nắn. Trả dict mô tả lưới hoặc None nếu không thấy bảng.

    Thử dựng bảng từ các vạch dọc cột trước (``_luoi_theo_vach_doc``, chịu được bảng ngắn/vạch ngang đứt),
    không được thì dùng thuật toán gốc theo cụm vạch ngang (``_trich_luoi_goc``).
    """
    if bw is None:
        bw = _nhi_phan(page)
    H, W = bw.shape[:2]
    # Bảng chỉ có tiêu đề + 1 dòng cao ~90 px: ngưỡng độ dài vạch dọc thấp hơn bản gốc (0.04H ≈ 93 px).
    doc_ngan = _gop_vach(_doan_vach(bw, 'doc', nhan_mo=max(25, H // 60), dai_toi_thieu=int(0.022 * H)))
    if len(doc_ngan) >= SO_VACH_DOC_TOI_THIEU:
        luoi = _luoi_theo_vach_doc(bw, doc_ngan)
        if luoi is not None:
            return luoi
    return _trich_luoi_goc(page, bw)


def _trich_luoi_goc(page, bw=None):
    """Thuật toán gốc (luoi_tong_quat.trich_luoi): cụm ≥ 4 vạch ngang cùng bề ngang."""
    if bw is None:
        bw = _nhi_phan(page)
    H, W = bw.shape[:2]
    ngang = _gop_vach(_doan_vach(bw, 'ngang', nhan_mo=max(25, W // 40), dai_toi_thieu=int(0.18 * W)))
    doc = _gop_vach(_doan_vach(bw, 'doc', nhan_mo=max(25, H // 60), dai_toi_thieu=int(0.04 * H)))
    if len(ngang) < 4 or len(doc) < 2:
        return None
    nhom = _cum_bang(ngang, W)
    if nhom is None:
        return None
    x0 = float(np.median([v['t0'] for v in nhom]))
    x1 = float(np.median([v['t1'] for v in nhom]))
    y_bang0, y_bang1 = nhom[0]['vi_tri'], nhom[-1]['vi_tri']
    cao_bang = y_bang1 - y_bang0
    if cao_bang < 100 or x1 - x0 < 0.25 * W:
        return None

    # các đường ngang của bảng (thêm cả vạch ngắn hơn nhưng nằm trong thân bảng
    # và phủ ≥ 55% bề ngang bảng — vd vạch dưới hàng tiêu đề bị chữ đè)
    rong_bang = x1 - x0
    hang_y = []
    for v in ngang:
        if y_bang0 - 6 <= v['vi_tri'] <= y_bang1 + 6:
            phu = (min(v['t1'], x1) - max(v['t0'], x0)) / rong_bang
            if phu >= 0.55:
                hang_y.append(v['vi_tri'])
    hang_y = sorted(hang_y)
    gop = [hang_y[0]]
    for y in hang_y[1:]:
        if y - gop[-1] < 12:                 # vạch kẻ đúp
            gop[-1] = (gop[-1] + y) / 2.0
        else:
            gop.append(y)
    hang_y = gop
    if len(hang_y) < 3:
        return None

    # vạch dọc trong bảng: phủ toàn bảng (cột chính) hoặc chỉ một phần (cột con)
    cot = []
    for v in doc:
        if not (x0 - 12 <= v['vi_tri'] <= x1 + 12):
            continue
        phu = (min(v['t1'], y_bang1) - max(v['t0'], y_bang0)) / cao_bang
        if phu < 0.15:
            continue
        cot.append(dict(x=v['vi_tri'], y0=max(v['t0'], y_bang0), y1=min(v['t1'], y_bang1), phu=phu))
    cot.sort(key=lambda c: c['x'])
    # bảo đảm có hai mép bảng
    if not cot or cot[0]['x'] > x0 + 12:
        cot.insert(0, dict(x=x0, y0=y_bang0, y1=y_bang1, phu=1.0))
    if cot[-1]['x'] < x1 - 12:
        cot.append(dict(x=x1, y0=y_bang0, y1=y_bang1, phu=1.0))
    if len(cot) < 3:
        return None

    buoc = float(np.median(np.diff(hang_y))) if len(hang_y) > 2 else 0.0
    return dict(hang_y=[float(y) for y in hang_y], cot=cot, bang=(float(x0), float(y_bang0), float(x1), float(y_bang1)),
                buoc_dong=buoc, so_hang=len(hang_y) - 1, rong_bang=float(rong_bang), cao_bang=float(cao_bang),
                so_vach_ngang=len(ngang), so_vach_doc=len(doc), kich_thuoc_trang=(int(W), int(H)))


def cot_cua_hang(luoi, i_hang, phu_toi_thieu=0.80):
    """Ranh giới cột áp dụng cho hàng thứ i (0 = hàng trên cùng của bảng)."""
    y0, y1 = luoi['hang_y'][i_hang], luoi['hang_y'][i_hang + 1]
    cao = max(y1 - y0, 1.0)
    xs = [c['x'] for c in luoi['cot']
          if (min(c['y1'], y1) - max(c['y0'], y0)) / cao >= phu_toi_thieu]
    x0, x1 = luoi['bang'][0], luoi['bang'][2]
    if not xs or xs[0] > x0 + 12:
        xs.insert(0, x0)
    if xs[-1] < x1 - 12:
        xs.append(x1)
    return [float(x) for x in xs]


def cat_o(page, luoi, i_hang, x_trai, x_phai, le=2):
    y0, y1 = luoi['hang_y'][i_hang], luoi['hang_y'][i_hang + 1]
    ya, yb = int(round(y0)) + le, int(round(y1)) - le
    xa, xb = int(round(x_trai)) + le, int(round(x_phai)) - le
    H, W = page.shape[:2]
    ya, yb = max(0, ya), min(H, yb)
    xa, xb = max(0, xa), min(W, xb)
    if yb - ya < 4 or xb - xa < 4:
        return None
    return page[ya:yb, xa:xb]



# ═════════════════ 4. Định danh cột theo tiêu đề (semantic anchoring) ═══════
def _o_co_chu_in(o):
    """Ô có chữ in hay không (dùng để đoán hàng tiêu đề)."""
    if o is None or o.size == 0:
        return False
    g = cv2.cvtColor(o, cv2.COLOR_BGR2GRAY) if o.ndim == 3 else o
    t = cv2.threshold(g, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    ty_le = float((t > 0).mean())
    return 0.02 < ty_le < 0.5


def doc_hang_tieu_de(page, luoi, ocr_ham=None, so_hang_thu=2):
    """OCR các hàng đầu bảng -> list [{'i_hang', 'o': [(x0,x1,text,vai_tro,diem)]}]."""
    ra = []
    for i in range(min(so_hang_thu, luoi['so_hang'])):
        xs = cot_cua_hang(luoi, i)
        o_list = []
        for k in range(len(xs) - 1):
            o = cat_o(page, luoi, i, xs[k], xs[k + 1], le=3)
            text = ''
            if ocr_ham is not None and o is not None and _o_co_chu_in(o):
                anh = _anh_cho_ocr(o)
                if anh is not None:
                    try:
                        text = ocr_ham(anh) or ''
                    except Exception:
                        text = ''
            vai_tro, diem = khop_tu_khoa(text) if text else (None, 0.0)
            o_list.append(dict(x0=xs[k], x1=xs[k + 1], text=text.strip(), vai_tro=vai_tro, diem=round(diem, 2)))
        ra.append(dict(i_hang=i, o=o_list))
    return ra


def _cot_du_lieu(luoi, i_hang_dau):
    """Ranh giới cột của vùng DỮ LIỆU (lấy hàng có nhiều cột nhất bên dưới tiêu đề)."""
    tot = None
    for i in range(i_hang_dau, luoi['so_hang']):
        xs = cot_cua_hang(luoi, i)
        if tot is None or len(xs) > len(tot):
            tot = xs
    return tot or cot_cua_hang(luoi, max(0, luoi['so_hang'] - 1))


def dinh_danh_cot(page, luoi, ocr_ham=None):
    """Gán vai trò cho từng cột dữ liệu dựa trên chữ in ở hàng tiêu đề.

    Trả dict(cot_du_lieu=[x...], cot=[{x0,x1,vai_tro,nhan,diem,tu_o_gop}], hang_tieu_de=i,
             hang_du_lieu_dau=i0, tieu_de=[...]).
    """
    tieu_de = doc_hang_tieu_de(page, luoi, ocr_ham)
    # hàng tiêu đề = hàng có nhiều từ khoá khớp nhất (mặc định hàng 0)
    diem_hang = [sum(1 for o in h['o'] if o['vai_tro']) for h in tieu_de]
    i_td = int(np.argmax(diem_hang)) if diem_hang and max(diem_hang) > 0 else 0
    # tiêu đề 2 tầng: hàng ngay dưới cũng là chữ in và có từ khoá -> gộp nhãn
    hai_tang = (i_td + 1 < len(tieu_de) and diem_hang[i_td + 1] > 0 and
                len(tieu_de[i_td + 1]['o']) > len(tieu_de[i_td]['o']))
    i_du_lieu = i_td + (2 if hai_tang else 1)

    xs = _cot_du_lieu(luoi, i_du_lieu)
    cot = []
    for k in range(len(xs) - 1):
        x0, x1 = xs[k], xs[k + 1]
        giua = (x0 + x1) / 2.0
        nhan, vai_tro, diem, gop = '', None, 0.0, False
        for tang, h in enumerate(tieu_de[:i_du_lieu]):
            for o in h['o']:
                if o['x0'] - 2 <= giua <= o['x1'] + 2 and o['text']:
                    la_gop = (o['x1'] - o['x0']) > 1.6 * (x1 - x0)
                    nhan = (nhan + ' | ' + o['text']).strip(' |') if nhan else o['text']
                    if o['vai_tro'] and o['diem'] > diem:
                        vai_tro, diem, gop = o['vai_tro'], o['diem'], la_gop
        cot.append(dict(x0=float(x0), x1=float(x1), vai_tro=vai_tro, nhan=nhan,
                        diem=round(diem, 2), tu_o_gop=gop, rong_mm=round((x1 - x0) / PX_MM, 1)))
    return dict(cot_du_lieu=xs, cot=cot, hang_tieu_de=i_td, hai_tang=hai_tang,
                hang_du_lieu_dau=i_du_lieu, tieu_de=tieu_de)



# ═════════════════ 5. Chọn cột điểm (có đường lui khi thiếu OCR) ═══════════
def _diem_hinh_hoc(c, rong_bang):
    """Cột ĐIỂM SỐ viết tay luôn hẹp (~6–13mm); cột 'Điểm chữ' rộng hơn hẳn (>15mm)."""
    r_mm = (c['x1'] - c['x0']) / PX_MM
    if r_mm < 4.5:
        d = -1.5
    elif r_mm <= 13.0:
        d = 1.0
    elif r_mm <= 16.0:
        d = 0.0
    else:
        d = -1.2
    d += 0.5 * min(1.0, max(0.0, (c['x0'] - 0.35 * rong_bang) / (0.5 * rong_bang)))
    return d


def chon_cot_diem(luoi, dinh_danh, cham_noi_dung=None):
    """Chọn cột điểm số chính + các cột điểm phụ.

    cham_noi_dung(x0, x1) -> dict(ty_le_hop_le, tin_cay) : hàm tuỳ chọn do tầng trên
    cung cấp (vd chạy CRNN trên vài ô mẫu) để chấm nội dung cột khi không có OCR
    hoặc khi tiêu đề không khớp từ khoá nào.
    """
    cot = dinh_danh['cot']
    rong = luoi['rong_bang']
    ket = []
    for i, c in enumerate(cot):
        d = dict(c)
        d['chi_so'] = i
        d['diem_chon'] = 0.0
        if c['vai_tro'] == 'diem_so':
            d['diem_chon'] += 3.0 + c['diem']
        elif c['vai_tro'] == 'diem_qua_trinh':
            d['diem_chon'] += 1.2 + 0.5 * c['diem']
        elif c['vai_tro'] in ('stt', 'ma_sv', 'ma_hs', 'ho_ten', 'ngay_sinh', 'lop', 'ky_ten', 'ghi_chu',
                              'diem_chu'):
            d['diem_chon'] -= 3.0
        d['diem_chon'] += 0.6 * _diem_hinh_hoc(c, rong)
        ket.append(d)

    # Cột ngay TRƯỚC cột "Điểm chữ" gần như luôn là cột điểm số -> cộng điểm
    for i, c in enumerate(cot):
        if c['vai_tro'] == 'diem_chu' and i > 0 and ket[i - 1]['vai_tro'] != 'diem_chu':
            ket[i - 1]['diem_chon'] += 1.5
            ket[i - 1]['canh_diem_chu'] = True

    # Chấm nội dung (CRNN) cho các cột còn khả năng — đường lui khi OCR không ra
    if cham_noi_dung is not None:
        can_cham = [d for d in ket if d['vai_tro'] in (None, 'diem_so', 'diem_qua_trinh')
                    and 5 * PX_MM <= (d['x1'] - d['x0']) <= 30 * PX_MM]
        for d in can_cham:
            try:
                nd = cham_noi_dung(d['x0'], d['x1'])
            except Exception:
                nd = None
            if nd:
                d['noi_dung'] = nd
                d['diem_chon'] += 2.5 * nd.get('ty_le_hop_le', 0.0) + 1.0 * nd.get('tin_cay', 0.0)

    ket.sort(key=lambda d: -d['diem_chon'])
    chinh = ket[0] if ket and ket[0]['diem_chon'] > 0.8 else None
    phu = [d for d in ket[1:] if d['diem_chon'] > 0.8 and
           (d['vai_tro'] == 'diem_qua_trinh' or d.get('noi_dung', {}).get('ty_le_hop_le', 0) > 0.5)]
    chu = next((dict(c, chi_so=i) for i, c in enumerate(cot) if c['vai_tro'] == 'diem_chu'), None)
    if chu is None and chinh is not None and chinh['chi_so'] + 1 < len(cot):
        ke = cot[chinh['chi_so'] + 1]
        if ke['vai_tro'] is None and (ke['x1'] - ke['x0']) > 12 * PX_MM:
            chu = dict(ke, chi_so=chinh['chi_so'] + 1, suy_doan=True)
    return dict(cot_diem_chinh=chinh, cot_diem_phu=phu, cot_diem_chu=chu, tat_ca=ket)



# ═══════════════════ 6. Bảng điểm hay không phải bảng điểm ═════════════════
def kiem_tra_la_bang_diem(luoi, dinh_danh=None):
    """Lưới dò được có giống một bảng điểm không. Trả (bool, ly_do_chan, chi_so).

    Căn cứ CHẶN là CẤU TRÚC CỘT (bảng điểm luôn nhiều cột và trải hết bề ngang
    trang), không phải số dòng: mặt sau của một tờ A4 có khi chỉ còn 2–3 dòng,
    chặn theo số dòng sẽ loại nhầm. Số dòng ít chỉ được ghi chú lại.
    """
    ly_do, nhac = [], []
    if luoi is None:
        return False, ['không tìm thấy bảng kẻ ô nào trong ảnh'], {}
    W, H = luoi['kich_thuoc_trang']
    so_hang = luoi['so_hang']
    so_cot = len(_cot_du_lieu(luoi, 0)) - 1
    dt = (luoi['rong_bang'] * luoi['cao_bang']) / float(W * H)
    rong_ty = luoi['rong_bang'] / float(W)
    buoc_mm = luoi['buoc_dong'] / max(PX_MM, 1)

    if so_cot < 4:
        ly_do.append(f'bảng chỉ có {so_cot} cột — bảng điểm phải có ít nhất 4–5 cột '
                     f'(STT, mã SV, họ tên, điểm…)')
    if so_hang < 2:
        ly_do.append(f'bảng chỉ có {so_hang} hàng — không có dòng dữ liệu nào')
    if rong_ty < 0.45:
        ly_do.append(f'bảng chỉ rộng {rong_ty:.0%} bề ngang trang — bảng điểm trải gần hết trang giấy')
    if not (3.0 <= buoc_mm <= 16.0):
        ly_do.append(f'bước dòng {buoc_mm:.1f}mm bất thường (bảng điểm thường 6–12mm)')

    if not ly_do:
        if so_hang < 5:
            nhac.append(f'bảng chỉ có {so_hang} hàng dữ liệu — nếu đây là mặt sau của tờ A4 thì bình thường')
        if dt < 0.10:
            nhac.append(f'bảng chỉ chiếm {dt:.0%} diện tích trang')

    tu_khoa_khop = sum(1 for c in dinh_danh['cot'] if c['vai_tro']) if dinh_danh else 0
    chi_so = dict(so_hang=so_hang, so_cot=so_cot, ty_le_dien_tich=round(dt, 3),
                  ty_le_rong=round(rong_ty, 3), buoc_dong_mm=round(buoc_mm, 2),
                  buoc_dong_px=round(luoi['buoc_dong'], 1), so_cot_khop_tu_khoa=tu_khoa_khop,
                  ghi_chu=nhac)
    return (len(ly_do) == 0), ly_do, chi_so



# ═════════ 7. Lớp bao: mã lỗi ổn định và đường lui hình học (không có trong bản gốc) ═════════
def phat_hien_luoi(page, bw=None):
    """``trich_luoi`` hoặc ``PipelineError("GRID_NOT_FOUND")`` khi trang không có bảng kẻ ô đủ lớn."""
    luoi = trich_luoi(page, bw)
    if luoi is None:
        raise PipelineError(
            "GRID_NOT_FOUND",
            "Không tìm thấy bảng kẻ ô trong ảnh — chụp thẳng, đủ sáng và thấy trọn bảng.",
        )
    return luoi


def bao_dam_la_bang_diem(luoi, dinh_danh=None):
    """Trả chỉ số của bảng; ném ``NOT_A_GRADEBOOK`` khi lưới không giống bảng điểm."""
    ok, ly_do, chi_so = kiem_tra_la_bang_diem(luoi, dinh_danh)
    if not ok:
        raise PipelineError("NOT_A_GRADEBOOK", "; ".join(ly_do))
    return chi_so


def chon_cot_diem_hinh_hoc(luoi, dinh_danh):
    """Đường lui khi KHÔNG đọc được tiêu đề nào (không có OCR hoặc OCR không khớp từ khoá).

    Cột điểm số viết tay luôn hẹp (4.5–13mm) và nằm ngay trước một cột rộng hơn 15mm (Điểm chữ), cách mép
    trái bảng ít nhất 20% bề rộng. Kết quả luôn đánh dấu ``suy_doan_hinh_hoc`` để tầng trên hạ độ tin cậy.
    Trả ``None`` khi không có cột nào thoả.
    """
    cot = dinh_danh['cot']
    x0 = luoi['bang'][0]
    rong = luoi['rong_bang']
    for i in range(len(cot) - 1):
        c, ke = cot[i], cot[i + 1]
        rong_mm = (c['x1'] - c['x0']) / PX_MM
        ke_mm = (ke['x1'] - ke['x0']) / PX_MM
        if 4.5 <= rong_mm <= 13.0 and ke_mm > 15.0 and c['x0'] > x0 + 0.2 * rong:
            chinh = dict(c, chi_so=i, suy_doan=True)
            chu = dict(ke, chi_so=i + 1, suy_doan=True)
            return dict(cot_diem_chinh=chinh, cot_diem_phu=[], cot_diem_chu=chu, tat_ca=[chinh],
                        suy_doan_hinh_hoc=True)
    return None


def chon_cot_diem_bat_buoc(luoi, dinh_danh, cham_noi_dung=None):
    """``chon_cot_diem`` + đường lui hình học; ném ``SCORE_COLUMN_NOT_FOUND`` khi không chọn được cột điểm."""
    kq = chon_cot_diem(luoi, dinh_danh, cham_noi_dung)
    kq['suy_doan_hinh_hoc'] = False
    if kq['cot_diem_chinh'] is None and not any(c['vai_tro'] for c in dinh_danh['cot']):
        kq = chon_cot_diem_hinh_hoc(luoi, dinh_danh) or kq
    if kq['cot_diem_chinh'] is None:
        raise PipelineError(
            "SCORE_COLUMN_NOT_FOUND",
            "Không xác định được cột điểm số trong bảng — kiểm tra tiêu đề cột Điểm số / Điểm chữ có thấy rõ không.",
        )
    return kq
