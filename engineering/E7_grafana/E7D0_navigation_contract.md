# E7D.0 — Navigation Contract

**Stage:** E7D.0 — Dashboard Information Architecture & Shared Navigation
**Date:** 2026-07-19

## Constraint

Grafana 13 does not allow freely replacing its native sidebar with the mockup's sidebar.
Navigation is therefore implemented with **native, sustainable** mechanisms only.

## Two complementary native mechanisms (identical on all 11 dashboards)

### 1. Shared navigation panel (primary — shows active section)

- A **Grafana text/markdown panel** pinned at the top of every dashboard (`gridPos y=0, h=3, w=24`).
- Lists **all 11 sections in the same fixed order**.
- The **active** section is rendered **bold, without a link**; the others are **relative markdown links**
  `[Section](/d/<uid>)`.
- Uses **local relative paths + stable UIDs** — no external hostname, no `http://localhost:3000` hardcoding,
  no HTML, no plugins.

Fixed order & targets (updated in **E7D.9A** — Top Forecast Keys + Top Scenarios consolidated into **Top Risk**):

| Order | Label | Target |
|-------|-------|--------|
| 1 | Overview | `/d/aegis-forecast-drift-foundation` |
| 2 | Forecast | `/d/aegis-forecast-drift-forecast` |
| 3 | Performance | `/d/aegis-forecast-drift-performance` |
| 4 | Shape | `/d/aegis-forecast-drift-shape` |
| 5 | Stability | `/d/aegis-forecast-drift-stability` |
| 6 | Volatility | `/d/aegis-forecast-drift-volatility` |
| 7 | Events | `/d/aegis-forecast-drift-events` |
| 8 | Historical Timeline | `/d/aegis-forecast-drift-timeline` |
| 9 | Top Risk | `/d/aegis-forecast-drift-top-keys` |
| 10 | Settings & Data Quality | `/d/aegis-forecast-drift-settings` |

> **E7D.9A consolidation (2026-07-20):** the former sections **Top Forecast Keys** (order 9) and **Top Scenarios**
> (order 10) were merged into a single **Top Risk** section. The **canonical dashboard reuses the Top Forecast Keys
> UID `aegis-forecast-drift-top-keys`** (preserved to avoid breaking links/provisioning). **Top Scenarios**
> (uid `aegis-forecast-drift-top-scenarios`) is retired from navigation (its `aegis-nav` dashboard tag removed) but
> preserved for rollback. The `aegis-nav` dropdown therefore lists **10** dashboards.

### 2. Native dashboard links dropdown (secondary — Grafana top bar)

Each dashboard declares a native `links` entry:

```json
{ "asDropdown": true, "title": "AEGIS Sections", "type": "dashboards",
  "tags": ["aegis-nav"], "keepTime": true, "targetBlank": false }
```

- Renders a **"AEGIS Sections"** dropdown in Grafana's dashboard top bar.
- Auto-populated by the shared tag **`aegis-nav`** carried by the active dashboards (**10** after E7D.9A;
  Top Scenarios' tag was removed on retirement).
- `keepTime: false` — the target loads its own saved range (corrected in E7D.6; the original `true` caused stale
  time ranges). `includeVars: true` preserves the shared template variables across navigation.

## Rules honored

- ✅ Dashboard links / native mechanisms compatible with Grafana 13.
- ✅ Same navigation and same order on every dashboard.
- ✅ Visible link to all 11 dashboards.
- ✅ Active dashboard clearly indicated (bold, non-link in the nav panel).
- ✅ No navigation plugins installed.
- ✅ No unsafe HTML (markdown only, Grafana-sanitized).
- ✅ No hardcoded links tied to an external hostname (relative `/d/<uid>`).
- ✅ Stable UIDs used as the routing key.

The product feels like a single application inside the `AEGIS Forecast Drift` folder.
