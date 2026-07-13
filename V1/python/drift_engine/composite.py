"""Composite Forecast Drift Score, coverage/confidence, event logic (E3 sec 8-9)."""

from __future__ import annotations

from typing import Optional

from .config.settings import (
    BANDS,
    CONFIDENCE_HIGH_COVERAGE,
    CONFIDENCE_MEDIUM_COVERAGE,
    CONTRIB_MIN_PCT,
    EVENT_THRESHOLD,
    FAMILIES,
    FAMILY_EVENT_THRESHOLD,
    WEIGHTS,
)
from .scoring import status_band


def composite(scores: dict) -> dict:
    """Combine family scores (dict family->score|None) into the composite result.

    Renormalizes weights over available (non-None) families.
    """
    available = {f: s for f, s in scores.items() if s is not None}
    if not available:
        return {
            "forecast_drift_score": None,
            "drift_status": "Unknown",
            "score_coverage_pct": 0.0,
            "confidence_level": "LOW",
            "dominant_drift_family": None,
            "contributing_families": None,
            "missing_family_flag": ",".join(FAMILIES),
        }
    w_avail = sum(WEIGHTS[f] for f in available)
    w_all = sum(WEIGHTS[f] for f in FAMILIES)
    fds = sum(WEIGHTS[f] * available[f] for f in available) / w_avail
    coverage = 100.0 * w_avail / w_all
    if coverage >= CONFIDENCE_HIGH_COVERAGE:
        conf = "HIGH"
    elif coverage >= CONFIDENCE_MEDIUM_COVERAGE:
        conf = "MEDIUM"
    else:
        conf = "LOW"
    contribs = {f: WEIGHTS[f] * available[f] for f in available}
    dominant = max(contribs, key=contribs.get)
    total_contrib = sum(contribs.values())
    contributing = [
        f for f, c in contribs.items() if total_contrib > 0 and 100.0 * c / total_contrib >= CONTRIB_MIN_PCT
    ]
    missing = [f for f in FAMILIES if f not in available]
    return {
        "forecast_drift_score": round(fds, 2),
        "drift_status": status_band(fds),
        "score_coverage_pct": round(coverage, 2),
        "confidence_level": conf,
        "dominant_drift_family": dominant,
        "contributing_families": ",".join(contributing) if contributing else None,
        "missing_family_flag": ",".join(missing) if missing else None,
    }


def is_event(fds: Optional[float], family_scores: dict) -> bool:
    """Event when composite >= EVENT_THRESHOLD or any family >= FAMILY_EVENT_THRESHOLD."""
    if fds is not None and fds >= EVENT_THRESHOLD:
        return True
    return any(s is not None and s >= FAMILY_EVENT_THRESHOLD for s in family_scores.values())


def severity_of(drift_status: str, is_event_flag: bool) -> Optional[str]:
    if not is_event_flag:
        return None
    return drift_status if drift_status in ("Watch", "Warning", "Critical") else None


def persistence_type(consecutive_warning_versions: int) -> Optional[str]:
    if consecutive_warning_versions <= 0:
        return None
    from .config.settings import PERSISTENCE_MIN

    return "sustained" if consecutive_warning_versions >= PERSISTENCE_MIN else "single_spike"
