# E7C — Dashboard Preview Validation

**Stage:** E7C — Grafana Dashboard Foundation Preview
**Date:** 2026-07-18
**Dashboard UID:** `aegis-forecast-drift-foundation`
**Folder UID:** `afsjccp27s0e8d`

## Validation matrix (MCP + read-only API)

| # | Check | Method | Result | Status |
|---|-------|--------|--------|--------|
| 1 | Folder created/reused correctly | MCP `create_folder` / `search_folders` | `afsjccp27s0e8d` "AEGIS Forecast Drift" | ✅ |
| 2 | Dashboard in correct folder | MCP `get_dashboard_summary` | folderUid `afsjccp27s0e8d` | ✅ |
| 3 | Dashboard accessible | MCP `search_dashboards` / summary | present, 5 panels, 4 variables | ✅ |
| 4 | Datasource UID correct | MCP `get_datasource` | `aegis-forecast-drift-csv` (Infinity) | ✅ |
| 5 | Datasource healthy | MCP `check_datasources_health` | status OK — "Health check successful" | ✅ |
| 6 | Panels load without error | read-only `/api/ds/query` per panel | see per-panel table below | ✅ |
| 7 | Variables load values | data-driven cardinality confirmed | 12 / 9 / 4 / 1 | ✅ |
| 8 | No "No data" from misconfig | rows returned > 0 for every panel query | all panels return rows | ✅ |
| 9 | No writes outside authorized folder/dashboard | `search_dashboards` | only new folder+dashboard added | ✅ |
| 10 | No other dashboards modified | `search_dashboards` | `advs2xz` untouched | ✅ |
| 11 | No secret exposed | secret scan JSON + docs | CLEAN | ✅ |

## Per-panel data-flow test (read-only `/api/ds/query`, HTTP 200)

| Panel | Type | CSV | Query rows | Post-transform | Status |
|-------|------|-----|-----------|----------------|--------|
| A — Latest Governed Run | table | forecast_drift_runs.csv | 1 | transpose → 1 run shown | 200 ✅ |
| B — Total Drift Signals | stat | forecast_drift_signals.csv | 168 | count → **168** | 200 ✅ |
| C — Drift Status Distribution | donut | forecast_drift_signals.csv | 168 | groupBy drift_status → Healthy 82 / Watch 38 / Warning 34 / Critical 14 | 200 ✅ |
| D — Top Drift Signals Preview | table | forecast_drift_signals.csv | 168 | sortBy Drift Score desc + limit 10 | 200 ✅ |

> The token was decrypted **in memory only** for the read-only API test, never printed,
> and zeroed/disposed immediately after. No writes were performed via the API.

## Queries & CSV mapping

| Panel / variable | CSV file | Key columns |
|------------------|----------|-------------|
| A | forecast_drift_runs.csv | calculation_run_id, run_status, run_finished_at, signals_written, events_created |
| B | forecast_drift_signals.csv | drift_event_id (count) |
| C | forecast_drift_signals.csv | drift_status, drift_event_id |
| D | forecast_drift_signals.csv | forecast_key, region, drift_status, dominant_drift_family, forecast_drift_score |
| var forecast_key | forecast_drift_signals.csv | forecast_key |
| var region | forecast_drift_signals.csv | region |
| var drift_status | forecast_drift_signals.csv | drift_status |
| var run_id | forecast_drift_runs.csv | calculation_run_id |

## Dashboard URL

`http://localhost:3000/d/aegis-forecast-drift-foundation/aegis-forecast-drift`
