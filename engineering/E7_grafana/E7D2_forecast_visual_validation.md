# E7D.2 — Forecast MVP · Visual Validation Checklist

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-forecast` · 2026-07-19
URL: `http://localhost:3000/d/aegis-forecast-drift-forecast`

> The MCP/agent browser session is **not authenticated**, so the agent cannot render the dashboard. This
> checklist is for **Oscar** to confirm from his own logged-in Grafana session. All data/filter logic was
> validated headlessly via `/api/ds/query` (see `E7D2_forecast_reconciliation.md`).

## Oscar's first visual review (v2) — two defects found → repaired in v3 (2026-07-19)
The v2 build was reviewed by Oscar. Confirmed working: Overall gauge 28.8, Family 88/45/27/8, historical
trend, Forecast-Key ranking, Latest Governed Run, Data Quality 18/18. **Two mandatory visual defects:**
1. **Drift Status Distribution — wrong colors.** `palette-classic` colored slices **by position**, ignoring
   the value mappings. **Fix (v3):** explicit per-value field overrides (`byName`: Healthy→green, Watch→
   yellow, Warning→orange, Critical→red, `color.mode: fixed`). Color is now bound to the value/series, not
   position.
2. **Drift Score Heatmap — empty** (only the Forecast Key column; no version columns, values or colors).
   **Root cause:** the 14-target Infinity pivot fired 14 GETs to one URL → per-URL response coalescing → only
   target A returned data → after join only `forecast_key` survived. **Fix (v3):** rebuilt as a **single
   Infinity query** pivoted by the native **`groupingToMatrix`** transform (`sortBy fv_label` →
   `groupingToMatrix` → `organize`). One query = no coalescing = stable matrix. See
   `E7D2_forecast_heatmap_design.md`. Republished **v3**.

## Filter bar
- [ ] Five dropdowns render populated (not empty): **Forecast Key · Forecast Version · Region · Drift Status ·
      Run ID**, each defaulting to **All**.
- [ ] **Forecast Version** options are plain strings (e.g. `v2024-04-01` … `v2026-05-01`) with **no red
      triangle** (no time-inference).

## Row 1 — Overall score & distributions
- [ ] **Overall Forecast Drift Score** gauge reads ≈ **28.8** (All) and sits in the Watch band; bands
      green/yellow/orange/red at 20/40/70.
- [ ] **Drift Family Distribution** donut shows Stability 88 · Volatility 45 · Shape 27 · Performance 8 with
      **neutral** (non-severity) colors and a right-side legend with value + percent.
- [ ] **Drift Status Distribution** donut shows Healthy 82 · Watch 38 · Warning 34 · Critical 14 with
      **severity** colors (green/yellow/orange/red).

## Row 2 — History
- [ ] **Average Drift Score Over Time** plots **14** points along a **2024→2026** time axis, dashed
      thresholds at 20/40/70, peak at 2025-12-01 (≈ 53).
- [ ] Changing **Forecast Version** does **not** collapse the trend (it keeps all 14 points); changing
      Region / Forecast Key / Drift Status / Run ID **does** reshape it.

## Row 3 — Key risk & heatmap
- [ ] **Forecast Keys by Average Drift Score** horizontal bars, sorted descending, **NAM-SDF** on top
      (≈ 42.7), neutral blue, value labels shown.
- [ ] **Drift Score Heatmap** renders a **12-row × 14-column** matrix: rows = forecast keys, columns =
      forecast versions (chronological headers `v2024-04-01` … `v2026-05-01`), each cell severity-colored, the
      Forecast Key label column uncolored.
- [ ] Spot-check: APC-MULTITENANT @ `v2024-04-01` ≈ **25.6**, @ `v2024-05-01` ≈ **23.2**.
- [ ] Filtering a single **Forecast Version** reduces the heatmap to that one column; filtering a
      **Forecast Key** reduces it to that one row (the heatmap now honors the shared filters).

## Row 4 — Run & data quality
- [ ] **Latest Governed Run** shows Run **1** · **Success** (green) · Finished **2026-07-13 22:44 UTC** ·
      Signals Written **168** · Events Created **71**.
- [ ] **Data Quality — Checks Passed** stat reads **18 / 18** on a green background.

## Chrome & polish
- [ ] Nav bar marks **Forecast** as current and links to Overview + the other sections.
- [ ] Header/subtitle is compact; **no** shell / preview / 🚧 / "coming soon" language anywhere.
- [ ] Overall look is consistent with the accepted Overview (severity palette only where severity applies).

## Sign-off
- [x] **Oscar confirmed** the two repaired defects (status donut severity colors + heatmap matrix with real
      values/colors) plus all other panels render correctly → token
      `E7D2_FORECAST_MVP_COMPLETED_VISUALLY_ACCEPTED`.
- Token (accepted 2026-07-19, second review): `E7D2_FORECAST_MVP_COMPLETED_VISUALLY_ACCEPTED` (v3).
