# E7D.12 — Navigation Validation

**Validator:** `V2/scripts/test-aegis-navigation.ps1` (read-only, JSON source of truth)
**Result:** NAVIGATION: PASS (exit 0)

## Navigation contract
Every active dashboard carries the native Grafana dashboard-links dropdown:
`asDropdown=true`, `type=dashboards`, `tags=[aegis-nav]`, `includeVars=true`,
`keepTime=false`, `targetBlank=false`, `url=""` (no hardcoded URL). Time range is
therefore **not** inherited across sections; template variables **are** carried.

## Regression matrix
| Check | Expected | Observed | Result |
|---|---|---|---|
| Dashboards tagged `aegis-nav` | 10 | 10 | PASS |
| Top Scenarios in navigation | absent | absent (not tagged `aegis-nav`) | PASS |
| Native dropdown present on each nav dashboard | yes | yes (10/10) | PASS |
| `includeVars` on dropdown | true | true | PASS |
| `keepTime` on dropdown | false | false | PASS |
| Hardcoded `url` on dropdown | none | none | PASS |
| Datasource UID references | only `aegis-forecast-drift-csv` | only `aegis-forecast-drift-csv` (+ each dashboard's own uid) | PASS |
| Broken / legacy datasource UID | none | none | PASS |
| Top Risk appears once | once | once (`aegis-forecast-drift-top-keys`) | PASS |

## Per-file result
```
PASS aegis-forecast-drift-events.json
PASS aegis-forecast-drift-forecast.json
PASS aegis-forecast-drift-foundation.json
PASS aegis-forecast-drift-performance.json
PASS aegis-forecast-drift-settings.json
PASS aegis-forecast-drift-shape.json
PASS aegis-forecast-drift-stability.json
PASS aegis-forecast-drift-timeline.json
PASS aegis-forecast-drift-top-keys.json
PASS top-scenarios present, correctly NOT in nav (rollback-only)
PASS aegis-forecast-drift-volatility.json
PASS aegis-nav dashboard count = 10
NAVIGATION: PASS
```

Entry points spot-checked (Overview, Top Risk, Settings) all resolve the same
dropdown set with no time inheritance and no broken links.
