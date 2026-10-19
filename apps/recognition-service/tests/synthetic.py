"""Synthetic gradebook photos for pipeline tests (no real student data).

The page is drawn with code: a ruled table on white paper, optional printed header and cell text, then
"photographed" with rotation, mild perspective and a coloured table surface behind the paper.
"""
from __future__ import annotations

import cv2
import numpy as np

A4_W, A4_H = 1654, 2338
BACKGROUND = (55, 90, 135)  # BGR, a brown surface clearly different from white paper
PAPER = (246, 246, 242)
INK = (35, 35, 35)
# A dashed rule: 26 px of ink then an 8 px gap; the gaps survive the "photograph" and the dashes are shorter than the
# vertical opening kernel of the grid detector, so the grid loses the rule while 76% of its length is still ink.
DASH_PERIOD = 34
DASH_GAP = 8

# Column widths in pixels on the 1654 px wide page: STT | Họ tên | Mã/ghi chú | Đ.số | Điểm chữ | Ký tên
DEFAULT_COLUMNS = (90, 470, 150, 190, 330, 214)
DEFAULT_HEADERS = ("STT", "Ho va ten", "Ghi chu", "D.so", "Diem chu", "Ky ten")


def make_page(
    rows: int = 38,
    columns: tuple[int, ...] = DEFAULT_COLUMNS,
    left: int = 110,
    top: int = 240,
    header_height: int = 76,
    row_height: int = 44,
    line: int = 3,
    headers: tuple[str, ...] | None = DEFAULT_HEADERS,
    cell_text: dict[tuple[int, int], str] | None = None,
    struck_rows: tuple[int, ...] = (),
    first_stt: int = 1,
    ink_cells: tuple[tuple[int, int], ...] = (),
    line_gaps: float = 0.0,
    missing_lines: tuple[int, ...] = (),
    dashed_lines: tuple[int, ...] = (),
) -> tuple[np.ndarray, dict]:
    """Return ``(page, layout)``; ``layout`` has the x lines and y lines of the ruled table.

    ``missing_lines`` are indexes into ``layout["xs"]`` of vertical rules that are not drawn (a rule lost to a faded scan).
    ``dashed_lines`` are rules drawn in short dashes with tiny gaps (a rule broken by a bad photo): the grid detector
    drops them but the ink is still on the page.
    """
    page = np.full((A4_H, A4_W, 3), PAPER, np.uint8)
    xs = [left]
    for width in columns:
        xs.append(xs[-1] + width)
    ys = [top, top + header_height]
    for _ in range(rows):
        ys.append(ys[-1] + row_height)
    drawn = [x for k, x in enumerate(xs) if k not in missing_lines and k not in dashed_lines]
    for x in drawn:
        cv2.line(page, (x, ys[0]), (x, ys[-1]), INK, line)
    for k in dashed_lines:
        for start in range(ys[0], ys[-1], DASH_PERIOD):
            cv2.line(page, (xs[k], start), (xs[k], min(start + DASH_PERIOD - DASH_GAP, ys[-1])), INK, line)
    for y in ys:
        cv2.line(page, (xs[0], y), (xs[-1], y), INK, line)
    if line_gaps > 0:
        # Inner row lines broken in two places (ink over the rule, faded scan): erase `line_gaps` of the width.
        width = xs[-1] - xs[0]
        for y in ys[1:-1]:
            for start in (0.25, 0.62):
                x0 = int(xs[0] + start * width)
                x1 = int(x0 + line_gaps / 2 * width)
                cv2.rectangle(page, (x0, y - line - 1), (x1, y + line + 1), PAPER, -1)
        for x in drawn:  # the column rules stay intact; only the row rules are broken
            cv2.line(page, (x, ys[0]), (x, ys[-1]), INK, line)
    if headers:
        for index, text in enumerate(headers):
            cv2.putText(
                page,
                text,
                (xs[index] + 8, ys[0] + 48),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.9,
                INK,
                2,
                cv2.LINE_AA,
            )
    for row in range(rows):
        y0, y1 = ys[row + 1], ys[row + 2]
        text = {0: str(first_stt + row)}
        if cell_text:
            text.update({c: t for (r, c), t in cell_text.items() if r == row})
        for col, value in text.items():
            cv2.putText(
                page,
                value,
                (xs[col] + 10, y1 - 12),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                INK,
                2,
                cv2.LINE_AA,
            )
        if row in struck_rows:
            cv2.line(page, (xs[0] + 6, y1 - 20), (xs[-1] - 6, y0 + 20), INK, 3)
    for row, col in ink_cells:
        y0, y1 = ys[row + 1], ys[row + 2]
        cv2.putText(
            page,
            "8.5",
            (xs[col] + 20, y1 - 12),
            cv2.FONT_HERSHEY_SIMPLEX,
            1.0,
            INK,
            3,
            cv2.LINE_AA,
        )
    return page, {"xs": xs, "ys": ys, "rows": rows}


