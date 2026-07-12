# E2 — Lineage Map

**Feature 6986096 — AEGIS Forecast Drift Framework**
Traceability from raw SQL source through normalization, logical entities, derived variables, drift families, to the Forecast Drift Event. Design only.

## 1. Layered chain

```
SQL source  ->  Normalization layer  ->  Logical entity  ->  Derived variable  ->  Drift family  ->  Forecast Drift Event
```

## 2. Per-path lineage

| SQL source | Normalization | Logical entity | Derived variable | Drift family | Event field |
| --- | --- | --- | --- | --- | --- |
| `hdd_region` (ModelVersion<>actual, Forecast-Mean) | dedupe FV 2025-06-01; is_forward; version_rank | `fact_forecast_values` -> `norm_forecast_forward` | `horizon_days`, `is_forward`, `version_rank`, `prev_value` | (base for Shape/Stability/Volatility) | — |
| `hdd_region` forward curves | align forward horizon per version | `norm_forecast_forward` | `shape_distance` | **Shape** | `shape_drift_score` |
| `hdd_region` fixed future target across versions | pair v_n / v_(n-1) | `norm_forecast_forward` | `value_delta`, `value_delta_pct` | **Stability** | `stability_drift_score` |
| `hdd_region` value series per Key+target | rolling window of last N versions | `norm_forecast_forward` | `rolling_std`, `rolling_cov` | **Volatility** | `volatility_drift_score` |
| `hdd_region` (ModelVersion=actual, Value>0) | per-scenario actuals | `fact_actual_values` | (feeds Performance recompute) | **Performance** (mode b) | `metric_value` |
| `*_metrics` (MAPE/Bias/Accuracy, Forecast_Version) | version pairing on Forecast_Version | `fact_accuracy_metrics` | `metric_delta`, `metric_delta_pct` | **Performance** (mode a) | `performance_drift_score`, `metric_name`, `metric_value`, `previous_metric_value` |
| `dim_forecast_version` | version_rank / prev_version_sk | `dim_forecast_version` | pairing | all families | `forecast_version`, `detected_on` |
| `Key` prefix | region parse | `dim_region` (via `dim_key`) | `region_code` | grouping/UX | (dimension) |
| forest metrics `Key` | region mapping | `dim_forest` | `mapped_region_code` | Performance (forest variant, deferred) | — |
| n/a (no column) | map from Key / external | `dim_service` (PENDING) | `service_name` | grouping/UX | (dimension) |
| `cfg_drift_weights` | — | `cfg_drift_weights` | weight_pct | engine | (weights applied) |
| `cfg_drift_thresholds` | — | `cfg_drift_thresholds` | band | engine | `severity`, `forecast_drift_flag` |
| (engine) | normalize + weight 4 sub-scores | `fact_forecast_drift_events` | `forecast_drift_score` | (aggregate) | `forecast_drift_score`, `drift_type`, `explanation` |

## 3. Source vs derived boundary

- **Source (read-only, reused verbatim):** Key, DateTime, Value, ModelVersion, ForecastVersion, Scenario, Resource, ValueType; metrics MAPE/MAE/RMSE/Bias/Bias_Pct/SMAPE/Accuracy/Count/Mean_Actual/Mean_Forecast/Forecast_Version/Start_Date/End_Date/Execution_Date.
- **Boundary:** `norm_forecast_forward` + version ranking + region parse.
- **Derived (computed in E3):** horizon_days, is_forward, value_delta[/pct], shape_distance, rolling_std/cov, metric_delta[/pct], the four `*_drift_score`, forecast_drift_score, severity, forecast_drift_flag, drift_type, explanation.

## 4. Governance note
Lineage keeps AEGIS as the producer of governed drift signals: raw source is never mutated; the drift event table is the single governed output consumed downstream (Power BI, Grafana, Planning, Monitoring).
