# E7C — Foundation Design

**Stage:** E7C — Grafana Dashboard Foundation Preview
**Date:** 2026-07-18
**Outcome token:** `E7C_DASHBOARD_FOUNDATION_PREVIEW_COMPLETED`

## Purpose

Establish the visual and technical **foundation** of the AEGIS Forecast Drift dashboard in
Grafana — structure, navigation, variables, style and first indicators — for Oscar to review
**before** building the full MVP in E7D. This is a **foundation preview**, not the final dashboard.

## Data source (unchanged, consume-only)

| Item | Value |
|------|-------|
| Datasource name | AEGIS Forecast Drift CSV |
| Datasource UID | `aegis-forecast-drift-csv` |
| Type | `yesoreyeram-infinity-datasource` (Infinity), `readOnly: true` |
| Base URL | `http://aegis-csv` (nginx static, read-only mount of `V2/data/processed/current`) |
| Governed snapshot | V2 — 168 signals / 672 family_scores / 71 event_history / 1 run |

CSV files consumed (served at nginx root):

- `http://aegis-csv/forecast_drift_runs.csv` (1 row)
- `http://aegis-csv/forecast_drift_signals.csv` (168 rows)

> No datasource, nginx, CSV, Docker Compose, Python, service account, token, or MCP config
> was modified in E7C.

## Grafana resources created

| Resource | Title | UID |
|----------|-------|-----|
| Folder | AEGIS Forecast Drift | `afsjccp27s0e8d` |
| Dashboard | AEGIS Forecast Drift | `aegis-forecast-drift-foundation` |

Pre-existing unrelated dashboard `advs2xz` ("First Grana DAshboard") was **inspected and left
untouched** (not overwritten, not deleted).

## Dashboard structure

1. **Header** (text panel) — title `AEGIS Forecast Drift`, subtitle
   _"Governed forecast drift monitoring across performance, shape, stability and volatility."_,
   plus a note that data comes from the governed **V2** snapshot.
2. **Global variables** (4) — see `E7C_variable_contract.md`.
3. **Preview panels (4):**
   - **Panel A — Latest Governed Run** (table, `forecast_drift_runs.csv`): run id, status,
     finished-at, signals, events (1 row, transposed for readability).
   - **Panel B — Total Drift Signals** (stat, `forecast_drift_signals.csv`): count of records
     (baseline 168), no decimals.
   - **Panel C — Drift Status Distribution** (donut, `forecast_drift_signals.csv`): groupBy
     `drift_status` → count; severity colors reserved for Healthy/Watch/Warning/Critical.
   - **Panel D — Top Drift Signals Preview** (table, `forecast_drift_signals.csv`): top 10 by
     `forecast_drift_score` (sortBy desc + limit 10); columns Forecast Key, Region, Status,
     Dominant Family, Drift Score (1 decimal).

## Visual foundation

- Grafana-compatible theme (no custom background); clear titles and short descriptions.
- Counts with 0 decimals; drift score with 1 decimal; legible tables.
- No internal/dev names (no `stage07`, `blog`, `mock`).
- Severity palette reserved exclusively for status values:
  Healthy = green, Watch = yellow, Warning = orange, Critical = red.

## Explicitly deferred to E7D/E7E

Forecast, Performance, Shape, Stability, Volatility, Events, Timeline, Top Services,
Top Scenarios, Settings panels; alerts; threshold/weight changes. **None created in E7C.**

## Governed export

`V2/grafana/dashboards/aegis-forecast-drift-foundation.json` — versioned, secret-free,
datasource referenced by UID only.
