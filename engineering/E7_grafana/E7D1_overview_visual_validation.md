# E7D.1 — Overview MVP · Visual Validation Checklist

**Dashboard:** AEGIS Forecast Drift — Overview
**URL:** `http://localhost:3000/d/aegis-forecast-drift-foundation`
**Published:** version 3, `status=success`, `inFolder=True` (folder `AEGIS Forecast Drift`, uid `afsjccp27s0e8d`), 15 panels.
Date: 2026-07-19.

> Grafana requires an authenticated session to render dashboards; the agent cannot log in (credentials must
> not be handled by the model), so this checklist is prepared for **Oscar's explicit visual review**. All
> underlying values are already reconciled 21/21 (see `E7D1_overview_reconciliation.md`).

## Automated pre-checks (done)
- [x] JSON valid; 15 panels; publish `success`; correct folder; UID unchanged (`aegis-forecast-drift-foundation`).
- [x] Foreign dashboard `advs2xz` not referenced/modified; datasource unchanged.
- [x] Every panel query reconciles to ground truth (21/21, 0 mismatches).
- [x] No "preview / mock / stage / foundation preview / TODO" wording in visible panel text.

## Visual checklist (for Oscar)
**Navigation & header**
- [ ] Top nav bar shows all 11 sections; **Overview** is bold/non-link; other links navigate correctly.
- [ ] Header title "AEGIS Forecast Drift — Overview" + governed read-only subtitle render.
- [ ] Section dropdown (top-right, `aegis-nav` tag) lists the 11 dashboards.

**A. KPI row**
- [ ] Total Signals = **168**, Total Events = **71**, Avg Drift Score = **28.8**.
- [ ] Critical **14** (red), Warning **34** (orange), Watch **38** (yellow), Healthy **82** (green).

**B. Drift Status Distribution (donut)**
- [ ] Four slices Healthy/Watch/Warning/Critical with correct colors; legend shows value + %.
- [ ] Counts 82 / 38 / 34 / 14; slices ordered largest→smallest.

**C. Average Drift Score Over Time**
- [ ] 14 points across forecast versions (2024-04 … 2026-05), UTC axis, ascending time.
- [ ] Dashed threshold guides at 20 / 40 / 70; 1-decimal values.

**D. Signals by Dominant Drift Family**
- [ ] Horizontal bars Stability 88 · Volatility 45 · Shape 27 · Performance 8 (descending).
- [ ] Neutral (blue) color — **not** the severity palette; labels capitalized.

**E. Forecast Keys by Drift Risk (table)**
- [ ] 12 rows; sorted by Avg Drift Score desc; top row **NAM-SDF ≈ 42.74**.
- [ ] "Avg Drift Score" cells colored by band; "Max Drift Status" shows Healthy/Watch/Warning/Critical text in band color; "Total Signals" = 14 per key.

**F. Latest Governed Run**
- [ ] Run ID 1 · Status **Success** (green) · Finished At **2026-07-13 22:44** (UTC) · Signals Written 168 · Events Created 71.

**G. Data Quality — Checks Passed**
- [ ] Reads **18 / 18** on green background; description points to Settings & Data Quality (E7D.11) for per-check detail.

**Filters (one-time interpolation confirmation)**
- [ ] All five variables default to **All** (Overview shows global 168).
- [ ] Selecting e.g. Region = APC narrows KPIs/donut/trend/family/table consistently (expect 14 signals); clearing restores 168.
- [ ] Selecting Drift Status = Critical narrows to 14; forecast_version = a single month narrows to 12.

## Sign-off
- [ ] Overview approved by Oscar → authorize **E7D.2**.
- [ ] Any change requested → note here and iterate on the Overview only.
