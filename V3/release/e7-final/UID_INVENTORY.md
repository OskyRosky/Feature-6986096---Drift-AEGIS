# UID Inventory — AEGIS Forecast Drift V2 (release `e7-final`)

All UIDs are **stable** and must not be changed (dashboard links, provisioning and
rollback all depend on them).

## Datasource
| Name | UID | Type | URL |
|---|---|---|---|
| AEGIS Forecast Drift CSV | `aegis-forecast-drift-csv` | `yesoreyeram-infinity-datasource` | `http://aegis-csv` (internal Docker network only) |

## Active navigation dashboards (10 — tag `aegis-nav`)
| # | Nav title | UID | File |
|---|---|---|---|
| 1 | Overview | `aegis-forecast-drift-foundation` | `dashboards/aegis-forecast-drift-foundation.json` |
| 2 | Forecast | `aegis-forecast-drift-forecast` | `dashboards/aegis-forecast-drift-forecast.json` |
| 3 | Performance | `aegis-forecast-drift-performance` | `dashboards/aegis-forecast-drift-performance.json` |
| 4 | Shape | `aegis-forecast-drift-shape` | `dashboards/aegis-forecast-drift-shape.json` |
| 5 | Stability | `aegis-forecast-drift-stability` | `dashboards/aegis-forecast-drift-stability.json` |
| 6 | Volatility | `aegis-forecast-drift-volatility` | `dashboards/aegis-forecast-drift-volatility.json` |
| 7 | Events | `aegis-forecast-drift-events` | `dashboards/aegis-forecast-drift-events.json` |
| 8 | Historical Timeline | `aegis-forecast-drift-timeline` | `dashboards/aegis-forecast-drift-timeline.json` |
| 9 | Top Risk | `aegis-forecast-drift-top-keys` | `dashboards/aegis-forecast-drift-top-keys.json` |
| 10 | Settings & Data Quality | `aegis-forecast-drift-settings` | `dashboards/aegis-forecast-drift-settings.json` |

## Retired dashboard (rollback-only — NOT in navigation)
| Nav title | UID | File | Note |
|---|---|---|---|
| Top Scenarios | `aegis-forecast-drift-top-scenarios` | `dashboards/retired/aegis-forecast-drift-top-scenarios.json` | Absorbed into Top Risk. Not tagged `aegis-nav`. Preserved for rollback; do not delete. |

## Navigation contract (verified per dashboard)
- Native Grafana dashboard-links dropdown: `asDropdown=true`, `type=dashboards`,
  `tags=[aegis-nav]`, `includeVars=true`, `keepTime=false`, no hardcoded `url`.
- Every panel datasource references only `aegis-forecast-drift-csv`.
