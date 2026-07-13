"""Governed output writer (E5B hardened).

Design goals (E5B #7, #8, #9):
  * **Atomic** writes: every file is written to a ``.tmp`` sibling then
    ``os.replace``d into place, so a crashed run never leaves a partial file.
  * **Stable names** in a predictable folder layout consumed by Power BI/Grafana:
        V1/data/processed/current/     <- always-latest governed datasets
        V1/data/processed/metadata/    <- run_metadata.json
        V1/data/processed/validation/  <- data-quality / idempotency / fixtures
        V1/data/processed/history/     <- optional timestamped snapshots
  * **Parquet preferred, CSV fallback**: Parquet is emitted when pyarrow is
    present; CSV is always emitted so the contract never breaks.

Read-only against source; writes only to the Drift project's processed folder.
"""

from __future__ import annotations

import importlib.util
import json
import os
import shutil
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

DATASET_NAMES = (
    "forecast_drift_signals",
    "forecast_drift_family_scores",
    "forecast_drift_runs",
    "forecast_drift_event_history",
)


def _atomic_write_csv(df: pd.DataFrame, path: Path) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    df.to_csv(tmp, index=False)
    os.replace(tmp, path)  # atomic on same filesystem


def _atomic_write_parquet(df: pd.DataFrame, path: Path) -> bool:
    tmp = path.with_suffix(path.suffix + ".tmp")
    try:
        df.to_parquet(tmp, index=False)
        os.replace(tmp, path)
        return True
    except Exception as exc:  # pragma: no cover
        log.warning("parquet write failed for %s: %s", path.name, exc)
        if tmp.exists():
            tmp.unlink(missing_ok=True)
        return False


def _write_dataset(df: pd.DataFrame, out_dir: Path, name: str) -> list[str]:
    written = []
    _atomic_write_csv(df, out_dir / f"{name}.csv")
    written.append(f"{name}.csv")
    if HAS_PARQUET and _atomic_write_parquet(df, out_dir / f"{name}.parquet"):
        written.append(f"{name}.parquet")
    return written


def resolve_layout(processed_root: Path) -> dict:
    """Return the E5B folder layout under a processed root, creating dirs."""
    layout = {
        "root": processed_root,
        "current": processed_root / "current",
        "metadata": processed_root / "metadata",
        "validation": processed_root / "validation",
        "history": processed_root / "history",
    }
    for p in (layout["current"], layout["metadata"], layout["validation"]):
        p.mkdir(parents=True, exist_ok=True)
    return layout


def export_all(processed_root: Path, signals: pd.DataFrame, family_scores: pd.DataFrame,
               runs: pd.DataFrame, event_history: pd.DataFrame, extra_meta: dict,
               snapshot: bool = False) -> dict:
    """Write the four governed datasets + run_metadata atomically into ``current/``.

    When ``snapshot`` is True, also copy the current datasets into a timestamped
    ``history/<ts>/`` folder for retention.
    """
    layout = resolve_layout(processed_root)
    cur = layout["current"]
    written = {
        "forecast_drift_signals": _write_dataset(signals, cur, "forecast_drift_signals"),
        "forecast_drift_family_scores": _write_dataset(family_scores, cur, "forecast_drift_family_scores"),
        "forecast_drift_runs": _write_dataset(runs, cur, "forecast_drift_runs"),
        "forecast_drift_event_history": _write_dataset(event_history, cur, "forecast_drift_event_history"),
    }

    meta = {
        "calculation_version": CALCULATION_VERSION,
        "formula_version": FORMULA_VERSION,
        "normalization_version": NORMALIZATION_VERSION,
        "threshold_config_version": THRESHOLD_CONFIG_VERSION,
        "weight_config_version": WEIGHT_CONFIG_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "parquet_available": HAS_PARQUET,
        "output_format_primary": "parquet" if HAS_PARQUET else "csv",
        "signal_rows": int(len(signals)),
        "family_score_rows": int(len(family_scores)),
        "event_rows": int(signals["is_event"].sum()) if not signals.empty else 0,
        "layout": {k: str(v) for k, v in layout.items()},
        "files": written,
    }
    meta.update(extra_meta)
    meta_path = layout["metadata"] / "run_metadata.json"
    tmp = meta_path.with_suffix(".json.tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, default=str)
    os.replace(tmp, meta_path)

    if snapshot:
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        snap = layout["history"] / ts
        snap.mkdir(parents=True, exist_ok=True)
        for name in DATASET_NAMES:
            for ext in ("csv", "parquet"):
                src = cur / f"{name}.{ext}"
                if src.exists():
                    shutil.copy2(src, snap / src.name)
        shutil.copy2(meta_path, snap / "run_metadata.json")
        meta["snapshot_dir"] = str(snap)

    log.info("exported %s dataset files (parquet=%s) to %s",
             sum(len(v) for v in written.values()), HAS_PARQUET, cur)
    return meta
