"""Common 0-100 normalization and status bands (E3 section 3 & 9).

Pure, testable, no I/O.
"""

from __future__ import annotations

from .config.settings import BANDS


def clamp(x: float, lo: float = 0.0, hi: float = 100.0) -> float:
    return max(lo, min(hi, x))


def piecewise(r: float, a20: float, a40: float, a70: float, a100: float) -> float:
    """Threshold-anchored piecewise-linear map of raw magnitude r>=0 to 0-100.

    Anchors: (0,0) (a20,20) (a40,40) (a70,70) (a100,100); clamp [0,100].
    """
    if r is None:
        return None
    if r <= 0:
        return 0.0
    if r < a20:
        return clamp(20.0 * r / a20)
    if r < a40:
        return clamp(20.0 + 20.0 * (r - a20) / (a40 - a20))
    if r < a70:
        return clamp(40.0 + 30.0 * (r - a40) / (a70 - a40))
    if r <= a100:
        return clamp(70.0 + 30.0 * (r - a70) / (a100 - a70))
    return 100.0


def status_band(score: float) -> str:
    """Map a 0-100 score to a status band (E3 section 9)."""
    if score is None:
        return "Unknown"
    if score < BANDS["watch_min"]:
        return "Healthy"
    if score < BANDS["warning_min"]:
        return "Watch"
    if score < BANDS["critical_min"]:
        return "Warning"
    return "Critical"
