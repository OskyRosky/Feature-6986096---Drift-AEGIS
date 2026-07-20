# E7D.3 — Performance MVP · Visual Validation Checklist

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-performance` · 2026-07-19
URL: `http://localhost:3000/d/aegis-forecast-drift-performance`

> The MCP/agent browser session is **not authenticated**, so the agent cannot render the dashboard. This
> checklist is for **Oscar** to confirm from his own logged-in Grafana session. All data/filter logic was
> validated headlessly via `/api/ds/query` (see `E7D3_performance_reconciliation.md`). Published **v3**,
> `status=success`, `inFolder=True`, **11 panels**.
>
> **v2 → v3 fix:** the *Performance Coverage* KPI rendered empty in v2 (its `is_comp` flag came back
> `boolean`, so the `mean` reducer produced no value). v3 adds a `convertFieldType is_comp → number` transform
> so it now reduces to **92.9 %**. **This is the panel to re-check first.**

## Filter bar
- [ ] Five dropdowns render populated (not empty): **Forecast Key · Forecast Version · Region · Drift Status ·
      Run ID**, each defaulting to **All**.
- [ ] **Forecast Version** options are plain strings (e.g. `v2024-04-01` … `v2026-05-01`) with **no red
      triangle** (no time-inference).

## Row 1 — KPIs
- [ ] **Average Performance Drift Score** reads ≈ **7.71** (All), colored in the Healthy band (low value).
- [ ] **Performance Signals Computable** reads **156**.
- [ ] **Average MAPE Change** reads ≈ **0.81 %** (percent unit, not ×100).
- [ ] **Performance Coverage** reads ≈ **92.9 %** on a **green** background (≥ 0.9 threshold) — **was empty in
      v2, repaired in v3**. Confirm it is **not** blank and that filtering (e.g. Region = NAM → still 92.9 %,
      Version = `v2025-06-01` → 100 %) keeps it populated (denominator is dynamic, not hardcoded to 168).

## Row 2 — Trend
- [ ] **Performance Drift Score Over Time** plots **13** points along a **2024 → 2026** time axis, dashed
      thresholds at 20/40/70, with peaks at **2025-06-01 (≈ 38)** and **2026-03-07 (≈ 23)**.
- [ ] The version **2026-05-01** is **absent** from the trend (all its signals are non-computable).
- [ ] Changing **Forecast Version** does **not** collapse the trend (it keeps all points); changing
      Region / Forecast Key / Drift Status / Run ID **does** reshape it.

## Row 3 — Details & non-computable
- [ ] **Performance Signal Details** lists rows sorted by **Performance Drift Score descending**, with columns
      Forecast Key · Forecast Version · Previous Version · Drift Status · Performance Drift Score · Computable ·
      Current MAPE · Previous MAPE · MAPE Change.
- [ ] **Computable** shows **Yes** (green) / **No** (red); the **No** rows correspond to version 2026-05-01.
- [ ] Current / Previous MAPE and MAPE Change are populated only for the `MAPE_deep` rows and **blank
      elsewhere** (documented limitation) — not an error.
- [ ] **Drift Status** cells are severity-colored (Healthy green / Watch yellow / Warning orange /
      Critical red).
- [ ] **Non-computable Performance Summary** shows **NO_REALIZED_OVERLAP → 12**.
- [ ] Note: the Non-computable Summary responds **only** to Forecast Key and Forecast Version (family scores
      lack Region / Drift Status / Run ID) — this is by design.

## Row 4 — Run & data quality
- [ ] **Latest Governed Run** shows Run **1** · **Success** (green) · Finished **2026-07-13 22:44 UTC** ·
      Signals Written **168** · Events Created **71**.
- [ ] **Data Quality — Checks Passed** stat reads **18 / 18** on a green background.

## Chrome & polish
- [ ] Nav bar marks **Performance** as current and links to Overview, Forecast + the other sections.
- [ ] No horizontal scrollbar spanning the whole dashboard; tables scroll vertically within their panels.
- [ ] No shell / "🚧" / "coming in E7D.3" language remains anywhere.

## Sign-off
- [x] **Oscar visual acceptance** — date: **2026-07-19** → token set to
      `E7D3_PERFORMANCE_MVP_COMPLETED_VISUALLY_ACCEPTED`. Performance Coverage confirmed **92.9 %**; all other
      components confirmed working.

_Current token: `E7D3_PERFORMANCE_MVP_COMPLETED_VISUALLY_ACCEPTED`._
