# E5A — Output Contract (file datasets)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Governed file outputs under `V1/data/processed/`. Follows the E4 physical contract as closely as reasonable for file datasets. CSV always; Parquet when pyarrow is available.

## Datasets

### forecast_drift_signals(.csv/.parquet)
- **Grain:** one row per (calculation_version, scenario, forecast_key, forecast_version).
- **Columns:** drift_event_id, event_natural_key, record_hash, calculation_run_id, calculation_version, detected_on, scenario, forecast_key, service(null), region, forest(null), resource, forecast_version, previous_forecast_version, target_date, drift_type, dominant_drift_family, drift_status, severity, persistence_type, event_status, is_event, metric_name, metric_value, previous_metric_value, metric_delta, metric_delta_pct, performance_drift_score, shape_drift_score, stability_drift_score, volatility_drift_score, forecast_drift_score, score_coverage_pct, confidence_level, missing_family_flag, reason_code, explanation, recommended_action, source_database, source_schema, source_object, source_forecast_version, source_row_count, normalization_version, formula_version, threshold_config_id, weight_config_id, created_at, created_by, updated_at, updated_by, is_current.
- **Logical nullability:** family scores nullable (NULL = NOT_COMPUTABLE); forecast_drift_score not null; severity/target_date/event_status nullable.

### forecast_drift_family_scores(.csv/.parquet)
- **Grain:** one row per (drift_event_id, drift_family).
- **Columns:** drift_event_id, forecast_key, forecast_version, drift_family, family_score, raw_magnitude, eligibility_status, not_computable_reason, version_count, horizon_point_count, shape_distance, divergence_start_date, max_curve_delta, max_curve_delta_pct, value_delta, value_delta_pct, cumulative_revision_pct, structural_break_flag, rolling_stddev, rolling_cov, rolling_mad, oscillation_count, sign_change_freq, volatility_class.

### forecast_drift_runs(.csv/.parquet)
- **Grain:** one row per run. Columns: calculation_run_id, calculation_version, formula_version, threshold_config_id, weight_config_id, run_started_at, run_finished_at, source_forecast_version_max, signals_written, events_created, run_status, created_by.

### forecast_drift_event_history(.csv/.parquet)
- **Grain:** one row per (drift_event_id, status change). Columns: event_history_id, drift_event_id, old_status, new_status, changed_at, changed_by, note. Append-only.

### run_metadata.json
Lineage + reproducibility: calculation_version, formula_version, normalization_version, threshold_config_version, weight_config_version, generated_at, parquet_available, signal_rows, family_score_rows, event_rows, files, sample_keys, sample_versions, normalization_stats (rows_in / after_nulls / after_dedupe / forward_only / distinct_keys / distinct_versions), checks_passed/total, idempotent, runtime_seconds, peak_memory_mb, status_distribution.

## Consumption rule
Power BI / Grafana read these files (or the future SQL tables/views) **only** — they contain no business logic. Same contract feeds both tools for identical numbers.

## Types (file-level)
Scores/percentages as floats (0–100 for scores); dates as ISO date strings; timestamps as ISO-8601 UTC; hashes as hex strings; flags as 0/1 or booleans; text as UTF-8.
