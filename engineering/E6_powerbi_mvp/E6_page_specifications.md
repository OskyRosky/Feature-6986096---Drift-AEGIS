# E6 — Power BI MVP: Page Specifications (11 pages)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

All visuals consume governed columns/measures. **No visual recomputes drift
logic.** Status colors: Healthy `#2E7D32` · Watch `#F9A825` · Warning `#EF6C00`
· Critical `#C62828`. Shared slicers (sync across pages): Scenario, Region,
forecast_key, ForecastVersion (Calendar), drift_status.

## 1. Overview
- KPI cards: `Total Signals`, `Total Events`, `Average Forecast Drift Score`,
  `Critical Count`, `Warning Count`, `Healthy Count`.
- Donut/bar: status distribution (`drift_status` × `Total Signals`).
- Line: trend of `Average Forecast Drift Score` and `Total Events` by
  `forecast_version` (Calendar[YearMonth]).
- Bar: `dominant_drift_family` × `Total Signals`.
- Card row (lineage): `Latest Refresh`, `Latest Calculation Version`,
  `Performance Mode`, `Data Quality Status`.
- Slicers: Scenario, Region, forecast_key, ForecastVersion, drift_status.

## 2. Forecast Drift (composite)
- KPI: `Average Forecast Drift Score`, `Total Signals`, `Total Events`.
- Histogram: `forecast_drift_score` buckets.
- Matrix: forecast_key × forecast_version, value = `forecast_drift_score`,
  conditional-format by status color.
- Table: forecast_key, forecast_version, forecast_drift_score, drift_status,
  confidence_level, dominant_drift_family, score_coverage_pct.

## 3–6. Performance / Shape / Stability / Volatility Drift (one page each)
Each family page (filter `forecast_drift_family_scores[drift_family]` = the
family) shows:
- KPI: `Avg <Family> Score`, `Computed Family Count`, `NOT_COMPUTABLE Count`.
- Column: score distribution by bucket.
- Line: trend of average family_score by forecast_version.
- Bar: **Top affected keys** — forecast_key by average family_score (desc).
- Matrix: forecast_key × forecast_version = family_score (comparison by version).
- Details table: forecast_key, forecast_version, family_score, raw_magnitude,
  eligibility_status, not_computable_reason, + family-specific columns
  (Performance: metric_delta_pct; Shape: shape_distance/max_curve_delta_pct;
  Stability: value_delta_pct/structural_break_flag; Volatility: rolling_cov/
  volatility_class) and the signal `explanation`.
- NOT_COMPUTABLE card/visual using `NOT_COMPUTABLE Count` + reason breakdown.

## 7. Forecast Drift Events
- Event list table (filter `is_event = 1`): forecast_key, scenario,
  forecast_version, dominant_drift_family, drift_status (severity), event_status,
  detected_on, explanation, recommended_action.
- KPI: `Total Events`, `Critical Event Count`, `Warning Event Count`.
- Bar: events by dominant_drift_family / by scenario.
- Drill-through target: from any page on forecast_key → this page filtered.

## 8. Historical Timeline
- Line/area: `forecast_drift_score` (or event counts) over `forecast_version`
  and `detected_on`, series by drift_status or drift_family.
- Matrix: forecast_version × drift_status = count.
- Table: event_history joined to signals (old_status → new_status, changed_at).

## 9. Top Services  — **PARTIAL (G3)**
- Prominent note: "Service dimension not yet sourced (G3). Showing forecast_key
  as the closest available grouping." `service` is null in all rows.
- Bar: forecast_key by `Average Forecast Drift Score` / `Total Events`
  (proxy until Service lands). Do **not** fabricate Service.

## 10. Top Scenarios
- Bar: scenario × `Total Signals` / `Total Events` / `Average Forecast Drift Score`.
- Donut: status distribution within scenario.
- Table ranking: scenario, Total Signals, Total Events, Critical Count, Avg score.
- (MVP scope = Enterprise scenario; visual generalizes when more scenarios load.)

## 11. Settings / Data Status
- Cards from `forecast_drift_runs`: `Latest Calculation Version`, formula_version,
  `Performance Mode`, threshold_config_id, weight_config_id, `Latest Refresh`,
  source mode (run_status/perf_mode), `Data Quality Status`, `Idempotent Flag`,
  `Signals Written (run)`.
- Lineage table: run row(s) with runtime_seconds, peak_memory_mb, checks_passed/
  total, idempotent, run_status.
- Text box: governance statement ("Power BI consumes governed Python datasets;
  no business logic recomputed"); pointer to `E5B_output_contract_final.md`.

## Cross-cutting
- Every page: title, the AEGIS sidebar (page 1 of `E6_sidebar_navigation_spec.md`),
  shared slicer panel, and a discreet "Last refresh: [Latest Refresh]" caption.
- Accessibility: high-contrast status palette, tabular-friendly number formats.
