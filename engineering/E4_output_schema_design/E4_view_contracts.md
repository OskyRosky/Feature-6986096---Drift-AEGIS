# E4 — View Contracts (conceptual, DESIGN ONLY — not executed)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Five governed consumption views for Power BI / Grafana. No view is created or executed here.

## vw_aegis_forecast_drift_current
- **Purpose:** latest governed signal per key×scenario for Overview KPIs.
- **Grain:** one row per (scenario, forecast_key) where `is_current = 1`, newest `forecast_version`.
- **Columns:** scenario, forecast_key, region, service, resource, forecast_version, forecast_drift_score, drift_status, severity, dominant_drift_family, score_coverage_pct, confidence_level, detected_on.
- **Consumers:** Power BI Overview, Grafana status panels.
- **Default filters:** `is_current = 1`; scenario in MVP scope (Enterprise).
- **Mockup:** Overview KPIs, Overall Drift Score.

## vw_aegis_forecast_drift_events
- **Purpose:** addressable drift events + current lifecycle state.
- **Grain:** one row per event signal (`is_event = 1`).
- **Columns:** drift_event_id, detected_on, scenario, forecast_key, drift_type, severity, persistence_type, event_status, forecast_drift_score, explanation, recommended_action.
- **Consumers:** Events page, Recent Drift Events, timeline.
- **Default filters:** `is_event = 1`; order by `detected_on DESC`.
- **Mockup:** Forecast Drift Events / Recent Drift Events.

## vw_aegis_forecast_drift_summary
- **Purpose:** aggregates for distributions and Top-N.
- **Grain:** aggregated by grouping (scenario / drift_family / severity / service).
- **Columns:** grouping key, event_count, avg_forecast_drift_score, max_forecast_drift_score, critical_count.
- **Consumers:** Severity Distribution, Distribution by Family, Top Services, Top Scenarios.
- **Default filters:** `is_current = 1` (or latest run).
- **Mockup:** Severity/Family distributions, Top Services (PARTIAL — Service pending), Top Scenarios.

## vw_aegis_forecast_drift_family_scores
- **Purpose:** per-family scores + family-specific metrics (long).
- **Grain:** one row per (signal, drift_family).
- **Columns:** drift_event_id, scenario, forecast_key, forecast_version, drift_family, family_score, eligibility_status, + family-specific (shape_distance, value_delta_pct, rolling_cov, …).
- **Consumers:** Performance/Shape/Stability/Volatility tabs, heatmaps.
- **Default filters:** `eligibility_status = 'COMPUTED'` (toggle to show NOT_COMPUTABLE).
- **Mockup:** the four family tabs + Drift Heatmap.

## vw_aegis_forecast_drift_timeline
- **Purpose:** time series of drift per key across versions.
- **Grain:** one row per (scenario, forecast_key, forecast_version).
- **Columns:** scenario, forecast_key, forecast_version, detected_on, forecast_drift_score, drift_status, dominant_drift_family.
- **Consumers:** Drift Trend, Drift Evolution.
- **Default filters:** scenario in scope; date range.
- **Mockup:** Overview Drift Trend, Forecast Drift Evolution.

> All views are read contracts over the governed tables; they perform no computation beyond selection/aggregation. Power BI and Grafana consume the **same** views, guaranteeing identical numbers across tools.
