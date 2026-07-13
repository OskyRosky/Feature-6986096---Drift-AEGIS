# E5A — Python Drift Engine Design

**Feature 6986096 — AEGIS Forecast Drift Framework**
**Stage:** E5A — Python Drift Engine Build
**Date:** 2026-07-12
**Principle:** *The dashboard does not cook data.* Tesseract = source (read-only). Python = ingestion / cleaning / transforms / calculation / validation. Parquet/CSV = output contract. Power BI / Grafana = consumption only.
**Guardrails honored:** SELECT only; no DDL; no writes to Tesseract; no Power BI/Grafana; no commit; no full-history run.

> Governance: no secrets/hosts/connection strings in code — DB host & database come from env vars `AEGIS_DRIFT_SQL_SERVER` / `AEGIS_DRIFT_SQL_DATABASE`. Entra ID `ActiveDirectoryInteractive`, ODBC Driver 18.

---

## 1. Package layout (`V1/python/drift_engine/`)

```
drift_engine/
  __init__.py
  config/
    settings.py     # scope, weights, anchors, gates, windows, versions, paths (all from E3/E4)
    db_config.py    # Entra Interactive connection string (host from env)
  ingestion/
    queries.py      # parameterized SELECT-only queries
    extract.py      # read-only sample extraction -> DataFrames
  normalization.py  # dedupe (G1), forward-only (G6), version_rank, region parse, grain
  scoring.py        # piecewise 0-100 + status bands
  families.py       # pure functions: performance/shape/stability/volatility drift
  composite.py      # composite score, coverage, confidence, dominant, events, persistence
  engine.py         # orchestration: normalized data -> signals + family_scores
  checks.py         # data-quality validations
  export.py         # governed CSV/Parquet writer + run_metadata.json
  logger.py         # logging (no secrets)
  tests/test_fixtures.py   # E3 fixtures (pytest OR standalone)
  scripts/run_sample.py    # controlled real-sample run + idempotency check
```

**Design principles:** the four family formulas + normalization + composite are **pure functions** (no I/O) so they are unit-testable against the E3 fixtures without a database. Ingestion/engine/export are the only I/O layers. No magic numbers — every parameter lives in `config/settings.py` traceable to E3/E4.

## 2. Reuse from Code Improvement (referenced, not copied)

| Pattern | Source (Code Improvement) | Adaptation in Drift |
| --- | --- | --- |
| Entra Interactive connection | `ingestion/config.py` | Host moved to **env var** (no host in repo); same driver/auth |
| Parameterized SELECT | `ingestion/queries.py` | New drift-specific multi-version queries; pyodbc params (no string-format) |
| Ingest structure | `ingestion/export_*.py` | Read-only extract to DataFrames (no CSV-to-raw side effects) |
| Logging | `utils/logger.py` | Minimal stdout logger; never logs secrets |
| Data contract discipline | `data/processed` + run_metadata | Governed CSV/Parquet + `run_metadata.json` with lineage/versions |

## 3. Pipeline

```
extract_sample (SELECT only)
  -> normalize_forecasts  (dedupe G1, is_forward G6, version_rank, region)
  -> normalize_metrics
  -> compute_signals      (per key x forecast_version: shape/stability/volatility/performance -> composite -> event)
  -> run_checks           (schema/grain/ranges/hash/weights/NaN/…)
  -> export_all           (CSV [+Parquet], run_metadata.json)
  -> idempotency check    (recompute -> compare record hashes)
```

## 4. Formula implementation (exactly E3 MVP)

- **Performance:** relative MAPE change with near-zero gate; shallow mode from official metrics; interface ready for deep recompute. Secondary metrics (Bias/Accuracy/SMAPE) available.
- **Shape:** level-normalized weighted curve RMSE; forward-aligned; ≥4 points; max_curve_delta, max_curve_delta_pct, divergence_start_date.
- **Stability:** latest consecutive revision %; cumulative revision; structural-break flag; forward-only.
- **Volatility:** coefficient of variation (sample std) over N=6; MAD/median companion; sign-change frequency; ≥4 versions; single-spike vs sustained.
- **Composite:** weights 20/40/30/10 renormalized over available families; coverage/confidence/dominant/contributing/missing-family.
- **Events:** create when composite ≥ 40 or any family ≥ 70; severity = status when event; persistence single_spike/sustained.

## 5. Output (E4 contract as files) — see `E5A_output_contract.md`

`forecast_drift_signals`, `forecast_drift_family_scores`, `forecast_drift_runs`, `forecast_drift_event_history` (each CSV + Parquet when pyarrow), plus `run_metadata.json`. Every signal carries calculation/formula/normalization/threshold/weight versions, source lineage, `record_hash`, `run_id`, `generated_at`.

## 6. Idempotency

Same input + same config + same formula version ⇒ identical `record_hash` per signal (SHA-256 of natural key + scores). The run script recomputes and asserts hash equality. No duplicate events within a run (grain-unique). Reproducible.

## 7. Dependencies observed

numpy 2.4.6 ✓, pandas 3.0.3 ✓, pyodbc 5.3.0 ✓. **pyarrow NOT installed** ⇒ CSV is primary, Parquet best-effort (documented, not blocking). **pytest NOT installed** ⇒ fixtures run via a standalone runner (`python -m drift_engine.tests.test_fixtures`).

## 8. E3 reconciliation

E3 config CSV listed `confidence_high_coverage=100`, but E3 fixture FX-COMP-02 (coverage 90%) expected `HIGH`. The engine harmonizes to **HIGH ≥ 90** (documented in `E5A_open_issues.md`) so the fixture and engine agree.
