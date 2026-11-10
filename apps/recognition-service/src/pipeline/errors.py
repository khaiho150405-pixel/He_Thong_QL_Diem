"""Error type shared by every stage of the image pipeline."""
from __future__ import annotations

from typing import Any

PIPELINE_ERROR_CODES = frozenset(
    {
        "IMAGE_UNREADABLE",
        "IMAGE_QUALITY_LOW",
        "GRID_NOT_FOUND",
        "NOT_A_GRADEBOOK",
        "SCORE_COLUMN_NOT_FOUND",
        "TEMPLATE_MISMATCH",
    }
)


class PipelineError(Exception):
    """A photo cannot be processed; the caller must ask for another photo."""

    def __init__(
        self, code: str, detail: str = "", details: dict[str, Any] | None = None
    ) -> None:
        if code not in PIPELINE_ERROR_CODES:
            raise ValueError(f"Unknown pipeline error code: {code}")
        super().__init__(f"{code}: {detail}" if detail else code)
        self.code = code
        self.detail = detail
        self.details: dict[str, Any] = dict(details) if details else {}
