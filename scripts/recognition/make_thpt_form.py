#!/usr/bin/env python
"""Sinh tờ "Sổ điểm môn học — THPT (mô phỏng theo Thông tư 22)" để in A4 và viết tay (ADR-0016, phase P6).

Tờ có 9 cột: STT | Họ và tên | TX1 | TX2 | TX3 | TX4 | GK | CK | Ghi chú và 40 dòng; chỉ có điểm số (không có cột điểm
chữ) nên khi nhận dạng mọi dòng tối đa Vàng (D-01). Danh sách họ tên là dữ liệu GIẢ, sinh ngẫu nhiên có ``--seed``
(hoặc đọc từ ``--names-file``, mỗi dòng một tên); không dùng họ tên thật. Chỉ dùng Pillow + OpenCV/NumPy đã có.

    python scripts/recognition/make_thpt_form.py --out-dir .local/forms [--seed 20261019] [--students 40]
        [--names-file ten_gia.txt] [--font arial.ttf --font-bold arialbd.ttf]
        [--write-layout scripts/recognition/layouts/thpt_tt22.json]

Ghi ``so_diem_thpt_tt22.png`` (A4, 200 dpi: 1654 × 2339 px) và ``so_diem_thpt_tt22.pdf`` (một trang A4 từ chính ảnh đó).
In ở tỉ lệ 100% (không "vừa trang") để bề rộng cột đúng như layout. ``--write-layout`` tính lại chữ ký lưới từ chính ảnh PNG
vừa sinh bằng pipeline của dịch vụ nhận dạng và ghi layout dùng cho ``/v2/recognize`` và khai báo mẫu.
"""
from __future__ import annotations

import argparse
import json
import random
import sys
import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "apps" / "recognition-service"))

