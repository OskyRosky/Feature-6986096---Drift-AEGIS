"""Drift engine orchestration: normalized data -> signals + family_scores.

Builds one signal per (key, forecast_version) at the E4 grain, computing the four
families where eligible, the composite score, events and explanations.
"""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone

import numpy as np
import pandas as pd

from .config.settings import (
    CALCULATION_VERSION,
    FAMILIES,
    FORMULA_VERSION,
    NORMALIZATION_VERSION,
    RESOURCE_SCOPE,
    SCENARIO_SCOPE,
    SOURCE_SCHEMA,
    FACT_TABLE,
    THRESHOLD_CONFIG_VERSION,
    VOL_WINDOW_N,
    WEIGHT_CONFIG_VERSION,
)
from .composite import composite, is_event, severity_of, persistence_type
from .families import performance_drift, shape_drift, stability_drift, volatility_drift
from .logger import get_logger
from .normalization import consecutive_version_pairs
from .performance_deep import deep_mape_by_version

log = get_logger("drift_engine.engine")


def _hash(*parts) -> str:
    return hashlib.sha256("|".join(str(p) for p in parts).encode("utf-8")).hexdigest()


def _metric_perf(metrics: pd.DataFrame, key: str, version) -> dict:
    """Performance drift from official metrics when a matching version + prior exists."""
    if metrics is None or metrics.empty:
        return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "NO_METRICS"}
    mk = metrics[metrics["Key"] == key].sort_values("forecast_version")
    if mk.empty:
        return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "NO_METRICS"}
    vers = list(mk["forecast_version"])
    if version not in vers:
        return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "METRIC_VERSION_UNMATCHED"}
    i = vers.index(version)
    if i == 0:
        return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "INSUFFICIENT_VERSIONS"}
    now = float(mk.iloc[i]["MAPE"])
    prev = float(mk.iloc[i - 1]["MAPE"])
    return performance_drift(now, prev, metric_name="MAPE", lower_is_better=True)


def _deep_perf(deep_mapes: dict, version) -> dict:
    """Performance drift from deep-recomputed MAPE (I3) when this + prior version exist."""
    if not deep_mapes:
        return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "NO_ACTUALS"}
    versions = sorted(deep_mapes)
    if version not in versions:
        return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "NO_REALIZED_OVERLAP"}
    i = versions.index(version)
    if i == 0:
        return {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "INSUFFICIENT_VERSIONS"}
    now = float(deep_mapes[versions[i]]["mape"])
    prev = float(deep_mapes[versions[i - 1]]["mape"])
    return performance_drift(now, prev, metric_name="MAPE_deep", lower_is_better=True)


