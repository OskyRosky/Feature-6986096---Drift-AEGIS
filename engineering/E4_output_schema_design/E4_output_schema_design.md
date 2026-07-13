# E4 — Output Schema Design

**Feature 6986096 — AEGIS Forecast Drift Framework**
**Stage:** E4 — Output Schema Design (physical & contractual design only)
**Date:** 2026-07-12
**Basis:** E1/E2/E3 + Blueprint V2 + Prototype. **No** DDL execution, **no** SQL/views/procs/pipelines, **no** Power BI/Grafana, **no** E5, **no** data mutation, **no** commit. All object/column names are design proposals.

> Governance: Microsoft internal / confidential. No server host/credentials. Physical **design** of the governed drift output layer.

---

## 1. Physical model overview

Seven MVP objects (details in `E4_table_catalog.csv`, columns in `E4_column_catalog.csv`):

**Fact / output**
- `dbo.aegis_forecast_drift_signals` — governed drift signal per version evaluation (the Blueprint `aegis_forecast_drift_signals`). Carries the 4 family sub-scores + composite + status + headline metric + lineage/audit.
- `dbo.aegis_forecast_drift_family_scores` — tidy long detail: one row per (signal, family) with family score + family-specific raw metrics.
- `dbo.aegis_forecast_drift_event_history` — append-only operational lifecycle trail.
- `dbo.aegis_forecast_drift_run` — calculation run lineage + idempotency anchor.

**Config**
- `dbo.aegis_drift_threshold_config` — anchors, bands, eligibility per family/metric (versioned, effective-dated).
- `dbo.aegis_drift_weight_config` — family weights (sum 100 per version).
- `dbo.aegis_drift_formula_config` — engine parameters per formula version.

**Deferred:** `aegis_forecast_drift_explanations` (long/multi-language) — MVP uses an inline `explanation` column.

## 2. Main table grain & key strategy (decision)

**Grain:** one row per **`(calculation_version, scenario, forecast_key, forecast_version)`** evaluation — a **signal-level** row (not events-only), so Healthy history is retained for trend/heatmap visuals. `is_event` flags actual events; `drift_type` = dominant family. *Justification:* the mockup needs full time-series (Drift Trend/Evolution), which an events-only table cannot supply.

**Key strategy — compared:**
| Option | Verdict |
| --- | --- |
| `BIGINT IDENTITY` surrogate | **Chosen PK** — compact, monotonic, best clustered key & FK target |
| `UNIQUEIDENTIFIER` | Rejected as PK — random GUID fragments the clustered index |
| Composite natural key as PK | Rejected — wide FK, slow joins |
| Deterministic hash | **Used as `record_hash`** for idempotency, not as PK |

**Final:** surrogate PK `drift_event_id` + **natural UNIQUE** `(calculation_version, scenario, forecast_key, forecast_version, drift_type)` + **`record_hash`** (SHA2_256 of natural key + score payload).

**Idempotency / reprocessing:** a re-run with the same `calculation_version` computes `record_hash`; **hash match ⇒ no-op** (idempotent), **hash differs ⇒ in-place correction** (`updated_at`). A run with a **new formula/threshold/weight** produces a **new `calculation_version`** (new rows); prior rows kept with `is_current = 0` (SCD-2 style). This gives full reproducibility and clean dedupe.

## 3. Wide vs normalized (decision)

- **Main table stays lean:** composite + 4 family scores + coverage/confidence + headline (dominant) source metric + status + lineage. This powers Overview, timeline, Top Scenarios **without joins**.
- **Family-specific sparse fields** (`shape_distance`, `value_delta`, `rolling_cov`, …) live in **`aegis_forecast_drift_family_scores`** (long). *Justification:* avoids a very wide main table dominated by NULLs; long format is the natural shape for per-family tabs and heatmaps in Power BI/Grafana. Balance achieved: not one giant table, not over-normalized.

## 4. Configuration tables (decision)

Three config tables, all versioned + effective-dated + `is_active`:
- **`aegis_drift_threshold_config`** — per family/metric anchors (a20/a40/a70/a100), band edges, `min_versions`, `window_n`, `gate_value`, approver/audit. Filtered unique index enforces one active config per family/metric.
- **`aegis_drift_weight_config`** — per-family `weight_pct`; business rule sum=100 per version (cross-row → enforced by app/trigger, documented as intent, not a table CHECK).
- **`aegis_drift_formula_config`** — `normalization_method`, `event_threshold`, `family_event_threshold`, `persistence_min`, `cooldown_versions`, `missing_family_policy`. **Kept as a table** (not just versioned docs) because every signal must **FK to the exact parameter set** used → auditable reproducibility.

