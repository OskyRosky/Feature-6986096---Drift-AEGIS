# E7D.9A — Top Risk Navigation Consolidation — Closure Summary

**Stage:** E7D.9A · **Date:** 2026-07-20 · **Status:** COMPLETED — VISUALLY ACCEPTED (Oscar, 2026-07-20)
**Token:** `E7D9A_TOP_RISK_NAVIGATION_COMPLETED_VISUALLY_ACCEPTED`

## Closure

| Field | Result |
|-------|--------|
| Task | E7D.9A — Top Risk Navigation Consolidation |
| Status | COMPLETED — VISUALLY ACCEPTED (Oscar, 2026-07-20) |
| Objective achieved? | Yes (navigation + destination shell only) |
| Canonical dashboard | AEGIS Forecast Drift — Top Risk |
| Canonical UID (preserved) | `aegis-forecast-drift-top-keys` |
| Absorbed dashboard | AEGIS Forecast Drift — Top Scenarios |
| Absorbed UID (preserved) | `aegis-forecast-drift-top-scenarios` |
| Navigation | 10 sections; single Top Risk link; dropdown = 10 |
| Dashboards updated | 11 (9 nav-only + canonical transform + retired scenarios) |
| Backups | `archive/top-risk-navigation-pre-e7d9a/` (both shells + nav block) |
| Risks | old `/d/aegis-forecast-drift-top-scenarios` links now land on a retired (non-nav) dashboard with a "consolidated into Top Risk" banner |
| Next step | E7D.9B — Top Risk Dashboard Content |
| Authorization required | Yes |

## Navigation: before → after

**Before (11 sections):** Overview · Forecast · Performance · Shape · Stability · Volatility · Events · Historical Timeline · **Top Forecast Keys** · **Top Scenarios** · Settings & Data Quality

**After (10 sections):** Overview · Forecast · Performance · Shape · Stability · Volatility · Events · Historical Timeline · **Top Risk** · Settings & Data Quality

## Dashboards updated

| Dashboard | UID | Previous nav | New nav | Status |
|-----------|-----|--------------|---------|--------|
| Overview | aegis-forecast-drift-foundation | Top Keys + Top Scenarios | Top Risk | ✅ |
| Forecast | aegis-forecast-drift-forecast | Top Keys + Top Scenarios | Top Risk | ✅ |
| Performance | aegis-forecast-drift-performance | Top Keys + Top Scenarios | Top Risk | ✅ |
| Shape | aegis-forecast-drift-shape | Top Keys + Top Scenarios | Top Risk | ✅ |
| Stability | aegis-forecast-drift-stability | Top Keys + Top Scenarios | Top Risk | ✅ |
| Volatility | aegis-forecast-drift-volatility | Top Keys + Top Scenarios | Top Risk | ✅ |
| Events | aegis-forecast-drift-events | Top Keys + Top Scenarios | Top Risk | ✅ |
| Historical Timeline | aegis-forecast-drift-timeline | Top Keys + Top Scenarios | Top Risk | ✅ |
| **Top Risk (canonical)** | **aegis-forecast-drift-top-keys** | self = Top Forecast Keys | self = **Top Risk** | ✅ |
| Top Scenarios (retired) | aegis-forecast-drift-top-scenarios | self = Top Scenarios | Top Risk (retired from nav) | ✅ |
| Settings & Data Quality | aegis-forecast-drift-settings | Top Keys + Top Scenarios | Top Risk | ✅ |

## Links & configuration
- Markdown nav panel id1: single `[Top Risk](/d/aegis-forecast-drift-top-keys)`; active section bold/non-link.
- Native dropdown `AEGIS Sections`: tag `aegis-nav`, `includeVars=true`, `keepTime=false`; membership = 10 (Top Scenarios tag removed).

## What was NOT modified
- No analytical panels / KPIs / tables / queries built.
- No dashboard deleted. No UID swapped. Top Scenarios queries untouched.
- No CSV / Python / datasource / Docker / nginx / token / DPAPI / MCP / weights / thresholds change.
- No plugins, no alerts. No manual commit. R1 unchanged.

## Rollback strategy
1. Restore `archive/top-risk-navigation-pre-e7d9a/aegis-forecast-drift-top-keys.PRE-E7D9A.json` and
   `...top-scenarios.PRE-E7D9A.json`, plus re-add the `aegis-nav` tag to Top Scenarios.
2. Restore the pre-change nav block (`nav-block-pre-e7d9a.md`) across the 11 dashboards.
3. Republish with the same DPAPI publisher. Since all UIDs are preserved, rollback restores the two-destination nav exactly.

## E7D.9A vs E7D.9B
- **E7D.9A (this stage):** navigation architecture + a clean Top Risk **shell** (no data).
- **E7D.9B (next):** build the governed Top Risk analytical content (Top Forecast Keys, Top Regions, Top Forecast Versions, Top Drift Families, Risk Details, KPIs); the provisional note and empty rows are removed then.

## Exact URL
`http://localhost:3000/d/aegis-forecast-drift-top-keys`
