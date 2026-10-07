"""Errors shared by recognition adapters."""
from __future__ import annotations


class ModelUnavailableError(RuntimeError):
    """The model cannot be used: missing file, wrong hash, unsafe or unreadable checkpoint, missing dependency."""
