"""Framework-independent recognition domain rules."""

from .classification import (
    ChannelPrediction,
    Classification,
    Comparison,
    DEFAULT_NUMERIC_FLOOR,
    DEFAULT_NUMERIC_THRESHOLD,
    DEFAULT_WRITTEN_FLOOR,
    DEFAULT_WRITTEN_THRESHOLD,
    ReviewLevel,
    Suggestion,
    classify_channels,
    floors_from_env,
    thresholds_from_env,
)

__all__ = [
    "ChannelPrediction",
    "Classification",
    "Comparison",
    "ReviewLevel",
    "Suggestion",
    "DEFAULT_NUMERIC_FLOOR",
    "DEFAULT_NUMERIC_THRESHOLD",
    "DEFAULT_WRITTEN_FLOOR",
    "DEFAULT_WRITTEN_THRESHOLD",
    "classify_channels",
    "floors_from_env",
    "thresholds_from_env",
]
