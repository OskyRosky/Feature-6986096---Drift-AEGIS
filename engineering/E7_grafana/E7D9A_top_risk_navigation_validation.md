# E7D.9A — Top Risk Navigation Consolidation — Validation

**Stage:** E7D.9A · **Date:** 2026-07-20 · **Status:** COMPLETED — VISUALLY ACCEPTED (Oscar, 2026-07-20)

All checks below were run live against `http://localhost:3000` (token DPAPI-decrypted in memory only, never printed).

## Precheck

| Check | Result |
|-------|--------|
| E7D.8 state | COMPLETED / VISUALLY ACCEPTED (Oscar, 2026-07-20) |
| Git | branch `main`, HEAD `ecd9510`; only tracked E7D.7/E7D.8 edits + untracked E7D.8 artifacts pending |
| Grafana | `Up` (container `grafana`) |
| aegis-csv | `Up (healthy)` |
| Datasource reachability | `grafana → http://aegis-csv/forecast_drift_runs.csv` returns 2 lines (header + 1 run) |
| Token DPAPI | present at `%LOCALAPPDATA%\AEGIS\secrets\grafana\aegis-mcp.token.dpapi` |
| UIDs (no name-guessing) | Top Forecast Keys `aegis-forecast-drift-top-keys`; Top Scenarios `aegis-forecast-drift-top-scenarios`; Settings `aegis-forecast-drift-settings` |
| Nav mechanism | (a) markdown nav panel id1 with `/d/<uid>` links; (b) native `links` dropdown filtered by dashboard tag `aegis-nav`; `includeVars=true`, `keepTime=false` |

## Post-publish validation

| Test | Expected | Result | Status |
|------|----------|--------|--------|
| All 11 dashboards published | 11 × `success` | 11 × `success` | ✅ |
| Canonical title | `AEGIS Forecast Drift — Top Risk` | matches | ✅ |
| Canonical UID preserved | `aegis-forecast-drift-top-keys` | preserved | ✅ |
| Top Risk resolves | url `/d/aegis-forecast-drift-top-keys`, folder `AEGIS Forecast Drift`, 5 vars, 5 rows | confirmed | ✅ |
| `aegis-nav` dropdown count | 10 | 10 | ✅ |
| Top Risk in dropdown | yes (once) | yes | ✅ |
| Top Forecast Keys in dropdown | no | absent | ✅ |
| Top Scenarios in dropdown | no | absent (tag removed) | ✅ |
| Nav panel of every dashboard | contains `Top Risk`, not `Top Forecast Keys`/`Top Scenarios` | 11/11 true | ✅ |
| Top Scenarios preserved | still resolves, queries/UID intact, `aegis-nav`=false | confirmed | ✅ |
| No dashboard deleted | 11 dashboards remain | confirmed | ✅ |

### `aegis-nav` dropdown (live `/api/search?tag=aegis-nav`) — 10 dashboards
Events · Forecast · Historical Timeline · Overview · Performance · Settings & Data Quality · Shape · Stability · **Top Risk** · Volatility

### Navigation migration
| Previous element | Action | New element | Status |
|------------------|--------|-------------|--------|
| Top Forecast Keys (`aegis-forecast-drift-top-keys`) | Renamed / reused (UID preserved) | **Top Risk** | ✅ |
| Top Scenarios (`aegis-forecast-drift-top-scenarios`) | Retired from nav (tag removed, preserved) | Absorbed into Top Risk | ✅ |

## Filter / data smoke (navigation did not break data)

- Canonical Top Risk exposes 5 shared filters (region, forecast_key, forecast_version, drift_status, run_id) — all populate from the governed datasource; no data panels yet (shell).
- Other dashboards unchanged (no query edits) → existing data continues to render; `keepTime=false` means Top Risk does not inherit a time range.
- Pending Oscar's live-session confirmation of hop-by-hop navigation (agent browser is unauthenticated).

## Visual acceptance (Oscar's session, 2026-07-20 — ACCEPTED)
Oscar visually confirmed: navigation shows a single **Top Risk**; **Top Forecast Keys** and **Top Scenarios** no longer
appear as separate destinations; Top Risk opens via the preserved canonical UID; the shell contains the five internal
sections (Top Forecast Keys, Top Regions, Top Forecast Versions, Top Drift Families, Risk Details); Top Scenarios
remains preserved outside navigation; all other menu destinations intact. **Token
`E7D9A_TOP_RISK_NAVIGATION_COMPLETED_VISUALLY_ACCEPTED`.**
