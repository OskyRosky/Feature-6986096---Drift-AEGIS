"""Data quality checks for governed drift outputs (E5A section 8)."""

from __future__ import annotations

import numpy as np
import pandas as pd

from .config.settings import FAMILIES, WEIGHTS

REQUIRED_SIGNAL_COLS = [
    "drift_event_id", "event_natural_key", "record_hash", "calculation_run_id",
    "scenario", "forecast_key", "forecast_version", "forecast_drift_score",
    "drift_status", "score_coverage_pct", "confidence_level", "is_event",
]


def run_checks(signals: pd.DataFrame, family_scores: pd.DataFrame) -> list[dict]:
    r = []

    def add(name, ok, detail=""):
        r.append({"check": name, "result": "PASS" if ok else "FAIL", "detail": str(detail)})

    add("signals_not_empty", not signals.empty, len(signals))
    add("required_columns_present", all(c in signals.columns for c in REQUIRED_SIGNAL_COLS),
        [c for c in REQUIRED_SIGNAL_COLS if c not in signals.columns])
    # grain uniqueness
    dup = signals.duplicated(subset=["calculation_version", "scenario", "forecast_key", "forecast_version", "drift_type"]).sum()
    add("grain_unique", dup == 0, f"{dup} duplicates")
    add("record_hash_unique", signals["record_hash"].is_unique if not signals.empty else True)
    # score ranges
    score_cols = ["performance_drift_score", "shape_drift_score", "stability_drift_score",
                  "volatility_drift_score", "forecast_drift_score", "score_coverage_pct"]
    bad = 0
    for c in score_cols:
        s = pd.to_numeric(signals[c], errors="coerce")
        bad += int(((s < 0) | (s > 100)).sum())
    add("scores_in_0_100", bad == 0, f"{bad} out of range")
    add("composite_not_null", signals["forecast_drift_score"].notna().all() if not signals.empty else True)
    # weights sum to 100
    add("weights_sum_100", abs(sum(WEIGHTS.values()) - 100.0) < 1e-9, sum(WEIGHTS.values()))
    # no uncontrolled NaN/Inf in numeric family metrics
    numinf = 0
    for c in family_scores.select_dtypes(include=[np.number]).columns:
        numinf += int(np.isinf(pd.to_numeric(family_scores[c], errors="coerce").fillna(0)).sum())
    add("no_inf_values", numinf == 0, numinf)
    # empty keys
    add("no_empty_keys", (signals["forecast_key"].astype(str).str.len() > 0).all() if not signals.empty else True)
    # family rows = 4 per signal
    if not signals.empty and not family_scores.empty:
        per = family_scores.groupby("drift_event_id")["drift_family"].nunique()
        add("four_families_per_signal", (per == len(FAMILIES)).all(), per.value_counts().to_dict())
    # confidence enumeration
    add("confidence_valid", signals["confidence_level"].isin(["HIGH", "MEDIUM", "LOW"]).all() if not signals.empty else True)
    # status enumeration
    add("status_valid", signals["drift_status"].isin(["Healthy", "Watch", "Warning", "Critical", "Unknown"]).all() if not signals.empty else True)

    # --- E5B additional checks ---
    if not signals.empty:
        # I1: canonical key present and equals the active forecast_key
        has_raw = "forecast_key_raw" in signals.columns
        add("forecast_key_raw_present", has_raw, "" if has_raw else "missing forecast_key_raw")
        canon_ok = (signals["forecast_key"].astype(str) == signals["forecast_key"].astype(str).str.strip().str.upper()).all()
        add("forecast_key_is_canonical", bool(canon_ok))
        # severity only set on events; null otherwise
        sev_ok = ((signals["is_event"] == 1) | (signals["severity"].isna())).all()
        add("severity_only_on_events", bool(sev_ok))
        # performance_mode enumerated
        if "performance_mode" in signals.columns:
            add("performance_mode_valid", signals["performance_mode"].isin(["shallow", "deep"]).all())
    if not family_scores.empty:
        # NOT_COMPUTABLE families must have a null family_score
        nc = family_scores["eligibility_status"] == "NOT_COMPUTABLE"
        nc_score_ok = family_scores.loc[nc, "family_score"].isna().all() if nc.any() else True
        add("not_computable_has_null_score", bool(nc_score_ok))
        # eligibility enumerated
        elig_ok = family_scores["eligibility_status"].isin(["COMPUTED", "NOT_COMPUTABLE"]).all()
        add("eligibility_status_valid", bool(elig_ok))
    return r
