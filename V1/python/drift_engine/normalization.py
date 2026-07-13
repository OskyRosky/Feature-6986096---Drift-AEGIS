"""Normalization layer (E2): dedupe, forward-only, version pairing, region parse.

Operates on pandas DataFrames from ingestion. Pure transforms + quality stats.
"""

from __future__ import annotations

import pandas as pd

from .canonicalize import add_canonical_keys, collision_report
from .config.settings import DUPLICATE_FORECAST_VERSION
from .logger import get_logger

log = get_logger("drift_engine.normalize")


def _to_date(s: pd.Series) -> pd.Series:
    return pd.to_datetime(s, errors="coerce").dt.date


def normalize_forecasts(forecasts: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """Apply dedupe (G1), forward-only (G6), version_rank, region parse."""
    df = forecasts.copy()
    stats = {"rows_in": len(df)}
    # E5B (I1): non-destructive canonicalization. Preserve the exact original in
    # forecast_key_raw, derive forecast_key_canonical (trim + collapse spaces +
    # upper), and route all downstream grouping through the canonical form. The
    # active grouping column "Key" is set to the canonical value so version
    # pairing merges case/whitespace variants; the raw value is never lost.
    df = add_canonical_keys(df, key_col="Key")
    report = collision_report(df)
    stats["distinct_keys_raw"] = report["distinct_keys_raw"]
    stats["distinct_keys_canonical"] = report["distinct_keys_canonical"]
    stats["keys_merged"] = report["keys_merged"]
    stats["collision_groups"] = report["collision_groups"]
    stats["suspicious_merges"] = report["suspicious_merges"]
    stats["key_collision_report"] = report["merges"]
    df["Key"] = df["forecast_key_canonical"]
    df["target_date"] = pd.to_datetime(df["target_date"], errors="coerce")
    df["forecast_version"] = pd.to_datetime(df["forecast_version"], errors="coerce")
    df = df.dropna(subset=["target_date", "forecast_version", "forecast_value"])
    stats["rows_after_nulls"] = len(df)

    # G1: dedupe (drop exact duplicate rows on the natural grain)
    grain = ["Key", "target_date", "forecast_version", "model_version", "Scenario", "Resource"]
    df = df.drop_duplicates(subset=grain, keep="first")
    stats["rows_after_dedupe"] = len(df)
    stats["duplicate_version_present"] = bool(
        (df["forecast_version"] == pd.Timestamp(DUPLICATE_FORECAST_VERSION)).any()
    )

    # G6: forward-only  (target_date >= forecast_version)
    df["is_forward"] = df["target_date"] >= df["forecast_version"]
    df["horizon_days"] = (df["target_date"] - df["forecast_version"]).dt.days
    df_fwd = df[df["is_forward"]].copy()
    stats["rows_forward_only"] = len(df_fwd)

    # region parse from Key prefix (e.g. APC-Dedicated -> APC)
    df_fwd["region"] = df_fwd["Key"].astype(str).str.split("-").str[0]

    # version_rank per key (ascending by version)
    df_fwd["forecast_version"] = df_fwd["forecast_version"].dt.date
    df_fwd["target_date"] = df_fwd["target_date"].dt.date
    ranks = (
        df_fwd[["Key", "forecast_version"]]
        .drop_duplicates()
        .sort_values(["Key", "forecast_version"])
    )
    ranks["version_rank"] = ranks.groupby("Key").cumcount() + 1
    df_fwd = df_fwd.merge(ranks, on=["Key", "forecast_version"], how="left")
    stats["distinct_keys"] = df_fwd["Key"].nunique()
    stats["distinct_versions"] = df_fwd["forecast_version"].nunique()
    return df_fwd, stats


def consecutive_version_pairs(df_fwd: pd.DataFrame) -> pd.DataFrame:
    """Return distinct (Key, version_rank) pairs mapping v_n to its previous v_(n-1)."""
    vpairs = (
        df_fwd[["Key", "forecast_version", "version_rank"]]
        .drop_duplicates()
        .sort_values(["Key", "version_rank"])
    )
    vpairs["prev_version"] = vpairs.groupby("Key")["forecast_version"].shift(1)
    return vpairs


def normalize_metrics(metrics: pd.DataFrame) -> pd.DataFrame:
    df = metrics.copy()
    if df.empty:
        return df
    # E5B (I1): canonicalize to the same key space as forecasts (raw preserved).
    df = add_canonical_keys(df, key_col="Key")
    df["Key"] = df["forecast_key_canonical"]
    df["forecast_version"] = pd.to_datetime(df["forecast_version"], errors="coerce").dt.date
    df = df.dropna(subset=["forecast_version"])
    df = df.sort_values(["Key", "forecast_version"])
    return df
