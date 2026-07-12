# E1A — Closure Summary

**Feature 6986096 — AEGIS Forecast Drift Framework**
**Stage:** E1A — Source Discovery & Data Profiling (Document Discovery & Reuse)
**Date:** 2026-07-12
**Authorization:** "Autorizo iniciar E1A ... Trabaja únicamente sobre el Blueprint, el Prototype y el proyecto Code Improvement ... No ejecutes todavía consultas SQL sobre Tesseract."
**Constraint honored:** No live SQL executed. No connection opened. Findings grounded in existing Code Improvement source code + real CSV headers. Confidential: no server host / connection string / credentials reproduced.

---

## What was done
1. Reviewed the Blueprint V2 (16 sections) and the HTML prototype (page/UX inventory).
2. Mined the **Code Improvement** project for reusable knowledge:
   - `python/ingestion/queries.py` → real source table + column set + version-resolution logic.
   - `python/ingestion/config.py` → connection method (Entra ID Interactive, ODBC Driver 18).
   - `python/ingestion/export_official_metrics.py` → official metrics tables + columns.
   - `data/processed/*` headers → governed data-contract grain.
3. Produced the first **Source Profiling**, **Data Dictionary**, and **Open Questions** list.
4. Recorded the adopted **E0-E8 engineering roadmap**.

## Key findings (grounded)
- **Fact table** `forecast_substrateBE_hdd_region`: `DateTime, Key, Value, ModelVersion, ForecastVersion, Scenario, Resource, ValueType`. Actuals = `ModelVersion='actual'`; forecasts = `ModelVersion<>'actual'`, `ValueType='Forecast-Mean'`.
- **Enabler for Drift:** ingestion pins to `MAX(ForecastVersion)` → only latest is materialized in `data/processed`. The fact table holds **many** versions; Shape/Stability/Volatility Drift must read it **without** the MAX filter.
- **Metric mismatch resolved:** the Blueprint's Performance Drift metrics (MAPE, MAE, RMSE, Bias, SMAPE, Accuracy) **already exist upstream** in the `*_metrics` tables, each carrying `Forecast_Version` + `Start_Date/End_Date`. (Code Improvement's MASE/RMSSE tournament metrics are separate backtest metrics, not what Performance Drift needs.)
- **Grain:** fact = `Key × DateTime × ModelVersion × ForecastVersion × Scenario × Resource × ValueType`; metrics = `Key × Forecast_Version × window`.
- **Dimension gap:** `Service` and `Forest` need explicit mapping; region appears embedded in `Key`; a forest-grain metrics table exists (`_hdd_forest_metrics`).
- **Coverage per family:** Performance = well supported today; Shape/Stability/Volatility = depend on the single enabler (multi-version history), to confirm in E1B.

## Decisions
- E1 split into **E1A (docs, done)** and **E1B (live validation, pending SQL)**.
- Adopt **E0-E8** engineering naming, separate from product V1/V2/V3.
- Data Dictionary is a **deliverable of E1**, not a separate stage.
- Reuse Code Improvement by **reference**, not by copying pipeline logic; keep repos/commits independent.
- Deliverables live under `engineering/E1_source_discovery_profiling/` (separate from the reserved product `V1/V2/V3` folders).

## Files created (this project only)
- `engineering/ROADMAP.md`
- `engineering/E1_source_discovery_profiling/E1A_source_profiling.md`
- `engineering/E1_source_discovery_profiling/E1A_data_dictionary.csv`
- `engineering/E1_source_discovery_profiling/E1A_open_questions.md`
- `engineering/E1_source_discovery_profiling/E1A_closure_summary.md`

Files modified: none in the Drift project other than the new files above. Code Improvement project: **read-only**, untouched.

## Next steps
- **E1B — Live Data Validation** (requires VPN + SQL): answer B1-B10, prioritizing **B1** (ForecastVersion history depth/cadence) and **B2** (metrics version retention) — together they confirm whether all four drift families are computable.
- In parallel, route stakeholder questions **A1-A8** (Blueprint §16) to Boon / Sihui / Chinmay / Nayeli.
- After E1B, refine the Data Dictionary, then start **E2 — Forecast Drift Information Model**.

## Status token
**E1A_SOURCE_DISCOVERY_DOCUMENT_REUSE_COMPLETED** — no SQL executed; no champion/pipeline/data mutation; Code Improvement untouched; do not start E1B (live SQL) without VPN access + explicit authorization.
