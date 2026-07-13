"""Performance Drift — deep recompute mode (E5B, resolves I3 at design + prototype).

E5A Performance ran in **shallow** mode: it consumed the official ``*_metrics``
table (MAPE per version). That table only retains ~3 versions, so Performance
was NOT_COMPUTABLE at most fact versions (metric versions do not align to fact
versions).

**Deep** mode recomputes accuracy directly from forecasts + actuals, aligned to
the fact-version grain, giving far deeper historical coverage. It is read-only
and reuses the same E3 ``performance_drift`` comparison (relative MAPE + gate),
so scores stay consistent with the shallow path — only the *source* of MAPE
changes and the coverage deepens.

Governance: this does NOT change the productive mode silently. The engine is
called with an explicit ``perf_mode`` and both modes are recorded in lineage.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from .config.settings import EPS


def deep_mape_for_version(
    fc_key_version: pd.DataFrame, actuals_key: pd.DataFrame,
    fc_date_col: str = "target_date", fc_val_col: str = "forecast_value",
    act_date_col: str = "target_date", act_val_col: str = "actual_value",
) -> dict:
    """Compute realized MAPE for one (key, forecast_version) from actuals.

    Only forward targets that already have an actual (realized) contribute.
    MAPE = mean(|actual - forecast| / |actual|) over actuals with |actual|>=EPS.
    Returns ``{"mape": float|None, "n_points": int, "reason": str|None}``.
    """
    if fc_key_version.empty or actuals_key.empty:
        return {"mape": None, "n_points": 0, "reason": "NO_ACTUALS"}
    fc = fc_key_version[[fc_date_col, fc_val_col]].dropna().copy()
    act = actuals_key[[act_date_col, act_val_col]].dropna().copy()
    # E5B: coerce both join keys to the same datetime dtype (forward df carries
    # python date objects after normalization; actuals carry datetime64).
    fc["_jd"] = pd.to_datetime(fc[fc_date_col], errors="coerce")
    act["_jd"] = pd.to_datetime(act[act_date_col], errors="coerce")
    merged = fc.merge(act, on="_jd", how="inner")
    merged = merged[merged[act_val_col].abs() >= EPS]
    n = int(len(merged))
    if n == 0:
        return {"mape": None, "n_points": 0, "reason": "NO_REALIZED_OVERLAP"}
    ape = (merged[act_val_col] - merged[fc_val_col]).abs() / merged[act_val_col].abs()
    return {"mape": float(np.mean(ape.to_numpy())), "n_points": n, "reason": None}


def deep_mape_by_version(
    sub_fwd: pd.DataFrame, actuals_key: pd.DataFrame,
    version_col: str = "forecast_version",
) -> dict:
    """Return ``{forecast_version: mape}`` for every version with realized overlap.

    ``sub_fwd`` = forward-only rows for a single canonical key.
    ``actuals_key`` = actuals rows for the same key.
    """
    out: dict = {}
    if sub_fwd.empty or actuals_key.empty:
        return out
    for version, grp in sub_fwd.groupby(version_col):
        res = deep_mape_for_version(grp, actuals_key)
        if res["mape"] is not None:
            out[version] = {"mape": res["mape"], "n_points": res["n_points"]}
    return out
