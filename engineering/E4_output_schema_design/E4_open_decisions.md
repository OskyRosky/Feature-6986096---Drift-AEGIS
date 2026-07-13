# E4 — Open Decisions

**Feature 6986096 — AEGIS Forecast Drift Framework.**

## 1. Decisions closed in E4
- **Physical grain:** signal-level — one row per (calculation_version, scenario, forecast_key, forecast_version); `is_event` flags events; `drift_type` = dominant family.
- **PK:** `BIGINT IDENTITY` surrogate `drift_event_id` (clustered).
- **Natural unique key:** (calculation_version, scenario, forecast_key, forecast_version, drift_type).
- **Idempotency:** `record_hash` (SHA2_256); same version+hash = no-op; new config = new calculation_version + is_current flip (SCD-2).
- **Main vs detail:** lean main table + tidy long `aegis_forecast_drift_family_scores` for family-specific sparse fields.
- **Config tables:** threshold + weight + formula (all versioned, effective-dated, active-flagged).
- **Lifecycle:** current `event_status` on main + immutable append-only `aegis_forecast_drift_event_history`.
- **Types/nullability:** scores DECIMAL(5,2) 0–100 (NULL=NOT_COMPUTABLE), pct DECIMAL(9,4), UTC DATETIME2(3), enums via CHECK.
- **Constraints:** PK/natural-UNIQUE/hash-UNIQUE/CHECKs/FKs to run+config; dim FKs deferred.
- **Indexes MVP:** clustered PK + 6 nonclustered (incl. 2 filtered); columnstore/partitioning FUTURE.
- **Views:** 5 governed consumption views (contracts documented).
- **E3 coverage:** every E3 math field mapped to a physical column.

## 2. Assumptions (to confirm in E5)
- MVP row volume is small (~thousands–tens of thousands) ⇒ no partitioning/columnstore needed yet.
- Denormalized dimension text on the signal is acceptable until dims are materialized.
- One dominant `drift_type` per version signal is sufficient (multi-family granularity lives in family detail).

## 3. Open gaps / risks
- **G3 Service** — `service` column nullable; Top Services page = PARTIAL until mapping exists.
- **G4 Forest** — `forest` nullable; forest-grain analytics deferred.
- **Weight sum = 100** is a cross-row rule → needs app/trigger enforcement (not a table CHECK).
- Anchors/weights/thresholds are still **uncalibrated** (from E3) → calibrate in E5.
- Region parsing authority (from E2 assumption) still unconfirmed.

## 4. Deferred to E5 (implementation)
- Execute DDL (after review), build load/UPSERT logic (MERGE on natural key + hash), implement the 5 views, validate against E3 fixtures, calibrate configs, decide Performance deep-recompute.

## 5. Deferred to E6/E7 (consumption)
- Power BI / Grafana bind to the 5 views (no logic in the tools).
