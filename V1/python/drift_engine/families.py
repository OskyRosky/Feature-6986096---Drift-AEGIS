"""The four Forecast Drift family formulas (E3), as pure testable functions.

Each returns a dict with score (0-100 or None=NOT_COMPUTABLE), raw magnitude,
family-specific metrics, reason_code, explanation and eligibility.
No I/O, no DB. Implements exactly the E3 MVP decisions.
"""

from __future__ import annotations

import math
from typing import Optional, Sequence

import numpy as np

from .config.settings import (
    ANCHORS,
    EPS,
    PERF_MIN_ABS_DELTA,
    SHAPE_DIV_PCT,
    SHAPE_MIN_POINTS,
    STAB_JUMP_PCT,
    STAB_MIN_ABS,
    VOL_WINDOW_N,
    MIN_VERSIONS,
)
from .scoring import piecewise, status_band


def _nc(reason: str) -> dict:
    return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": reason}


# ---------------------------------------------------------------------------
# Performance Drift (E3 sec 4) — primary metric MAPE (lower-better), shallow mode
# ---------------------------------------------------------------------------
def performance_drift(
    metric_now: Optional[float],
    metric_prev: Optional[float],
    metric_name: str = "MAPE",
    lower_is_better: bool = True,
) -> dict:
    if metric_now is None or metric_prev is None:
        return _nc("INSUFFICIENT_VERSIONS")
    delta = metric_now - metric_prev
    base = abs(metric_prev) if abs(metric_prev) >= EPS else EPS
    delta_pct = delta / base
    if abs(delta) < PERF_MIN_ABS_DELTA:
        raw = 0.0
    else:
        signed = delta_pct if lower_is_better else -delta_pct
        raw = max(0.0, signed)
    a = ANCHORS["performance"]
    score = round(piecewise(raw, *a), 2)
    reason = "PERFORMANCE_DETERIORATION" if score >= 40 else "PERFORMANCE_STABLE"
    expl = (
        f"{metric_name} moved {metric_prev:g} -> {metric_now:g} "
        f"({delta_pct:+.1%}); "
        + ("accuracy deteriorating." if raw > 0 else "no significant deterioration.")
    )
    return {
        "score": score,
        "raw_magnitude": round(raw, 6),
        "eligibility_status": "COMPUTED",
        "not_computable_reason": None,
        "metric_name": metric_name,
        "metric_value": metric_now,
        "previous_metric_value": metric_prev,
        "metric_delta": round(delta, 6),
        "metric_delta_pct": round(delta_pct, 6),
        "reason_code": reason,
        "explanation": expl,
    }


# ---------------------------------------------------------------------------
# Shape Drift (E3 sec 5) — level-normalized weighted curve RMSE
# ---------------------------------------------------------------------------
def shape_drift(prev_curve: Sequence[float], now_curve: Sequence[float], target_dates=None) -> dict:
    prev = np.asarray(prev_curve, dtype=float)
    now = np.asarray(now_curve, dtype=float)
    if prev.size != now.size:
        return _nc("CURVE_LENGTH_MISMATCH")
    if prev.size < SHAPE_MIN_POINTS:
        return _nc("INSUFFICIENT_POINTS")
    level = max(float(np.mean(np.abs(prev))), EPS)
    diffs = now - prev
    rmse = math.sqrt(float(np.mean(diffs ** 2)))
    raw = rmse / level
    a = ANCHORS["shape"]
    score = round(piecewise(raw, *a), 2)
    idx_max = int(np.argmax(np.abs(diffs)))
    max_delta = float(diffs[idx_max])
    base_at_max = abs(prev[idx_max]) if abs(prev[idx_max]) >= EPS else EPS
    max_delta_pct = max_delta / base_at_max
    # divergence start: first point with relative diff > SHAPE_DIV_PCT
    rel = np.abs(diffs) / np.maximum(np.abs(prev), EPS)
    div_idx = next((i for i, v in enumerate(rel) if v > SHAPE_DIV_PCT), None)
    div_date = None
    if div_idx is not None and target_dates is not None:
        div_date = target_dates[div_idx]
    expl = (
        f"Forecast trajectory diverged from the prior version "
        f"(relative curve RMSE {raw:.1%}); largest change {max_delta:+.4g} "
        f"({max_delta_pct:+.1%})."
    )
    return {
        "score": score,
        "raw_magnitude": round(raw, 6),
        "eligibility_status": "COMPUTED",
        "not_computable_reason": None,
        "shape_distance": round(raw, 6),
        "max_curve_delta": round(max_delta, 6),
        "max_curve_delta_pct": round(max_delta_pct, 6),
        "divergence_start_date": div_date,
        "horizon_point_count": int(prev.size),
        "reason_code": "SHAPE_DIVERGENCE" if score >= 40 else "SHAPE_STABLE",
        "explanation": expl,
    }


