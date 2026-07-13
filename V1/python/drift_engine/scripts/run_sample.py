"""Controlled real-sample run of the Forecast Drift engine (E5A section 7).

Read-only. Extracts a small governed sample, computes drift, validates, exports.
Also runs an idempotency check (two passes -> identical record hashes).

Usage:
    set AEGIS_DRIFT_SQL_SERVER / AEGIS_DRIFT_SQL_DATABASE env vars, then:
    python -m drift_engine.scripts.run_sample
"""

from __future__ import annotations

import sys
import time
import tracemalloc
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))  # V1/python

import pandas as pd

from drift_engine.config.settings import Paths, SampleConfig
from drift_engine.ingestion.extract import extract_sample
from drift_engine.normalization import normalize_forecasts, normalize_metrics
from drift_engine.engine import compute_signals
from drift_engine.checks import run_checks
from drift_engine.export import export_all
from drift_engine.logger import get_logger

log = get_logger("drift_engine.run_sample")


def main() -> int:
    cfg = SampleConfig()
    paths = Paths()
    tracemalloc.start()
    t0 = time.time()

    log.info("E5A controlled sample run START")
    data = extract_sample(cfg.n_keys, cfg.n_versions, cfg.keys or None)

    fwd, stats = normalize_forecasts(data["forecasts"])
    metrics = normalize_metrics(data["metrics"])
    log.info("normalization stats: %s", stats)

    signals, family = compute_signals(fwd, metrics, run_id=1)

    checks = run_checks(signals, family)
    n_pass = sum(1 for c in checks if c["result"] == "PASS")
    log.info("checks: %s/%s PASS", n_pass, len(checks))

    # idempotency: recompute and compare record hashes
    signals2, _ = compute_signals(fwd, metrics, run_id=1)
    hashes_match = (
        not signals.empty
        and signals["record_hash"].tolist() == signals2["record_hash"].tolist()
    )
    log.info("idempotency hashes_match=%s", hashes_match)

    elapsed = time.time() - t0
    cur_mem, peak_mem = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    runs = pd.DataFrame([{
        "calculation_run_id": 1,
        "calculation_version": "E5A-v1",
        "formula_version": "f1.0",
        "threshold_config_id": "t1.0",
        "weight_config_id": "w1.0",
        "run_started_at": pd.Timestamp.utcnow().isoformat(),
        "run_finished_at": pd.Timestamp.utcnow().isoformat(),
        "source_forecast_version_max": max(data["versions"]) if data["versions"] else None,
        "signals_written": int(len(signals)),
        "events_created": int(signals["is_event"].sum()) if not signals.empty else 0,
        "run_status": "Success",
        "created_by": "drift_engine",
    }])
    # event history seeded from open events
    if not signals.empty:
        ev = signals[signals["is_event"] == 1]
        event_history = pd.DataFrame([{
            "event_history_id": i + 1,
            "drift_event_id": int(row["drift_event_id"]),
            "old_status": None,
            "new_status": "Open",
            "changed_at": row["detected_on"],
            "changed_by": "drift_engine",
            "note": "auto-created on detection",
        } for i, (_, row) in enumerate(ev.iterrows())])
    else:
        event_history = pd.DataFrame(columns=["event_history_id", "drift_event_id", "old_status", "new_status", "changed_at", "changed_by", "note"])

    extra = {
        "sample_keys": data["keys"],
        "sample_versions": [str(v) for v in data["versions"]],
        "normalization_stats": stats,
        "checks_passed": n_pass,
        "checks_total": len(checks),
        "idempotent": bool(hashes_match),
        "runtime_seconds": round(elapsed, 2),
        "peak_memory_mb": round(peak_mem / 1e6, 2),
        "status_distribution": signals["drift_status"].value_counts().to_dict() if not signals.empty else {},
    }
    meta = export_all(paths.processed, signals, family, runs, event_history, extra)

    # write checks csv
    pd.DataFrame(checks).to_csv(paths.processed / "_data_quality_checks.csv", index=False)

    log.info("E5A sample run DONE in %.2fs; signals=%s events=%s", elapsed, len(signals), extra["status_distribution"])
    print("SAMPLE_RESULT_JSON_START")
    import json
    print(json.dumps(meta, indent=2, default=str))
    print("SAMPLE_RESULT_JSON_END")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
