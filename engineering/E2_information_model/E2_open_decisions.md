# E2 — Open Decisions

**Feature 6986096 — AEGIS Forecast Drift Framework**
Design decisions taken, assumptions, open gaps, and what is deferred to E3 / E4.

## 1. Confirmed design decisions
- Model = **star schema** (dimensions + facts + config) with an explicit **normalization layer** as the source/derived boundary.
- Fact grain (validated): `fact_forecast_values` = `Key × DateTime × ForecastVersion × Scenario × Resource`, **one model_version per cell**.
- `model_version` is an **attribute**, not a driver (drift compares version-to-version regardless of model).
- `dim_drift_family`, `cfg_drift_weights`, `cfg_drift_thresholds` make weights/bands **governed data**, not hard-coded.
- Canonical grain fixed for all four families + the event (section 4 of the model doc).
- Gap rules encoded in design: dedupe FV 2025-06-01 (G1), forward-only `is_forward` (G6), version pairing via `version_rank`/`prev_version_sk`.
- The Forecast Drift Event entity = the Blueprint `aegis_forecast_drift_signals` (one row = one event).

## 2. Assumptions (to confirm)
- `region_code` is reliably parseable from the `Key` prefix (e.g. `APC-`, `EUR-`, `NAM-`). Needs an authoritative region lookup to confirm.
- MVP scope = **Enterprise** scenario, **region** grain, **HDD** resource.
- Families with no data for a Key contribute **null** (not zero) to the weighted score, so absence never looks "healthy".

## 3. Open gaps (carried from E1, still open)
- **G3 Service dimension** — no source column; mapping source unresolved. `dim_service` modeled as PENDING.
- **G4 region↔forest mapping** — forest namespace (155 keys) not yet mapped to region keys.
- **G7 TTL** — `vw_SubstrateBE_MonthsToLive_*` not probed; only relevant if TTL enters Drift Score v0 (Blueprint Q A6).
- Authoritative region lookup (assumption 2.1).

## 4. Deferred to E3 (mathematics)
- Exact formulas for each family and normalization of each sub-score to 0-100.
- **Shape distance metric** choice (normalized L2 / cosine / DTW on aligned horizons).
- **Volatility window N** (how many versions).
- **Performance mode** decision: official metrics (3 versions) vs recompute from facts for depth (G2).
- Aggregation of per-target signals up to Key×version (Stability/Volatility).
- Weighting/severity confirmation (Blueprint 20/40/30/10; bands 0-20/20-40/40-70/70+) — stakeholder Q A5.
- Known-answer fixtures from Blueprint worked examples.

## 5. Deferred to E4 (physical output schema)
- Physical DDL for `aegis_forecast_drift_signals`: PK/FK, indexes, data types, nullability, audit columns, lineage columns.
- Physical materialization of `dim_service` and the region/forest mapping tables.
- Seeding of `cfg_drift_thresholds` / `cfg_drift_weights`.
- Naming finalization and schema/namespace placement.
