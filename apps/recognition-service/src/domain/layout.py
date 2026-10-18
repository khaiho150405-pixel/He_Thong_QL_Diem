"""Kiểm schema ``layout`` của ``POST /v2/recognize`` (ADR-0016 mục 2).

``layout = {"signature": {...}, "columns": [{"index", "role", "key", "writtenIndex"}]}``. ``index`` là chỉ số cột của MẪU
(trái → phải, từ 0). Chỉ gửi các cột cần đọc. Quy tắc:

* ``role`` thuộc ``STT | HO_TEN | DIEM | DIEM_CHU``; ``index`` là số nguyên trong ``[0, số cột của chữ ký)``, không trùng;
* đúng một ``HO_TEN``, tối đa một ``STT``, ít nhất một ``DIEM``;
* ``key`` bắt buộc và duy nhất cho cột ``DIEM`` (``[A-Za-z0-9_-]{1,32}``), phải vắng mặt ở các vai trò khác;
* ``writtenIndex`` (chỉ ở ``DIEM``, tùy chọn) trỏ tới ``index`` của một cột ``DIEM_CHU`` có trong layout; mỗi cột chữ
  chỉ đi kèm một cột ``DIEM``.

Mô-đun thuần Python, không phụ thuộc framework. Lỗi ném ``InvalidLayoutError`` (API trả 422 ``INVALID_LAYOUT``).
"""
from __future__ import annotations

import json
import math
import re
from dataclasses import dataclass
from typing import Any

ROLES = ("STT", "HO_TEN", "DIEM", "DIEM_CHU")
MAX_COLUMNS = 64
MAX_LAYOUT_BYTES = 64 * 1024
_KEY = re.compile(r"[A-Za-z0-9_-]{1,32}")


class InvalidLayoutError(ValueError):
    """``layout`` sai schema hoặc vi phạm các quy tắc của mẫu."""


@dataclass(frozen=True, slots=True)
class LayoutColumn:
    index: int
    role: str
    key: str | None = None
    written_index: int | None = None


@dataclass(frozen=True, slots=True)
class Layout:
    signature: dict[str, Any]
    columns: tuple[LayoutColumn, ...]

    def by_role(self, role: str) -> tuple[LayoutColumn, ...]:
        return tuple(c for c in self.columns if c.role == role)

    @property
    def grade_columns(self) -> tuple[LayoutColumn, ...]:
        """Các cột ``DIEM`` theo thứ tự khai báo (thứ tự ``grades`` trong phản hồi)."""
        return self.by_role("DIEM")


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _signature(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise InvalidLayoutError("signature phải là một đối tượng.")
    if raw.get("version") != 1 or not _is_int(raw.get("version")):
        raise InvalidLayoutError("signature.version phải là 1.")
    widths = raw.get("columnWidths")
    if not isinstance(widths, list) or not 2 <= len(widths) <= MAX_COLUMNS:
        raise InvalidLayoutError(f"signature.columnWidths phải có từ 2 đến {MAX_COLUMNS} phần tử.")
    converted: list[float] = []
    for width in widths:
        if isinstance(width, bool) or not isinstance(width, (int, float)):
            raise InvalidLayoutError("signature.columnWidths chỉ gồm số dương.")
        try:
            value = float(width)  # số nguyên quá lớn không đổi được sang float → OverflowError
        except OverflowError as error:
            raise InvalidLayoutError("signature.columnWidths chỉ gồm số dương.") from error
        if not math.isfinite(value) or value <= 0:
            raise InvalidLayoutError("signature.columnWidths chỉ gồm số dương.")
        converted.append(value)
    if not math.isfinite(sum(converted)):
        raise InvalidLayoutError("signature.columnWidths quá lớn.")
    texts = raw.get("headerTexts", [])
    if not isinstance(texts, list) or not all(isinstance(t, str) for t in texts):
        raise InvalidLayoutError("signature.headerTexts phải là danh sách chuỗi.")
    if texts and len(texts) != len(widths):
        raise InvalidLayoutError("signature.headerTexts phải cùng độ dài columnWidths.")
    return {**raw, "columnWidths": converted, "headerTexts": list(texts)}


def parse_layout(text: str) -> Layout:
    """Chuỗi JSON của trường ``layout`` → ``Layout`` hợp lệ, hoặc ``InvalidLayoutError``."""
    if len(text.encode("utf-8", "surrogatepass")) > MAX_LAYOUT_BYTES:
        raise InvalidLayoutError("layout quá lớn.")
    try:
        raw = json.loads(text)
    except ValueError as error:
        raise InvalidLayoutError("layout không phải JSON hợp lệ.") from error
    if not isinstance(raw, dict):
        raise InvalidLayoutError("layout phải là một đối tượng.")
    signature = _signature(raw.get("signature"))
    column_count = len(signature["columnWidths"])
    raw_columns = raw.get("columns")
    if not isinstance(raw_columns, list) or not 1 <= len(raw_columns) <= MAX_COLUMNS:
        raise InvalidLayoutError(f"columns phải có từ 1 đến {MAX_COLUMNS} phần tử.")

    columns: list[LayoutColumn] = []
    for item in raw_columns:
        if not isinstance(item, dict):
            raise InvalidLayoutError("Mỗi phần tử của columns phải là một đối tượng.")
        index, role = item.get("index"), item.get("role")
        if not _is_int(index) or not 0 <= index < column_count:
            raise InvalidLayoutError(f"index {index!r} nằm ngoài các cột của chữ ký (0..{column_count - 1}).")
        if role not in ROLES:
            raise InvalidLayoutError(f"role {role!r} không hợp lệ.")
        key, written = item.get("key"), item.get("writtenIndex")
        if role == "DIEM":
            if not isinstance(key, str) or not _KEY.fullmatch(key):
                raise InvalidLayoutError("Cột DIEM cần key dạng [A-Za-z0-9_-]{1,32}.")
            if written is not None and not _is_int(written):
                raise InvalidLayoutError("writtenIndex phải là số nguyên hoặc null.")
        elif key is not None or written is not None:
            raise InvalidLayoutError(f"Cột {role} không có key hoặc writtenIndex.")
        columns.append(LayoutColumn(index, role, key, written))

    indexes = [c.index for c in columns]
    if len(set(indexes)) != len(indexes):
        raise InvalidLayoutError("index bị trùng.")
    layout = Layout(signature, tuple(columns))
    if len(layout.by_role("HO_TEN")) != 1:
        raise InvalidLayoutError("Phải có đúng một cột HO_TEN.")
    if len(layout.by_role("STT")) > 1:
        raise InvalidLayoutError("Tối đa một cột STT.")
    if not layout.grade_columns:
        raise InvalidLayoutError("Phải có ít nhất một cột DIEM.")
    keys = [c.key for c in layout.grade_columns]
    if len(set(keys)) != len(keys):
        raise InvalidLayoutError("key bị trùng.")
    written_columns = {c.index for c in layout.by_role("DIEM_CHU")}
    used: set[int] = set()
    for column in layout.grade_columns:
        if column.written_index is None:
            continue
        if column.written_index not in written_columns:
            raise InvalidLayoutError(
                f"writtenIndex {column.written_index} của {column.key} không trỏ tới một cột DIEM_CHU trong layout."
            )
        if column.written_index in used:
            raise InvalidLayoutError("Một cột DIEM_CHU chỉ đi kèm một cột DIEM.")
        used.add(column.written_index)
    return layout
