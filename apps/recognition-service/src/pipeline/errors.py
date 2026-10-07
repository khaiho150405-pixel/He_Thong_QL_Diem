"""Error type shared by every stage of the image pipeline."""
from __future__ import annotations

# Stable codes returned to the API (HTTP 422 body, see src/api/main.py).
PIPELINE_ERROR_CODES = frozenset(
    {
        "IMAGE_UNREADABLE",
        "IMAGE_QUALITY_LOW",
        "GRID_NOT_FOUND",
        "NOT_A_GRADEBOOK",
        "SCORE_COLUMN_NOT_FOUND",
    }
)


class PipelineError(Exception):
    """A photo cannot be processed; the caller must ask for another photo."""

    def __init__(self, code: str, detail: str = "") -> None:
        if code not in PIPELINE_ERROR_CODES:
            raise ValueError(f"Unknown pipeline error code: {code}")
        super().__init__(f"{code}: {detail}" if detail else code)
        self.code = code
        self.detail = detail
