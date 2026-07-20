# E7D.9B — Top Risk · Visual Validation

**Status:** PENDING Oscar's visual acceptance. Token `E7D9B_TOP_RISK_DASHBOARD_IMPLEMENTED_PENDING_VISUAL_ACCEPTANCE`.

The agent browser is unauthenticated, so the agent validates data (CSV reconciliation + live `/api/ds/query`) and publish status; Oscar validates the rendered visuals in his authenticated session at `http://localhost:3000/d/aegis-forecast-drift-top-keys`.

## Publish confirmation
- `POST /api/dashboards/db` → status `success`, version `4`, uid `aegis-forecast-drift-top-keys`.
- Live audit: title `AEGIS Forecast Drift — Top Risk`, tags `aegis|forecast-drift|aegis-nav|top-risk|e7d9b`, 17 panels (ids 1,2,10–14,20,21,30,40,50,51,60,70,80,90).
- UID preserved → aegis-nav dropdown and canonical URL intact. Folder `afsjccp27s0e8d`.

## Visual checklist for Oscar
1. **No "No data"** on any panel with All filters.
2. **KPI row** reads Forecast Keys = 12 · Average Drift Score = 28.83 (amber band) · Critical Signals = 14 (red) · Drift Events = 71.
3. **Highest-Risk Forecast Key** = NAM-SDF, Region NAM, Avg 42.74, Critical 4, Worst Status = Critical (red label).
4. **Top Forecast Keys** bar: 12 bars, NAM-SDF longest, colored by 20/40/70 thresholds, descending.
5. **Forecast Key Risk Summary** table: 12 rows, sorted by Avg desc, Worst Status colored, Forecast Key cell exposes the 3 drill links (Forecast / Events / Historical Timeline).
6. **Top Regions** (9 bars, NAM first) and **Top Forecast Versions** (14 bars, 2025-12-01 first) render side by side, risk-ranked.
7. **Top Drift Families** bar: volatility > stability > shape > performance. **Drift Family Computability** table shows brand-colored family names with Computable / Non-computable = 168 per family.
8. **Risk Concentration Matrix**: 12 key rows × 4 family columns, color-background cells, NAM-SDF volatility ~82 deepest red.
9. **Consolidated Risk Details**: 168 rows @ All, sorted by Drift Score desc, Drift Status / Drift Family colored, Explanation legible, no horizontal scroll.
10. **Latest Governed Run** (Run 1, Success, 18/18 context) and **Data Quality** stat renders `18 / 18` white-on-green.
11. **Filters** change rankings live per the filter-validation table; return to All restores the full view.
12. **Shared nav** shows **Top Risk** bold, all 10 links present.

## Acceptance
On Oscar's explicit approval, promote all E7D.9B artifacts + status to `E7D9B_TOP_RISK_DASHBOARD_COMPLETED_VISUALLY_ACCEPTED`. Do not self-declare acceptance. Stop before E7D.11 (Settings & Data Quality). No manual commit.