DPI = 200
PAGE_PX = (1654, 2339)  # A4 ở 200 dpi
PX_PER_MM = DPI / 25.4
TITLE = "SỔ ĐIỂM MÔN HỌC — THPT"
SUBTITLE = "(Mô phỏng theo Thông tư 22/2021/TT-BGDĐT)"
FIELDS = "Lớp: ................   Môn: ......................   Học kỳ: ......   Năm học: ..............."
FOOTER = "Mẫu mô phỏng để thử nghiệm nhận dạng; danh sách họ tên là dữ liệu giả."
HEADERS = ("STT", "Họ và tên", "TX1", "TX2", "TX3", "TX4", "GK", "CK", "Ghi chú")
# Bề rộng cột (mm), tổng 186 mm = A4 trừ lề 12 mm hai bên.
COLUMNS_MM = (10, 56, 14, 14, 14, 14, 16, 16, 32)
N_ROWS = 40
LEFT_MM = 12.0
TOP_PX = 300
HEADER_PX = 76
ROW_PX = 44
LINE_PX = 3
INK = (20, 20, 20)
FONT_CANDIDATES = (
    ("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/arialbd.ttf"),
    ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/segoeuib.ttf"),
    ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    ("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"),
    ("/Library/Fonts/Arial.ttf", "/Library/Fonts/Arial Bold.ttf"),
    ("/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
)

# Họ, đệm, tên phổ biến để ghép tên giả. Ghép ngẫu nhiên nên không phản ánh người thật nào.
HO = ("Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý")
DEM = ("Văn", "Thị", "Hữu", "Minh", "Quốc", "Ngọc", "Thanh", "Anh", "Gia", "Bảo", "Đức", "Thu", "Hoài", "Kim")
TEN = ("An", "Bình", "Châu", "Dũng", "Giang", "Hà", "Hải", "Khoa", "Lan", "Linh", "Mai", "Nam", "Phúc", "Quân", "Sơn", "Thảo", "Trang", "Uyên", "Vy", "Yến")


def fake_names(count: int, seed: int) -> list[str]:
    """``count`` họ tên giả KHÁC NHAU, tất định theo ``seed``, xếp theo tên rồi họ như danh sách lớp."""
    rng = random.Random(seed)
    if count > len(HO) * len(DEM) * len(TEN):
        raise ValueError("Quá nhiều tên giả.")
    names: set[tuple[str, str, str]] = set()
    while len(names) < count:
        names.add((rng.choice(HO), rng.choice(DEM), rng.choice(TEN)))
    return [" ".join(parts) for parts in sorted(names, key=lambda n: (n[2], n[0], n[1]))]


def column_edges() -> list[int]:
    """Hoành độ (px) các vạch dọc, từ trái sang phải (10 vạch cho 9 cột)."""
    edges, total = [], LEFT_MM
    edges.append(round(total * PX_PER_MM))
    for width in COLUMNS_MM:
        total += width
        edges.append(round(total * PX_PER_MM))
    return edges


def row_edges() -> list[int]:
    """Tung độ (px) các vạch ngang: viền trên, đáy hàng tiêu đề, rồi đáy từng dòng."""
    ys = [TOP_PX, TOP_PX + HEADER_PX]
    ys += [ys[-1] + ROW_PX * (i + 1) for i in range(N_ROWS)]
    return ys


def strip_accents(text: str) -> str:
    text = text.replace("đ", "d").replace("Đ", "D")
    return "".join(c for c in unicodedata.normalize("NFD", text) if unicodedata.category(c) != "Mn")


def load_fonts(regular: Path | None, bold: Path | None):
    """``(tải_phông(cỡ), tải_phông_đậm(cỡ), có_dấu)``. Không có phông TrueType hỗ trợ tiếng Việt thì dùng phông mặc định của
    Pillow và bỏ dấu (``có_dấu`` = False) để tệp vẫn in được."""
    pairs = [(regular, bold or regular)] if regular else [(Path(a), Path(b)) for a, b in FONT_CANDIDATES]
    for a, b in pairs:
        if a.is_file():
            bold_path = b if b.is_file() else a
            return (lambda size: ImageFont.truetype(str(a), size)), (lambda size: ImageFont.truetype(str(bold_path), size)), True
    if regular:
        raise SystemExit(f"Không đọc được phông {regular}.")
    print("Cảnh báo: không tìm thấy phông TrueType có tiếng Việt; dùng phông mặc định và bỏ dấu (dùng --font để chỉ định).", file=sys.stderr)
    default = lambda size: ImageFont.load_default(size)  # noqa: E731
    return default, default, False


def render_form(names: list[str], regular: Path | None = None, bold: Path | None = None) -> Image.Image:
    """Ảnh RGB A4 200 dpi của tờ. ``names`` điền vào cột họ tên theo thứ tự (thiếu thì để trống)."""
    if len(names) > N_ROWS:
        raise ValueError(f"Tối đa {N_ROWS} tên.")
    font, font_bold, accents = load_fonts(regular, bold)
    text = (lambda s: s) if accents else strip_accents
    image = Image.new("RGB", PAGE_PX, (255, 255, 255))
    draw = ImageDraw.Draw(image)
    xs, ys = column_edges(), row_edges()
    draw.text((PAGE_PX[0] / 2, 96), text(TITLE), font=font_bold(54), fill=INK, anchor="mm")
    draw.text((PAGE_PX[0] / 2, 150), text(SUBTITLE), font=font(30), fill=INK, anchor="mm")
    draw.text((xs[0], 230), text(FIELDS), font=font(30), fill=INK, anchor="lm")
    for y in ys:
        draw.line([(xs[0], y), (xs[-1], y)], fill=INK, width=LINE_PX)
    for x in xs:
        draw.line([(x, ys[0]), (x, ys[-1])], fill=INK, width=LINE_PX)
    header_y = (ys[0] + ys[1]) / 2
    for i, label in enumerate(HEADERS):
        draw.text(((xs[i] + xs[i + 1]) / 2, header_y), text(label), font=font_bold(30), fill=INK, anchor="mm")
    for row in range(N_ROWS):
        y = (ys[row + 1] + ys[row + 2]) / 2
        draw.text(((xs[0] + xs[1]) / 2, y), str(row + 1), font=font(28), fill=INK, anchor="mm")
        if row < len(names):
            draw.text((xs[1] + 10, y), text(names[row]), font=font(28), fill=INK, anchor="lm")
    draw.text((xs[0], ys[-1] + 40), text(FOOTER), font=font(24), fill=INK, anchor="lm")
    return image


def png_bytes(image: Image.Image) -> bytes:
    import io

    buffer = io.BytesIO()
    image.save(buffer, "PNG", dpi=(DPI, DPI))
    return buffer.getvalue()


def thpt_layout(png: bytes) -> dict:
    """Layout cho ``/v2/recognize`` của tờ THPT: chữ ký lưới tính từ chính ảnh ``png`` bằng pipeline của dịch vụ nhận dạng."""
    from src.pipeline.layout import phan_tich_bo_cuc

    signature = dict(phan_tich_bo_cuc(png, None).signature)
    if len(signature["columnWidths"]) != len(HEADERS):
        raise SystemExit(f"Pipeline thấy {len(signature['columnWidths'])} cột thay vì {len(HEADERS)}: kiểm tra ảnh sinh ra.")
    signature["headerTexts"] = [strip_accents(h).lower().replace(" ", "") for h in HEADERS]
    columns = [{"index": 0, "role": "STT"}, {"index": 1, "role": "HO_TEN"}]
    columns += [{"index": 2 + i, "role": "DIEM", "key": key} for i, key in enumerate(("TX1", "TX2", "TX3", "TX4", "GK1", "CK1"))]
    return {"signature": signature, "columns": columns}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out-dir", type=Path, default=ROOT / ".local" / "forms", help="thư mục ghi PNG và PDF")
    parser.add_argument("--seed", type=int, default=20261019, help="hạt giống sinh tên giả")
    parser.add_argument("--students", type=int, default=N_ROWS, help=f"số tên in sẵn (0..{N_ROWS}); phần còn lại để trống")
    parser.add_argument("--names-file", type=Path, default=None, help="tệp UTF-8, mỗi dòng một họ tên (thay cho tên sinh ngẫu nhiên)")
    parser.add_argument("--font", type=Path, default=None, help="phông TrueType thường có tiếng Việt")
    parser.add_argument("--font-bold", type=Path, default=None, help="phông TrueType đậm")
    parser.add_argument("--write-layout", type=Path, default=None, help="ghi layout JSON (chữ ký lưới tính từ ảnh vừa sinh)")
    args = parser.parse_args()
    if not 0 <= args.students <= N_ROWS:
        raise SystemExit(f"--students phải từ 0 đến {N_ROWS}.")
    if args.names_file:
        names = [line.strip() for line in args.names_file.read_text(encoding="utf-8").splitlines() if line.strip()][: N_ROWS]
    else:
        names = fake_names(args.students, args.seed)
    image = render_form(names, args.font, args.font_bold)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    png_path, pdf_path = args.out_dir / "so_diem_thpt_tt22.png", args.out_dir / "so_diem_thpt_tt22.pdf"
    data = png_bytes(image)
    png_path.write_bytes(data)
    image.save(pdf_path, "PDF", resolution=float(DPI))
    print(f"Đã ghi {png_path} ({PAGE_PX[0]}x{PAGE_PX[1]} px, {DPI} dpi) và {pdf_path}")
    if args.write_layout:
        args.write_layout.parent.mkdir(parents=True, exist_ok=True)
        args.write_layout.write_text(json.dumps(thpt_layout(data), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Đã ghi layout {args.write_layout}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
