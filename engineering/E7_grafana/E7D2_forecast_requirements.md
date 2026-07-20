# E7D.2 — Forecast MVP · Requirements

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: **E7D.2 — Forecast MVP (analytical panels)** · Date: 2026-07-19
Dashboard: **AEGIS Forecast Drift — Forecast** · uid `aegis-forecast-drift-forecast` · folder
`AEGIS Forecast Drift` (uid `afsjccp27s0e8d`).

## Purpose
Transform the E7D.0 structural **shell** of the Forecast section into a complete, governed analytical
dashboard answering the forecast-level drift questions, adapting the Power BI V1 "Forecast" page logic to
Grafana + the read-only governed **V2** CSV snapshot. **No data is cooked in Grafana** — all logic lives in
the V1 engine; Grafana only reads, filters (shared filter contract) and aggregates via transformations.

## Data source (read-only V2 snapshot)
Datasource `aegis-forecast-drift-csv` (Infinity, backend parser) over the nginx-served CSVs:
- `forecast_drift_signals.csv` — 168 rows (one governed signal per forecast_key × forecast_version).
- `forecast_drift_runs.csv` — 1 row (governed calculation run metadata).

## Questions the Forecast dashboard must answer
1. **What is the overall forecast drift level?** → Overall Forecast Drift Score gauge (mean
   `forecast_drift_score`, 0–100, severity bands).
2. **Which drift families contribute the signals?** → Drift Family Distribution donut over
   `dominant_drift_family` (neutral, non-severity colors).
3. **How is severity distributed?** → Drift Status Distribution donut over `drift_status` (severity colors).
4. **How has drift evolved historically?** → Average Drift Score Over Time (by forecast version) timeseries.
5. **Which forecast keys carry the most risk?** → Forecast Keys by Average Drift Score horizontal bars.
6. **How does each key behave across every forecast version?** → Drift Score Heatmap (forecast key ×
   forecast version), one governed score per cell, severity-colored.
7. **What produced this data?** → Latest Governed Run table.
8. **Is the data trustworthy?** → Data Quality — Checks Passed stat.

## Shared filters (contract)
Five multi-value filters with `Include All`: **Forecast Key · Forecast Version · Region · Drift Status ·
Run ID** (E7D.0 shared filter contract). All analytical panels honor the five filters **except**:
- The **historical trend** intentionally ignores **Forecast Version** to preserve the full 14-point series
  (it still honors Region / Forecast Key / Drift Status / Run ID).
- The **drift heatmap** is a fixed cross-tab of all keys × all versions and intentionally shows the complete
  matrix regardless of the shared filters (documented in-panel).
- The **Latest Run** and **Data Quality** panels filter only by **Run ID** (run-level metadata).

## Ground truth (validated via `/api/ds/query`, 2026-07-19)
- Signals **168**; mean `forecast_drift_score` **28.8** (n=168, 0 nulls).
- `dominant_drift_family`: stability **88** · volatility **45** · shape **27** · performance **8** (Σ 168).
- `drift_status`: Healthy **82** · Watch **38** · Warning **34** · Critical **14** (Σ 168).
- 14 forecast versions (chronological), 12 forecast keys, 9 regions.
- Heatmap: 168 key×version combos, **exactly one** score per cell (0 duplicates).
- Run 1 · `E5A-v1` · Success · checks **18/18** · signals_written **168** · events_created **71** ·
  finished 2026-07-13 22:44 UTC · source_forecast_version_max 2026-05-01.

## Out of scope (do not start)
Performance, Shape, Stability, Volatility, Events, Historical Timeline, Top Forecast Keys, Top Scenarios,
Settings & Data Quality. No changes to the Overview, the other 9 shells, datasource, nginx, Docker, CSVs,
Python, Power BI, weights, thresholds, alerts, plugins, token, DPAPI or MCP.
