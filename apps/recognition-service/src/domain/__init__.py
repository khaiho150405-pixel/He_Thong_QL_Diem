"""Framework-independent recognition domain rules."""

from .classification import (
    ChannelPrediction,
    Classification,
    Comparison,
    ReviewLevel,
    classify_channels,
)

__all__ = [
    "ChannelPrediction",
    "Classification",
    "Comparison",
    "ReviewLevel",
    "classify_channels",
]