Every signal stores `formula_version`, `threshold_config_id`, `weight_config_id`, `normalization_version` for full traceability.

## 5. Detail & history tables (decision)

- **`aegis_forecast_drift_family_scores`** (MVP) — per-family detail.
- **`aegis_forecast_drift_event_history`** (MVP) — **append-only** lifecycle trail; never overwrites evidence.
- **`aegis_forecast_drift_run`** (MVP) — run lineage/idempotency anchor.
- `aegis_forecast_drift_explanations` (FUTURE).

## 6. Lifecycle (decision)

Operational states: **Open → Acknowledged → Investigating → Resolved / Suppressed**. Current state = `event_status` on the main row (mutable, with `updated_at/by`); the **immutable trail** is in `aegis_forecast_drift_event_history` (append-only, `old_status`→`new_status`, actor, note). *Justification:* separates immutable analytical evidence (the signal + scores) from mutable operational state, preserving history without overwriting.

## 7. Types & nullability (highlights — full in `E4_column_catalog.csv`)

- Scores `DECIMAL(5,2)`, `CHECK BETWEEN 0 AND 100`; family scores **NULL = NOT_COMPUTABLE**; composite `NOT NULL` (≥1 family required).
- Percentages `DECIMAL(9,4)` (signed); raw metric values `DECIMAL(18,6)`.
- Dates `DATE`; timestamps `DATETIME2(3)` **UTC** (`SYSUTCDATETIME()`).
- Dimensional text sized (scenario 50, key 100, region/forest 50, resource 20); enumerations via `CHECK`.
- Flags `BIT`; `record_hash` `BINARY(32)`; ids `BIGINT`/`INT` identity.
- `NOT_COMPUTABLE` = NULL score + `eligibility_status`/`not_computable_reason` in the family detail.

## 8. PK / FK / constraints (full in `E4_relationship_and_constraint_matrix.csv`)

PKs surrogate; natural UNIQUE prevents duplicate events; FKs from signals → run + 3 config tables; family/history → signals. **Dimension FKs (scenario/key/service/forest/region) are DEFERRED/optional** — dimensions are denormalized as text on the signal so pending dims (Service G3, Forest G4) **do not block the MVP**; hard FKs can be added when dims are materialized. CHECKs enforce score ranges, enumerations, anchor monotonicity, temporal integrity.

## 9. Index strategy (full in `E4_index_strategy.csv`)

Clustered PK on `drift_event_id`. Nonclustered for: dimensional filter, timeline (`detected_on DESC`), family+severity, plus **filtered** indexes for recent Critical and events-only. Columnstore + monthly partitioning marked **FUTURE** (not justified at MVP volume ~thousands–tens of thousands of rows). No over-indexing for unvalidated scale.

## 10. Audit, lineage & idempotency

- **Identify a calculation:** `calculation_run_id` + `calculation_version` + `formula_version` + config ids.
- **Reproduce a result:** re-run same `calculation_version` + same configs ⇒ identical `record_hash`.
- **Link to sources:** `source_database/schema/object/forecast_version/row_count`.
- **Detect duplicates:** natural UNIQUE + `record_hash`.
- **Reprocess safely:** hash match = no-op; hash differ = correction; new config = new `calculation_version` + `is_current` flip.
- **Formula change tracking:** `formula_version` / `normalization_version` on every row + `aegis_drift_formula_config` history.
- **New calc vs status update:** new calc writes signals; a lifecycle change writes only `event_status` + an `event_history` row (no new signal).

## 11. Consumption views & mockup coverage

Five conceptual views (contracts in `E4_view_contracts.md`) power the prototype; full page→field→view matrix in `E4_mockup_consumption_mapping.csv`. All pages are MVP-consumable **except** Top Services (PARTIAL — depends on Service dimension G3) and Settings→Integrations (FUTURE).

## 12. E3 field coverage

Every E3 math field has a physical destination (`E4_e3_field_mapping.csv`): composite/status/headline on the main table; family-specific raw metrics on the family detail. No E3 output is left without a home or an explicit decision.

## 13. What E4 does NOT do
No formula recalibration, no SQL execution, no data load, no Power BI/Grafana, no pipelines, no source changes, no production. Design + `E4_design_only_ddl.sql` (marked **DESIGN ONLY — DO NOT EXECUTE**).