def compute_signals(df_fwd: pd.DataFrame, metrics: pd.DataFrame, run_id: int,
                    perf_mode: str = "shallow", actuals: pd.DataFrame | None = None) -> tuple[pd.DataFrame, pd.DataFrame]:
    now_ts = datetime.now(timezone.utc)
    signals = []
    family_rows = []
    perf_mode = (perf_mode or "shallow").lower()

    for key, sub in df_fwd.groupby("Key"):
        region = sub["region"].iloc[0]
        # E5B (I1): key is the canonical form; keep the most frequent original
        # spelling as raw for lineage (never lose the source value).
        if "forecast_key_raw" in sub.columns:
            raw_key = sub["forecast_key_raw"].value_counts().index[0]
        else:
            raw_key = key
        # E5B (I3): deep Performance recompute source (aligned to fact versions).
        deep_mapes = {}
        if perf_mode == "deep" and actuals is not None and not actuals.empty:
            akey = actuals[actuals["Key"] == key] if "Key" in actuals.columns else actuals
            deep_mapes = deep_mape_by_version(sub, akey)
        piv = sub.pivot_table(index="target_date", columns="forecast_version", values="forecast_value", aggfunc="first")
        versions = sorted(piv.columns)
        for i in range(1, len(versions)):
            v_n = versions[i]
            v_prev = versions[i - 1]
            col_n = piv[v_n]
            col_p = piv[v_prev]
            common = [t for t in piv.index if pd.notna(col_n.get(t)) and pd.notna(col_p.get(t))]
            common = sorted(common)

            # --- Shape ---
            if len(common) >= 4:
                shape = shape_drift([col_p[t] for t in common], [col_n[t] for t in common], target_dates=common)
            else:
                shape = {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "INSUFFICIENT_POINTS"}

            # --- Stability & Volatility (per target, aggregate max) ---
            best_stab = {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "INSUFFICIENT_VERSIONS"}
            best_vol = {"score": None, "eligibility_status": "NOT_COMPUTABLE", "not_computable_reason": "INSUFFICIENT_VERSIONS"}
            for t in piv.index:
                if pd.isna(col_n.get(t)):
                    continue
                series = [piv.loc[t, v] for v in versions[: i + 1] if pd.notna(piv.loc[t, v])]
                if len(series) >= 2:
                    st = stability_drift(series)
                    if st.get("score") is not None and (best_stab.get("score") is None or st["score"] > best_stab["score"]):
                        best_stab = {**st, "target_date": t}
                if len(series) >= 4:
                    vo = volatility_drift(series, window_n=VOL_WINDOW_N)
                    if vo.get("score") is not None and (best_vol.get("score") is None or vo["score"] > best_vol["score"]):
                        best_vol = {**vo, "target_date": t}

            # --- Performance (shallow=official metrics, deep=recomputed MAPE) ---
            if perf_mode == "deep":
                perf = _deep_perf(deep_mapes, v_n)
            else:
                perf = _metric_perf(metrics, key, v_n)

            fam_scores = {
                "performance": perf.get("score"),
                "shape": shape.get("score"),
                "stability": best_stab.get("score"),
                "volatility": best_vol.get("score"),
            }
            comp = composite(fam_scores)
            evflag = is_event(comp["forecast_drift_score"], fam_scores)
            sev = severity_of(comp["drift_status"], evflag)
            dominant = comp["dominant_drift_family"]

            # headline metric + explanation from dominant family
            headline = {"metric_name": None, "metric_value": None, "previous_metric_value": None,
                        "metric_delta": None, "metric_delta_pct": None}
            expl_src = {"performance": perf, "shape": shape, "stability": best_stab, "volatility": best_vol}
            dom = expl_src.get(dominant, {})
            explanation = dom.get("explanation")
            reason_code = dom.get("reason_code")
            if dominant == "performance":
                headline = {k: perf.get(k) for k in headline}

            nat_key = f"{CALCULATION_VERSION}|{SCENARIO_SCOPE}|{key}|{v_n}|{dominant or comp['drift_status']}"
            rec_hash = _hash(nat_key, comp["forecast_drift_score"], fam_scores["performance"],
                             fam_scores["shape"], fam_scores["stability"], fam_scores["volatility"])

            drift_event_id = len(signals) + 1
            signals.append({
                "drift_event_id": drift_event_id,
                "event_natural_key": nat_key,
                "record_hash": rec_hash,
                "calculation_run_id": run_id,
                "calculation_version": CALCULATION_VERSION,
                "detected_on": now_ts.isoformat(),
                "scenario": SCENARIO_SCOPE,
                "forecast_key": key,
                "forecast_key_raw": raw_key,
                "service": None,
                "region": region,
                "forest": None,
                "resource": RESOURCE_SCOPE,
                "forecast_version": v_n,
                "previous_forecast_version": v_prev,
                "target_date": best_stab.get("target_date"),
                "drift_type": dominant if dominant else "composite",
                "dominant_drift_family": dominant,
                "drift_status": comp["drift_status"],
                "severity": sev,
                "persistence_type": None,  # filled in second pass
                "event_status": "Open" if evflag else None,
                "is_event": int(evflag),
                "metric_name": headline["metric_name"],
                "metric_value": headline["metric_value"],
                "previous_metric_value": headline["previous_metric_value"],
                "metric_delta": headline["metric_delta"],
                "metric_delta_pct": headline["metric_delta_pct"],
                "performance_drift_score": fam_scores["performance"],
                "shape_drift_score": fam_scores["shape"],
                "stability_drift_score": fam_scores["stability"],
                "volatility_drift_score": fam_scores["volatility"],
                "forecast_drift_score": comp["forecast_drift_score"],
                "score_coverage_pct": comp["score_coverage_pct"],
                "confidence_level": comp["confidence_level"],
                "missing_family_flag": comp["missing_family_flag"],
                "reason_code": reason_code,
                "explanation": explanation,
                "recommended_action": _recommend(dominant, comp["drift_status"]),
                "source_database": "(env)",
                "source_schema": SOURCE_SCHEMA,
                "source_object": FACT_TABLE,
                "source_forecast_version": v_n,
                "source_row_count": int(len(sub)),
                "normalization_version": NORMALIZATION_VERSION,
                "formula_version": FORMULA_VERSION,
                "performance_mode": perf_mode,
                "threshold_config_id": THRESHOLD_CONFIG_VERSION,
                "weight_config_id": WEIGHT_CONFIG_VERSION,
                "created_at": now_ts.isoformat(),
                "created_by": "drift_engine",
                "updated_at": None,
                "updated_by": None,
                "is_current": 1,
            })

            for fam, res in (("performance", perf), ("shape", shape), ("stability", best_stab), ("volatility", best_vol)):
                family_rows.append({
                    "drift_event_id": drift_event_id,
                    "forecast_key": key,
                    "forecast_version": v_n,
                    "drift_family": fam,
                    "family_score": res.get("score"),
                    "raw_magnitude": res.get("raw_magnitude"),
                    "eligibility_status": res.get("eligibility_status"),
                    "not_computable_reason": res.get("not_computable_reason"),
                    "version_count": res.get("version_count"),
                    "horizon_point_count": res.get("horizon_point_count"),
                    "shape_distance": res.get("shape_distance"),
                    "divergence_start_date": res.get("divergence_start_date"),
                    "max_curve_delta": res.get("max_curve_delta"),
                    "max_curve_delta_pct": res.get("max_curve_delta_pct"),
                    "value_delta": res.get("value_delta"),
                    "value_delta_pct": res.get("value_delta_pct"),
                    "cumulative_revision_pct": res.get("cumulative_revision_pct"),
                    "structural_break_flag": res.get("structural_break_flag"),
                    "rolling_stddev": res.get("rolling_stddev"),
                    "rolling_cov": res.get("rolling_cov"),
                    "rolling_mad": res.get("rolling_mad"),
                    "oscillation_count": res.get("oscillation_count"),
                    "sign_change_freq": res.get("sign_change_freq"),
                    "volatility_class": res.get("volatility_class"),
                })

    signals_df = pd.DataFrame(signals)
    family_df = pd.DataFrame(family_rows)
    signals_df = _apply_persistence(signals_df)
    return signals_df, family_df


def _recommend(dominant, status) -> str | None:
    if status not in ("Warning", "Critical"):
        return None
    return {
        "performance": "Review forecast accuracy inputs and model calibration.",
        "shape": "Investigate the change in forecast trajectory versus prior version.",
        "stability": "Review the revised target-date value and drivers of the jump.",
        "volatility": "Investigate forecast instability across recent versions.",
    }.get(dominant, "Investigate forecast drift.")


def _apply_persistence(signals_df: pd.DataFrame) -> pd.DataFrame:
    """Second pass: consecutive Warning+ versions per key -> persistence_type."""
    if signals_df.empty:
        return signals_df
    signals_df = signals_df.sort_values(["forecast_key", "forecast_version"]).reset_index(drop=True)
    warn = signals_df["drift_status"].isin(["Warning", "Critical"])
    run = 0
    ptypes = []
    prev_key = None
    for idx, row in signals_df.iterrows():
        if row["forecast_key"] != prev_key:
            run = 0
            prev_key = row["forecast_key"]
        if warn.iloc[idx]:
            run += 1
            ptypes.append(persistence_type(run))
        else:
            run = 0
            ptypes.append(None)
    signals_df["persistence_type"] = ptypes
    return signals_df
