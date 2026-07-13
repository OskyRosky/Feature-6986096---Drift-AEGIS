"""Offline synthetic dataset for deterministic E5B validation (no DB).

Produces forecasts / actuals / metrics DataFrames with the SAME schema the
read-only Tesseract extract returns, so the whole pipeline (canonicalization,
normalization, families, composite, export, checks, idempotency) can be
validated without a live connection.

Deliberately includes:
  * **case/whitespace variants** of one logical key (``CAN-Go Local`` vs
    ``CAN-GO LOCAL`` vs ``  can-go local ``) to prove I1 folding;
  * multiple versions per key so Stability/Volatility are computable;
  * one shallow key (2 versions) to force NOT_COMPUTABLE for Volatility;
  * realized actuals so deep Performance (I3) is computable;
  * a sparse official-metrics table (few retained versions) mirroring reality.

Deterministic: fixed seed. This is SYNTHETIC data, clearly labelled; it never
claims to be real Tesseract output.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

SCENARIO = "Enterprise"
RESOURCE = "HDD"

# (raw_key_spelling, canonical_group_id, profile)
_KEY_SPECS = [
    ("CAN-Go Local", "CAN-GO LOCAL", "shape"),
    ("CAN-GO LOCAL", "CAN-GO LOCAL", "shape"),      # case variant -> merges (I1)
    ("  can-go local ", "CAN-GO LOCAL", "shape"),   # whitespace+case variant -> merges
    ("NAM-Dedicated", "NAM-DEDICATED", "stability"),
    ("EUR-Multitenant", "EUR-MULTITENANT", "volatility"),
    ("APC-Dedicated", "APC-DEDICATED", "calm"),
    ("LAM-Multitenant", "LAM-MULTITENANT", "shape"),
    ("JPN-Go Local", "JPN-GO LOCAL", "stability"),
    ("IND-Dedicated", "IND-DEDICATED", "shallow"),  # only 2 versions -> vol NOT_COMPUTABLE
]


def _versions(n: int) -> list[pd.Timestamp]:
    """n monthly forecast versions ending 2026-05-01."""
    end = pd.Timestamp("2026-05-01")
    return list(pd.date_range(end=end, periods=n, freq="MS"))


def build_synthetic(n_versions: int = 10, horizon_months: int = 24, seed: int = 42) -> dict:
    rng = np.random.default_rng(seed)
    versions = _versions(n_versions)
    f_rows, a_rows, m_rows = [], [], []
    actual_cutoff = pd.Timestamp("2026-04-01")  # actuals realized up to here

    # actuals are per canonical key (shared across raw variants)
    canon_seen: dict[str, float] = {}

    for raw_key, canon, profile in _KEY_SPECS:
        base = canon_seen.get(canon)
        if base is None:
            base = float(rng.uniform(4000, 40000))
            canon_seen[canon] = base
        trend = float(rng.uniform(20, 200))
        key_versions = versions[-2:] if profile == "shallow" else versions

        for vi, fv in enumerate(key_versions):
            targets = pd.date_range(start=fv, periods=horizon_months, freq="MS")
            # version-to-version behaviour per profile
            if profile == "shape":
                curve_shift = 1.0 + 0.03 * vi + (0.015 * np.arange(horizon_months) if vi >= 2 else 0.0)
            elif profile == "stability":
                curve_shift = 1.0 + (0.18 if vi == len(key_versions) - 1 else 0.02 * vi)
            elif profile == "volatility":
                curve_shift = 1.0 + 0.12 * np.sin(vi) + rng.normal(0, 0.05)
            else:  # calm
                curve_shift = 1.0 + 0.005 * vi
            noise = rng.normal(0, base * 0.01, horizon_months)
            values = (base + trend * np.arange(horizon_months)) * curve_shift + noise
            values = np.maximum(values, 1.0)
            for t, val in zip(targets, values):
                f_rows.append({
                    "Key": raw_key, "target_date": t, "forecast_version": fv,
                    "forecast_value": float(val), "model_version": "prod",
                    "Scenario": SCENARIO, "Resource": RESOURCE,
                })

        # actuals per canonical key (once)
        if canon not in {r["Key"] for r in a_rows}:
            a_targets = pd.date_range(start=versions[0], end=actual_cutoff, freq="MS")
            a_base = base * float(rng.uniform(0.97, 1.03))
            for j, t in enumerate(a_targets):
                a_rows.append({
                    "Key": canon, "target_date": t,
                    "actual_value": float(max(1.0, a_base + trend * j + rng.normal(0, base * 0.008))),
                    "Scenario": SCENARIO, "Resource": RESOURCE,
                })

        # sparse official metrics (only last 3 versions retained) — canonical key
        for fv in key_versions[-3:]:
            m_rows.append({
                "Key": canon, "forecast_version": fv,
                "MAPE": float(rng.uniform(0.03, 0.35)), "Bias": float(rng.normal(0, 500)),
                "Bias_Pct": float(rng.normal(0, 0.05)), "Accuracy": float(rng.uniform(0.6, 0.97)),
                "MAE": float(rng.uniform(100, 900)), "RMSE": float(rng.uniform(150, 1200)),
                "SMAPE": float(rng.uniform(0.03, 0.4)),
                "Start_Date": versions[0], "End_Date": actual_cutoff,
            })

    return {
        "keys": sorted({c for _, c, _ in _KEY_SPECS}),
        "versions": versions,
        "forecasts": pd.DataFrame(f_rows),
        "actuals": pd.DataFrame(a_rows),
        "metrics": pd.DataFrame(m_rows),
        "synthetic": True,
    }
