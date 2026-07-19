# E7D.0 — Validation

**Stage:** E7D.0 — Dashboard Information Architecture & Shared Navigation
**Date:** 2026-07-19

## Validation matrix

| # | Check | Method | Result | Status |
|---|-------|--------|--------|--------|
| 1 | 11 dashboards exist in folder `afsjccp27s0e8d` | Grafana API `GET /api/dashboards/uid/*` | all 11 `inFolder=True` | ✅ |
| 2 | Overview keeps E7C functional panels | JSON diff + panel count | 6 panels (nav + header + Latest Run + Total Signals + Status Distribution + Top 10) | ✅ |
| 3 | Other 10 are structural shells | JSON review | nav + header + purpose panel only (no analytic panels) | ✅ |
| 4 | Navigation works from/to all | Relative `/d/<uid>` links + `aegis-nav` dropdown | present & identical on all 11 | ✅ |
| 5 | No broken links | UIDs match the registry exactly | all targets resolve to real UIDs | ✅ |
| 6 | No duplicate UIDs | `GET /api/search` inventory | 11 unique AEGIS UIDs; no duplicate Overview | ✅ |
| 7 | Shared filters load where applicable | Infinity query vars from governed CSVs | region 9 / forecast_key 12 / forecast_version 14 / drift_status 4 / run_id 1 | ✅ |
| 8 | No empty variables | Cardinality inspection | every variable returns ≥1 real value | ✅ |
| 9 | No "No data" panels | Shells use purpose text panels | no empty analytic panels created | ✅ |
| 10 | Foreign dashboard intact | `GET /api/search` before/after | `advs2xz` "First Grana DAshboard" untouched | ✅ |
| 11 | Datasource unchanged | `GET /api/datasources/uid/aegis-forecast-drift-csv` | name/type/uid unchanged (Infinity) | ✅ |
| 12 | CSV / nginx / Docker / Python / PBI V1 unchanged | no such calls issued | not modified | ✅ |
| 13 | MCP still Connected | `claude mcp list` | `grafana` ✓ Connected | ✅ |
| 14 | No secret exposed | token-literal scan of repo (json/ps1/md) | `TOKEN_LITERAL_SCAN=CLEAN` (no hardcoded tokens) | ✅ |

## Publish / verification evidence

- Publisher: `V2/scripts/push-e7d0-structure.ps1` (service-account token DPAPI-decrypted in memory only,
  never printed; zeroed in `finally`).
- Folder confirmed: `AEGIS Forecast Drift` (uid `afsjccp27s0e8d`).
- Inventory before publish: 2 dashboards total (1 = our E7C foundation, 1 = foreign `advs2xz`).
- Publish results: Overview updated to **version 2**; 10 shells created at **version 1**; all `status=success`.
- Post-publish verification: all 11 `inFolder=True`; datasource lookup OK.

## Secret-scan note

A broad pattern scan initially flagged `start-mcp-grafana.ps1` line
`$env:GRAFANA_SERVICE_ACCOUNT_TOKEN = $plain` — this is a **variable assignment in memory**, not a
hardcoded secret. A targeted literal scan (`glsa_…`, JWT, `Bearer <literal>`) returned **CLEAN**.

## Dashboard URLs (for visual review)

| Section | URL |
|---------|-----|
| Overview | http://localhost:3000/d/aegis-forecast-drift-foundation |
| Forecast | http://localhost:3000/d/aegis-forecast-drift-forecast |
| Performance | http://localhost:3000/d/aegis-forecast-drift-performance |
| Shape | http://localhost:3000/d/aegis-forecast-drift-shape |
| Stability | http://localhost:3000/d/aegis-forecast-drift-stability |
| Volatility | http://localhost:3000/d/aegis-forecast-drift-volatility |
| Events | http://localhost:3000/d/aegis-forecast-drift-events |
| Historical Timeline | http://localhost:3000/d/aegis-forecast-drift-timeline |
| Top Forecast Keys | http://localhost:3000/d/aegis-forecast-drift-top-keys |
| Top Scenarios | http://localhost:3000/d/aegis-forecast-drift-top-scenarios |
| Settings & Data Quality | http://localhost:3000/d/aegis-forecast-drift-settings |
