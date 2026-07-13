"""Reproducible local refresh runner for the Forecast Drift engine (E5B #10).

Single governed entrypoint. Read-only against Tesseract; writes only governed
datasets under V1/data/processed/{current,metadata,validation,history}.

Sources:
  * ``--source live``      : read-only SELECT from Tesseract (needs env + VPN + Entra).
  * ``--source synthetic`` : deterministic offline fixture (no DB) for validation.

Pipeline: validate config -> extract -> normalize (canonicalize) -> compute
drift -> data-quality checks -> (idempotency 2nd pass) -> atomic export ->
metadata. Valid outputs are NOT overwritten when checks fail (unless --force).

Exit codes:
  0 success · 1 data-quality/idempotency failure · 2 connection/config error ·
  3 unexpected error · 0 (dry-run prints plan and exits).

Usage:
  python -m drift_engine.scripts.run_refresh --source synthetic --profile expanded
  python -m drift_engine.scripts.run_refresh --source live --profile expanded --perf-mode shallow
  python -m drift_engine.scripts.run_refresh --dry-run
"""

from __future__ import annotations

import argparse
import sys
import time
import tracemalloc
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))  # V1/python

import pandas as pd

from drift_engine.canonicalize import add_canonical_keys
from drift_engine.checks import run_checks
from drift_engine.config.settings import Paths, SampleConfig, sql_server, sql_database
from drift_engine.engine import compute_signals
from drift_engine.export import export_all, resolve_layout
from drift_engine.logger import get_logger
from drift_engine.normalization import normalize_forecasts, normalize_metrics

log = get_logger("drift_engine.run_refresh")

EXIT_OK, EXIT_QUALITY, EXIT_CONN, EXIT_UNEXPECTED = 0, 1, 2, 3


def _parse_args(argv=None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="AEGIS Forecast Drift local refresh (E5B)")
    p.add_argument("--source", choices=["live", "synthetic"], default="synthetic")
    p.add_argument("--profile", choices=["sample", "expanded"], default="expanded")
    p.add_argument("--perf-mode", choices=["shallow", "deep"], default="shallow")
    p.add_argument("--n-keys", type=int, default=None)
    p.add_argument("--n-versions", type=int, default=None)
    p.add_argument("--seed", type=int, default=42, help="synthetic determinism seed")
    p.add_argument("--dry-run", action="store_true", help="print the plan and exit")
    p.add_argument("--snapshot", action="store_true", help="also copy outputs to history/<ts>")
    p.add_argument("--force", action="store_true", help="export even if checks fail")
    return p.parse_args(argv)


def _config(args) -> SampleConfig:
    cfg = SampleConfig.expanded() if args.profile == "expanded" else SampleConfig()
    if args.n_keys:
        cfg.n_keys = args.n_keys
    if args.n_versions:
        cfg.n_versions = args.n_versions
    cfg.perf_mode = args.perf_mode
    return cfg


def validate_config(args, cfg: SampleConfig) -> list[str]:
    issues = []
    if cfg.n_keys < 1 or cfg.n_versions < 2:
        issues.append("n_keys>=1 and n_versions>=2 required")
    if args.source == "live" and (not sql_server() or not sql_database()):
        issues.append("live source needs AEGIS_DRIFT_SQL_SERVER and AEGIS_DRIFT_SQL_DATABASE env vars")
    if args.perf_mode not in ("shallow", "deep"):
        issues.append("perf-mode must be shallow or deep")
    return issues


def _extract(args, cfg: SampleConfig) -> dict:
    if args.source == "synthetic":
        from drift_engine.fixtures.synthetic import build_synthetic
        log.info("SYNTHETIC source (offline, deterministic seed=%s)", args.seed)
        return build_synthetic(n_versions=cfg.n_versions, seed=args.seed)
    from drift_engine.ingestion.extract import extract_sample
    log.info("LIVE read-only source (Enterprise/HDD, %s keys x %s versions)", cfg.n_keys, cfg.n_versions)
    return extract_sample(cfg.n_keys, cfg.n_versions, cfg.keys or None)


def _build_runs(cfg, data, signals, elapsed, peak_mb, checks_pass, checks_total, idempotent) -> pd.DataFrame:
    return pd.DataFrame([{
        "calculation_run_id": 1,
        "calculation_version": "E5A-v1",
        "formula_version": "f1.0",
        "threshold_config_id": "t1.0",
        "weight_config_id": "w1.0",
        "run_started_at": pd.Timestamp.now("UTC").isoformat(),
        "run_finished_at": pd.Timestamp.now("UTC").isoformat(),
        "source_forecast_version_max": max(data["versions"]) if data["versions"] else None,
        "signals_written": int(len(signals)),
        "events_created": int(signals["is_event"].sum()) if not signals.empty else 0,
        "runtime_seconds": round(elapsed, 2),
        "peak_memory_mb": round(peak_mb, 2),
        "checks_passed": checks_pass,
        "checks_total": checks_total,
        "idempotent": bool(idempotent),
        "perf_mode": cfg.perf_mode,
        "run_status": "Success" if checks_pass == checks_total and idempotent else "Completed_with_warnings",
        "created_by": "drift_engine",
    }])


