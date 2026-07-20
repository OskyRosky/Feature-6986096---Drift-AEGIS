# E7D.8 — Historical Timeline · Visual Validation Checklist

The agent's shared browser is **unauthenticated**, so Oscar validates the rendered dashboard in his own authenticated Grafana session. Backend data correctness is already proven (GATES A–F). This checklist covers the visual/interaction layer.

**Open:** `http://localhost:3000/d/aegis-forecast-drift-timeline`
**Prerequisite:** if any panel shows "No data", run `docker start aegis-csv` (the nginx container does not auto-restart after a Docker restart) and refresh.

## A. Layout & chrome
- [ ] Section nav row renders; **Historical Timeline** is bold; the other 10 links navigate (vars carried, time not).
- [ ] Header and "Temporal model & Date Range" note render as written.
- [ ] Native time picker is **absent** (hidden), timezone shows UTC.
- [ ] Variable bar shows: Forecast Key, Forecast Version, Region, Drift Status, Run ID, Drift Family, **Date Range** (default "All available history").

## B. KPIs (Date Range = All available history, all filters = All)
- [ ] Timeline Records = **71**
- [ ] Drift Events = **71**
- [ ] Forecast Versions = **12**
- [ ] Affected Forecast Keys = **12**
- [ ] Lifecycle Records = **71** (label indicates Initial Open)

## C. Historical Timeline table (id 20)
- [ ] Sorted newest forecast_version first (2026-05-01 at top).
- [ ] Columns: Timeline Date (Forecast Version), Date Basis (= "Forecast Version"), Forecast Key, Drift Family (colored), Drift Score, Drift Status (colored), Explanation (wrapped).
- [ ] 71 rows at All.

## D. Charts
- [ ] "Drift Events by Forecast Version" (id 30) shows bars in chronological order, values sum to 71.
- [ ] "Timeline Records by Forecast Key" (id 32) horizontal bars, 12 keys, descending.

## E. Historical Details table (id 40)
- [ ] Columns present: Timeline Date, Date Basis, Timeline Type (= "Drift by Forecast Version"), Forecast Key, Region, Previous Version, Drift Family, Drift Score, Drift Status, Lifecycle Status (= "Open"), Explanation, Run ID.
- [ ] Column filter icons work.

## F. Provenance
- [ ] Latest Governed Run shows Run 1 / Success / 2026-07-13 22:44 / Signals 168 / Events 71.
- [ ] Data Quality shows **18 / 18 checks passed**.

## G. Date Range is FUNCTIONAL (the key acceptance) — change the Date Range variable
- [ ] All available history → Timeline Records **71**
- [ ] Year to date → **40**
- [ ] Last 180 days → **32**
- [ ] Last 90 days → **5**
- [ ] Last 60 days → **0** (empty timeline, no error)
- [ ] Last 30 days → **0**
- [ ] Year 2024 → **5**
- [ ] Year 2025 → **26**
- [ ] Year 2026 → **40**
- [ ] The table, both charts, and the KPIs all shrink/grow together with the window.

## H. Other filters (spot checks, Date Range = All)
- [ ] Region = NAM → 29 records.
- [ ] Drift Status = Critical → 14 records.
- [ ] Drift Family = Shape → 26 records.
- [ ] A single Forecast Version (e.g. v2025-12-01) → 10 records.
- [ ] Reset all to All → back to 71.

## Sign-off
- [ ] Oscar confirms visuals acceptable → promote token to `E7D8_HISTORICAL_TIMELINE_MVP_COMPLETED_VISUALLY_ACCEPTED`.