# ---------------------------------------------------------------------------
# Stability Drift (E3 sec 6) — latest consecutive revision %
# ---------------------------------------------------------------------------
def stability_drift(version_values: Sequence[float]) -> dict:
    vals = [v for v in version_values if v is not None]
    if len(vals) < MIN_VERSIONS["stability"]:
        return _nc("INSUFFICIENT_VERSIONS")
    now, prev, first = vals[-1], vals[-2], vals[0]
    base = abs(prev) if abs(prev) >= STAB_MIN_ABS else None
    if base is None:
        return _nc("NEAR_ZERO_BASE")
    value_delta = now - prev
    value_delta_pct = value_delta / prev
    raw = abs(value_delta_pct)
    base_first = abs(first) if abs(first) >= EPS else EPS
    cumulative_pct = (now - first) / base_first if len(vals) >= 3 else None
    a = ANCHORS["stability"]
    score = round(piecewise(raw, *a), 2)
    structural_break = bool(raw >= STAB_JUMP_PCT)
    cum_txt = f"; cumulative {cumulative_pct:+.1%} vs first" if cumulative_pct is not None else ""
    expl = (
        f"Target revised {prev:g} -> {now:g} ({value_delta_pct:+.1%})"
        + cum_txt
        + ("; structural break." if structural_break else ".")
    )
    return {
        "score": score,
        "raw_magnitude": round(raw, 6),
        "eligibility_status": "COMPUTED",
        "not_computable_reason": None,
        "value_delta": round(value_delta, 6),
        "value_delta_pct": round(value_delta_pct, 6),
        "cumulative_revision_pct": None if cumulative_pct is None else round(cumulative_pct, 6),
        "structural_break_flag": structural_break,
        "version_count": len(vals),
        "reason_code": "STABILITY_JUMP" if structural_break else ("STABILITY_DRIFT" if score >= 40 else "STABILITY_STABLE"),
        "explanation": expl,
    }


# ---------------------------------------------------------------------------
# Volatility Drift (E3 sec 7) — coefficient of variation over last N versions
# ---------------------------------------------------------------------------
def volatility_drift(version_values: Sequence[float], window_n: int = VOL_WINDOW_N) -> dict:
    vals = [v for v in version_values if v is not None][-window_n:]
    if len(vals) < MIN_VERSIONS["volatility"]:
        return _nc("INSUFFICIENT_VERSIONS")
    x = np.asarray(vals, dtype=float)
    mean = float(np.mean(x))
    if abs(mean) < EPS:
        return _nc("NEAR_ZERO_MEAN")
    std = float(np.std(x, ddof=1))  # sample std
    cov = std / abs(mean)
    raw = cov
    a = ANCHORS["volatility"]
    score = round(piecewise(raw, *a), 2)
    median = float(np.median(x))
    mad = float(np.median(np.abs(x - median)))
    mad_over_median = mad / (abs(median) if abs(median) >= EPS else EPS)
    diffs = np.diff(x)
    signs = np.sign(diffs)
    sign_changes = int(np.sum(signs[1:] * signs[:-1] < 0)) if signs.size >= 2 else 0
    sign_change_freq = sign_changes / (len(x) - 2) if len(x) > 2 else 0.0
    a20 = a[0]
    a70 = a[2]
    if cov < a20:
        vclass = "stable"
    elif cov < a70:
        vclass = "variable"
    else:
        vclass = "erratic"
    single_spike = cov >= a70 and mad_over_median < a20
    if single_spike:
        vclass = vclass + "_single_spike"
    expl = (
        f"Forecast oscillated across last {len(x)} versions (CoV {cov:.1%})"
        + ("; single-spike (robust MAD low)." if single_spike else ".")
    )
    return {
        "score": score,
        "raw_magnitude": round(raw, 6),
        "eligibility_status": "COMPUTED",
        "not_computable_reason": None,
        "rolling_stddev": round(std, 6),
        "rolling_cov": round(cov, 6),
        "rolling_mad": round(mad_over_median, 6),
        "oscillation_count": sign_changes,
        "sign_change_freq": round(sign_change_freq, 4),
        "volatility_class": vclass,
        "version_count": len(x),
        "reason_code": "VOLATILITY_ERRATIC" if score >= 40 else "VOLATILITY_STABLE",
        "explanation": expl,
    }
