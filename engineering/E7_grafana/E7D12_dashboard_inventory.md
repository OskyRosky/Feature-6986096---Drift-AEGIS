# E7D.12 — Dashboard Inventory (canonical)

Source of truth: `V2/grafana/dashboards/*.json`. Verified 2026-07-20.
Total JSON files: **11** (10 active navigation + 1 retired rollback-only).
All UIDs unique. Datasource for every panel: `aegis-forecast-drift-csv`.

## Active navigation set (tag `aegis-nav`)
| # | Nav title | UID | Template vars | Nav dropdown |
|---|---|---|---|---|
| 1 | Overview | `aegis-forecast-drift-foundation` | 5 | ✔ |
| 2 | Forecast | `aegis-forecast-drift-forecast` | 5 | ✔ |
| 3 | Performance | `aegis-forecast-drift-performance` | 5 | ✔ |
| 4 | Shape | `aegis-forecast-drift-shape` | 5 | ✔ |
| 5 | Stability | `aegis-forecast-drift-stability` | 5 | ✔ |
| 6 | Volatility | `aegis-forecast-drift-volatility` | 5 | ✔ |
| 7 | Events | `aegis-forecast-drift-events` | 6 | ✔ |
| 8 | Historical Timeline | `aegis-forecast-drift-timeline` | 7 | ✔ |
| 9 | Top Risk | `aegis-forecast-drift-top-keys` | 5 | ✔ |
| 10 | Settings & Data Quality | `aegis-forecast-drift-settings` | 1 | ✔ |

Notes on variable counts: dashboards 1–6 and 9 expose the five shared filters
(`forecast_key`, `forecast_version`, `region`, `drift_status`, `run_id`). Events (7)
and Historical Timeline (8) add local dimensions (e.g. severity / temporal range).
Settings (10) is a configuration/quality view and intentionally carries a single
run-scope variable — the five shared drill filters are N/A there by design.

## Retired (rollback-only — NOT in navigation)
| Nav title | UID | Tags | Status |
|---|---|---|---|
| Top Scenarios | `aegis-forecast-drift-top-scenarios` | `absorbed-into-top-risk`, `shell`, … (no `aegis-nav`) | Preserved for rollback; not deleted; absent from nav dropdown |

## Governed data snapshot backing the dashboards
| Dataset | Rows (data) | Endpoint (internal) |
|---|---|---|
| forecast_drift_signals | 168 | `http://aegis-csv/forecast_drift_signals.csv` |
| forecast_drift_family_scores | 672 (168 × 4 families) | `http://aegis-csv/forecast_drift_family_scores.csv` |
| forecast_drift_event_history | 71 | `http://aegis-csv/forecast_drift_event_history.csv` |
| forecast_drift_runs | 1 | `http://aegis-csv/forecast_drift_runs.csv` |
| forecast_drift_data_quality_checks | 18 (18 PASS / 0 FAIL) | `http://aegis-csv/forecast_drift_data_quality_checks.csv` |

Catalog SHA256 (validation == served): `9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1`