def _event_history(signals: pd.DataFrame) -> pd.DataFrame:
    cols = ["event_history_id", "drift_event_id", "old_status", "new_status", "changed_at", "changed_by", "note"]
    if signals.empty:
        return pd.DataFrame(columns=cols)
    ev = signals[signals["is_event"] == 1]
    return pd.DataFrame([{
        "event_history_id": i + 1, "drift_event_id": int(row["drift_event_id"]),
        "old_status": None, "new_status": "Open", "changed_at": row["detected_on"],
        "changed_by": "drift_engine", "note": "auto-created on detection",
    } for i, (_, row) in enumerate(ev.iterrows())])


def run(argv=None) -> int:
    args = _parse_args(argv)
    cfg = _config(args)

    issues = validate_config(args, cfg)
    if args.dry_run:
        print("DRY_RUN_PLAN")
        print(f"  source      : {args.source}")
        print(f"  profile     : {args.profile}  (n_keys={cfg.n_keys}, n_versions={cfg.n_versions})")
        print(f"  perf_mode   : {cfg.perf_mode}")
        print(f"  snapshot    : {args.snapshot}")
        print(f"  output root : {Paths().processed}")
        print(f"  config OK   : {not issues}")
        for i in issues:
            print(f"  ISSUE       : {i}")
        return EXIT_OK if not issues else EXIT_CONN
    if issues:
        for i in issues:
            log.error("config issue: %s", i)
        return EXIT_CONN

    paths = Paths()
    layout = resolve_layout(paths.processed)
    tracemalloc.start()
    t0 = time.time()
    try:
        data = _extract(args, cfg)
        fwd, stats = normalize_forecasts(data["forecasts"])
        metrics = normalize_metrics(data["metrics"])
        actuals = data.get("actuals")
        if actuals is not None and not actuals.empty and "Key" in actuals.columns:
            actuals = add_canonical_keys(actuals, key_col="Key")
            actuals["Key"] = actuals["forecast_key_canonical"]
        log.info("normalization: raw_keys=%s canonical_keys=%s merged=%s forward_rows=%s",
                 stats.get("distinct_keys_raw"), stats.get("distinct_keys_canonical"),
                 stats.get("keys_merged"), stats.get("rows_forward_only"))

        signals, family = compute_signals(fwd, metrics, run_id=1, perf_mode=cfg.perf_mode, actuals=actuals)
        checks = run_checks(signals, family)
        n_pass = sum(1 for c in checks if c["result"] == "PASS")

        signals2, _ = compute_signals(fwd, metrics, run_id=1, perf_mode=cfg.perf_mode, actuals=actuals)
        idempotent = (not signals.empty
                      and signals["record_hash"].tolist() == signals2["record_hash"].tolist())

        elapsed = time.time() - t0
        _, peak = tracemalloc.get_traced_memory()
        peak_mb = peak / 1e6
    except Exception as exc:  # connection or unexpected
        tracemalloc.stop()
        msg = str(exc)
        if any(s in msg for s in ("pyodbc", "ODBC", "Login", "server", "connection", "Connection")):
            log.error("connection error (no secret logged): %s", type(exc).__name__)
            return EXIT_CONN
        log.exception("unexpected error: %s", type(exc).__name__)
        return EXIT_UNEXPECTED
    finally:
        if tracemalloc.is_tracing():
            tracemalloc.stop()

    # write validation artifacts
    pd.DataFrame(checks).to_csv(layout["validation"] / "_data_quality_checks.csv", index=False)

    quality_ok = (n_pass == len(checks)) and idempotent
    if not quality_ok and not args.force:
        log.error("QUALITY GATE FAILED (checks %s/%s, idempotent=%s) — outputs NOT overwritten (use --force)",
                  n_pass, len(checks), idempotent)
        return EXIT_QUALITY

    runs = _build_runs(cfg, data, signals, elapsed, peak_mb, n_pass, len(checks), idempotent)
    event_history = _event_history(signals)
    extra = {
        "source": args.source,
        "profile": args.profile,
        "perf_mode": cfg.perf_mode,
        "synthetic": bool(data.get("synthetic", False)),
        "sample_keys": data["keys"],
        "sample_versions": [str(v) for v in data["versions"]],
        "normalization_stats": {k: v for k, v in stats.items() if k != "key_collision_report"},
        "key_collision_report": stats.get("key_collision_report"),
        "checks_passed": n_pass,
        "checks_total": len(checks),
        "idempotent": bool(idempotent),
        "runtime_seconds": round(elapsed, 2),
        "peak_memory_mb": round(peak_mb, 2),
        "status_distribution": signals["drift_status"].value_counts().to_dict() if not signals.empty else {},
    }
    export_all(paths.processed, signals, family, runs, event_history, extra, snapshot=args.snapshot)

    log.info("REFRESH DONE source=%s checks=%s/%s idempotent=%s runtime=%.2fs peak=%.1fMB signals=%s",
             args.source, n_pass, len(checks), idempotent, elapsed, peak_mb, len(signals))
    return EXIT_OK if quality_ok else EXIT_QUALITY


if __name__ == "__main__":
    raise SystemExit(run())
