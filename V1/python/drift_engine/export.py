"""Governed output writer (E4 contract as files). Parquet if pyarrow, else CSV.

Writes signals, family_scores, runs, event_history + run_metadata.json.
"""

from __future__ import annotations

import importlib.util
import json
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

from .config.settings import (
    CALCULATION_VERSION,
    FORMULA_VERSION,
    NORMALIZATION_VERSION,
    THRESHOLD_CONFIG_VERSION,
    WEIGHT_CONFIG_VERSION,
)
from .logger import get_logger

log = get_logger("drift_engine.export")
HAS_PARQUET = importlib.util.find_spec("pyarrow") is not None


def _write(df: pd.DataFrame, out_dir: Path, name: str) -> list[str]:
    written = []
    csv_path = out_dir / f"{name}.csv"
    df.to_csv(csv_path, index=False)
    written.append(str(csv_path.name))
    if HAS_PARQUET:
        try:
            df.to_parquet(out_dir / f"{name}.parquet", index=False)
            written.append(f"{name}.parquet")
        except Exception as exc:  # pragma: no cover
            log.warning("parquet write failed for %s: %s", name, exc)
    return written


def export_all(out_dir: Path, signals: pd.DataFrame, family_scores: pd.DataFrame,
               runs: pd.DataFrame, event_history: pd.DataFrame, extra_meta: dict) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    written = {}
    written["forecast_drift_signals"] = _write(signals, out_dir, "forecast_drift_signals")
    written["forecast_drift_family_scores"] = _write(family_scores, out_dir, "forecast_drift_family_scores")
    written["forecast_drift_runs"] = _write(runs, out_dir, "forecast_drift_runs")
    written["forecast_drift_event_history"] = _write(event_history, out_dir, "forecast_drift_event_history")

    meta = {
        "calculation_version": CALCULATION_VERSION,
        "formula_version": FORMULA_VERSION,
        "normalization_version": NORMALIZATION_VERSION,
        "threshold_config_version": THRESHOLD_CONFIG_VERSION,
        "weight_config_version": WEIGHT_CONFIG_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "parquet_available": HAS_PARQUET,
        "signal_rows": int(len(signals)),
        "family_score_rows": int(len(family_scores)),
        "event_rows": int(signals["is_event"].sum()) if not signals.empty else 0,
        "files": written,
    }
    meta.update(extra_meta)
    with (out_dir / "run_metadata.json").open("w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, default=str)
    log.info("exported %s (parquet=%s)", out_dir, HAS_PARQUET)
    return meta
