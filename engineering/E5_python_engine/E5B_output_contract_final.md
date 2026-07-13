# E5B — Final Output Contract (frozen for E6)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

Governed datasets written atomically to `V1/data/processed/current/`
(Parquet preferred, CSV always). Power BI / Grafana consume these **as-is** and
must not recompute any business logic.

## Folder layout (stable)
```
V1/data/processed/
  current/     forecast_drift_signals · forecast_drift_family_scores · forecast_drift_runs · forecast_drift_event_history  (.csv/.parquet)
  metadata/    run_metadata.json
  validation/  _data_quality_checks.csv · _fixture_results.csv
  history/     <UTC timestamp>/  (optional snapshots, --snapshot)
```
Naming: lower_snake_case, no timestamp in `current/` file names (stable paths for
BI); history snapshots are timestamped folders. Overwrite semantics: `current/`
is overwritten atomically each successful run; failed runs never overwrite.

## 1. `forecast_drift_signals` (primary)
- **Grain / logical PK:** `calculation_version × scenario × forecast_key × forecast_version` (+ `drift_type`).
- **Natural key:** `event_natural_key`. **Row hash:** `record_hash` (unique).
- **Columns (54):** `drift_event_id, event_natural_key, record_hash,
  calculation_run_id, calculation_version, detected_on, scenario, forecast_key,
  forecast_key_raw, service, region, forest, resource, forecast_version,
  previous_forecast_version, target_date, drift_type, dominant_drift_family,
  drift_status, severity, persistence_type, event_status, is_event, metric_name,
  metric_value, previous_metric_value, metric_delta, metric_delta_pct,
  performance_drift_score, shape_drift_score, stability_drift_score,
  volatility_drift_score, forecast_drift_score, score_coverage_pct,
  confidence_level, missing_family_flag, reason_code, explanation,
  recommended_action, source_database, source_schema, source_object,
  source_forecast_version, source_row_count, normalization_version,
  formula_version, performance_mode, threshold_config_id, weight_config_id,
  created_at, created_by, updated_at, updated_by, is_current`.
- **Required (non-null):** drift_event_id, event_natural_key, record_hash,
  calculation_version, scenario, forecast_key, forecast_key_raw,
  forecast_version, drift_type, drift_status, forecast_drift_score,
  score_coverage_pct, confidence_level, is_event, performance_mode.
- **Nullable by design:** service, forest (G3/G4 open); severity, event_status,
  persistence_type (only on events); metric_* (only when dominant=performance);
  any family score that was NOT_COMPUTABLE; updated_at/by.
- **Enums:** drift_status ∈ {Healthy,Watch,Warning,Critical,Unknown};
  confidence_level ∈ {HIGH,MEDIUM,LOW}; performance_mode ∈ {shallow,deep};
  is_event ∈ {0,1}.
- **Scores:** all `*_drift_score` and `score_coverage_pct` ∈ [0,100].

## 2. `forecast_drift_family_scores`
- **Grain:** `drift_event_id × drift_family` (4 rows per signal).
- **Columns (24):** drift_event_id, forecast_key, forecast_version, drift_family,
  family_score, raw_magnitude, eligibility_status, not_computable_reason,
  version_count, horizon_point_count, shape_distance, divergence_start_date,
  max_curve_delta, max_curve_delta_pct, value_delta, value_delta_pct,
  cumulative_revision_pct, structural_break_flag, rolling_stddev, rolling_cov,
  rolling_mad, oscillation_count, sign_change_freq, volatility_class.
- **Rule:** `eligibility_status='NOT_COMPUTABLE'` ⇒ `family_score` is null.
- **Enums:** drift_family ∈ {performance,shape,stability,volatility};
  eligibility_status ∈ {COMPUTED,NOT_COMPUTABLE}.

## 3. `forecast_drift_runs`
- **Grain:** `calculation_run_id`. One row per refresh.
- **Columns:** calculation_run_id, calculation_version, formula_version,
  threshold_config_id, weight_config_id, run_started_at, run_finished_at,
  source_forecast_version_max, signals_written, events_created, runtime_seconds,
  peak_memory_mb, checks_passed, checks_total, idempotent, perf_mode, run_status,
  created_by.

## 4. `forecast_drift_event_history`
- **Grain:** `event_history_id`. Status transitions for events.
- **Columns:** event_history_id, drift_event_id, old_status, new_status,
  changed_at, changed_by, note.

## 5. `run_metadata.json` (metadata/)
Versions, generated_at, parquet_available, output_format_primary, row counts,
layout paths, files written, source, profile, perf_mode, synthetic flag,
sample_keys, sample_versions, normalization_stats, key_collision_report,
checks_passed/total, idempotent, runtime_seconds, peak_memory_mb,
status_distribution.

## Determinism
`record_hash` = sha256 over natural key + composite + four family scores; stable
across runs (idempotent). Non-deterministic fields (allowed to differ run-to-run):
`detected_on`, `created_at`, `run_started_at`, `run_finished_at`, `generated_at`.

## Power BI / Grafana compatibility
Flat, typed, columnar-friendly; stable file paths under `current/`; enums are
plain strings; scores are 0–100 numerics; one primary fact
(`forecast_drift_signals`) + a family detail table joinable on `drift_event_id`.