# High-school sheet (cấp 3): STT | Họ tên | TX1 | TX2 | TX3 | TX4 | GK | CK | Ghi chú. One-channel (no written-grade
# column), printed headers. Widths in px on the 1654 px wide page.
THPT_COLUMNS = (60, 380, 105, 105, 105, 105, 116, 128, 326)
THPT_HEADERS = ("STT", "Ho va ten", "TX1", "TX2", "TX3", "TX4", "GK", "CK", "Ghi chu")
THPT_OCR = ("STT", "Họ và tên", "TX1", "TX2", "TX3", "TX4", "GK", "CK", "Ghi chú")
THPT_SCORE_COLUMNS = (2, 3, 4, 5, 6, 7)
# A different printed form: STT | Mã HS | Họ tên | Miệng | 15 phút | 1 tiết | Học kỳ | Ghi chú (other column count and widths).
OTHER_COLUMNS = (70, 140, 360, 130, 130, 130, 130, 340)
OTHER_HEADERS = ("STT", "Ma HS", "Ho va ten", "Mieng", "15 phut", "1 tiet", "Hoc ky", "Ghi chu")
OTHER_OCR = ("STT", "Mã HS", "Họ và tên", "Miệng", "15 phút", "1 tiết", "Học kỳ", "Ghi chú")


def make_thpt_page(
    rows: int = 20,
    filled_rows: tuple[int, ...] | None = None,
    columns: tuple[int, ...] = THPT_COLUMNS,
    headers: tuple[str, ...] | None = THPT_HEADERS,
    score_columns: tuple[int, ...] = THPT_SCORE_COLUMNS,
    name_column: int = 1,
    **kwargs,
) -> tuple[np.ndarray, dict]:
    """A one-channel high-school sheet: every filled row has a printed name and a grade in each score column.

    ``filled_rows`` are zero-based row positions with ink (default: all rows). Extra keyword arguments go to ``make_page``.
    """
    filled = tuple(range(rows)) if filled_rows is None else filled_rows
    cell_text = {(row, name_column): f"Hoc sinh {row + 1:02d}" for row in filled}
    ink = tuple((row, col) for row in filled for col in score_columns)
    return make_page(
        rows=rows,
        columns=columns,
        headers=headers,
        cell_text=cell_text,
        ink_cells=ink,
        **kwargs,
    )


def photograph(
    page: np.ndarray,
    angle: float = 5.0,
    perspective: float = 0.025,
    scale: float = 0.72,
    canvas: tuple[int, int] = (3000, 2300),
    blur: float = 0.0,
    seed: int = 7,
) -> np.ndarray:
    """Place the page on a coloured surface with rotation and mild perspective, like a phone photo."""
    height, width = canvas
    surface = np.full((height, width, 3), BACKGROUND, np.uint8)
    rng = np.random.RandomState(seed)
    noise = rng.randint(-6, 7, surface.shape).astype(np.int16)
    surface = np.clip(surface.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    ph, pw = page.shape[:2]
    corners = np.array([[0, 0], [pw, 0], [pw, ph], [0, ph]], np.float32)
    centre = np.array([width / 2.0, height / 2.0], np.float32)
    theta = np.radians(angle)
    rot = np.array(
        [[np.cos(theta), -np.sin(theta)], [np.sin(theta), np.cos(theta)]], np.float32
    )
    placed = ((corners - np.array([pw / 2.0, ph / 2.0], np.float32)) * scale) @ rot.T + centre
    # perspective: the far (top) edge is a little shorter than the near (bottom) edge
    shrink = perspective * pw * scale
    placed[0, 0] += shrink
    placed[1, 0] -= shrink
    matrix = cv2.getPerspectiveTransform(corners, placed.astype(np.float32))
    warped = cv2.warpPerspective(
        page, matrix, (width, height), flags=cv2.INTER_AREA, borderMode=cv2.BORDER_TRANSPARENT
    )
    mask = cv2.warpPerspective(
        np.full(page.shape[:2], 255, np.uint8), matrix, (width, height), flags=cv2.INTER_NEAREST
    )
    surface[mask > 0] = warped[mask > 0]
    if blur > 0:
        surface = cv2.GaussianBlur(surface, (0, 0), blur)
    return surface


def encode_png(image: np.ndarray) -> bytes:
    ok, buffer = cv2.imencode(".png", image)
    assert ok
    return buffer.tobytes()


def scan(
    page: np.ndarray, angle: float = 0.4, noise: float = 6.0, blur: float = 0.8, seed: int = 11
) -> np.ndarray:
    """A flatbed scan: the page fills the frame, tiny skew, grey paper, sensor noise, slight softness."""
    height, width = page.shape[:2]
    matrix = cv2.getRotationMatrix2D((width / 2.0, height / 2.0), angle, 1.0)
    out = cv2.warpAffine(
        page, matrix, (width, height), flags=cv2.INTER_AREA, borderValue=PAPER
    )
    out = (out.astype(np.float32) * 0.93).clip(0, 255)  # greyish paper
    rng = np.random.RandomState(seed)
    out = out + rng.normal(0, noise, out.shape)
    out = np.clip(out, 0, 255).astype(np.uint8)
    return cv2.GaussianBlur(out, (0, 0), blur) if blur > 0 else out
