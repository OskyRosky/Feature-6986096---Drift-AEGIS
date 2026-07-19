# E7D.0 — Dashboard Registry

**Stage:** E7D.0 — Dashboard Information Architecture & Shared Navigation
**Date:** 2026-07-19
**Folder:** `AEGIS Forecast Drift` — uid `afsjccp27s0e8d`
**Datasource:** `AEGIS Forecast Drift CSV` — uid `aegis-forecast-drift-csv` (Infinity, read-only)

## Registry (11 dashboards, all in the AEGIS folder)

| # | Title | UID | Governed JSON | Type | Nav tag |
|---|-------|-----|---------------|------|---------|
| 1 | AEGIS Forecast Drift — Overview | `aegis-forecast-drift-foundation` | `aegis-forecast-drift-foundation.json` | Functional (E7C panels) + nav | `aegis-nav` |
| 2 | AEGIS Forecast Drift — Forecast | `aegis-forecast-drift-forecast` | `aegis-forecast-drift-forecast.json` | Shell | `aegis-nav` |
| 3 | AEGIS Forecast Drift — Performance | `aegis-forecast-drift-performance` | `aegis-forecast-drift-performance.json` | Shell | `aegis-nav` |
| 4 | AEGIS Forecast Drift — Shape | `aegis-forecast-drift-shape` | `aegis-forecast-drift-shape.json` | Shell | `aegis-nav` |
| 5 | AEGIS Forecast Drift — Stability | `aegis-forecast-drift-stability` | `aegis-forecast-drift-stability.json` | Shell | `aegis-nav` |
| 6 | AEGIS Forecast Drift — Volatility | `aegis-forecast-drift-volatility` | `aegis-forecast-drift-volatility.json` | Shell | `aegis-nav` |
| 7 | AEGIS Forecast Drift — Events | `aegis-forecast-drift-events` | `aegis-forecast-drift-events.json` | Shell | `aegis-nav` |
| 8 | AEGIS Forecast Drift — Historical Timeline | `aegis-forecast-drift-timeline` | `aegis-forecast-drift-timeline.json` | Shell | `aegis-nav` |
| 9 | AEGIS Forecast Drift — Top Forecast Keys | `aegis-forecast-drift-top-keys` | `aegis-forecast-drift-top-keys.json` | Shell | `aegis-nav` |
| 10 | AEGIS Forecast Drift — Top Scenarios | `aegis-forecast-drift-top-scenarios` | `aegis-forecast-drift-top-scenarios.json` | Shell | `aegis-nav` |
| 11 | AEGIS Forecast Drift — Settings & Data Quality | `aegis-forecast-drift-settings` | `aegis-forecast-drift-settings.json` | Shell | `aegis-nav` |

## Clean URLs (redirect to slug)

- Overview — `http://localhost:3000/d/aegis-forecast-drift-foundation`
- Forecast — `http://localhost:3000/d/aegis-forecast-drift-forecast`
- Performance — `http://localhost:3000/d/aegis-forecast-drift-performance`
- Shape — `http://localhost:3000/d/aegis-forecast-drift-shape`
- Stability — `http://localhost:3000/d/aegis-forecast-drift-stability`
- Volatility — `http://localhost:3000/d/aegis-forecast-drift-volatility`
- Events — `http://localhost:3000/d/aegis-forecast-drift-events`
- Historical Timeline — `http://localhost:3000/d/aegis-forecast-drift-timeline`
- Top Forecast Keys — `http://localhost:3000/d/aegis-forecast-drift-top-keys`
- Top Scenarios — `http://localhost:3000/d/aegis-forecast-drift-top-scenarios`
- Settings & Data Quality — `http://localhost:3000/d/aegis-forecast-drift-settings`

## UID decisions & conflict handling

- **Overview UID retained as `aegis-forecast-drift-foundation`** (the E7C dashboard), retitled to
  "AEGIS Forecast Drift — Overview". The proposed `aegis-forecast-drift-overview` was **not adopted**:
  a safe UID change in Grafana requires creating a new dashboard and **deleting** the old one, which is
  explicitly prohibited ("No borrar dashboards existentes") and would risk duplicate Overviews. Keeping
  the UID is the safe, verifiable choice; the E7C panels and data are preserved (dashboard version 1 → 2).
- The other 10 UIDs are **new** and were confirmed **conflict-free** before publishing.
- **Conflict guard:** the publisher refuses to overwrite any UID that lives outside the AEGIS folder.
  Pre-existing foreign dashboard `advs2xz` ("First Grana DAshboard") was detected and **left untouched**.

## Publish evidence (Grafana API, service account, token in-memory only)

| UID | Version after publish | Status | In folder `afsjccp27s0e8d` |
|-----|-----------------------|--------|-----------------------------|
| aegis-forecast-drift-foundation | 2 (updated in place) | success | ✅ |
| aegis-forecast-drift-forecast | 1 | success | ✅ |
| aegis-forecast-drift-performance | 1 | success | ✅ |
| aegis-forecast-drift-shape | 1 | success | ✅ |
| aegis-forecast-drift-stability | 1 | success | ✅ |
| aegis-forecast-drift-volatility | 1 | success | ✅ |
| aegis-forecast-drift-events | 1 | success | ✅ |
| aegis-forecast-drift-timeline | 1 | success | ✅ |
| aegis-forecast-drift-top-keys | 1 | success | ✅ |
| aegis-forecast-drift-top-scenarios | 1 | success | ✅ |
| aegis-forecast-drift-settings | 1 | success | ✅ |

Publisher script (secret-free): `V2/scripts/push-e7d0-structure.ps1`.
