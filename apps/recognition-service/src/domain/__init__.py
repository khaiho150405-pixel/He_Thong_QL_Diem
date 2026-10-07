"""Framework-independent recognition domain rules."""

from .classification import (
    ChannelPrediction,
    Classification,
    Comparison,
    DEFAULT_NUMERIC_THRESHOLD,
    DEFAULT_WRITTEN_THRESHOLD,
    ReviewLevel,
    classify_channels,
    thresholds_from_env,
)

__all__ = [
    "ChannelPrediction",
    "Classification",
    "Comparison",
    "ReviewLevel",
    "DEFAULT_NUMERIC_THRESHOLD",
    "DEFAULT_WRITTEN_THRESHOLD",
    "classify_channels",
    "thresholds_from_env",
]
