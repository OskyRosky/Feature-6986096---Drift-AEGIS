# E7D.7 — Events Dashboard · Visual Validation (Oscar sign-off)

**Stage:** E7D.7 · **Date:** 2026-07-19
**URL:** http://localhost:3000/d/aegis-forecast-drift-events
**Token:** `E7D7_EVENTS_MVP_COMPLETED_VISUALLY_ACCEPTED` — **visually accepted by Oscar on 2026-07-20.**

> The agent's shared browser session is **unauthenticated**, so click-through and pixel checks must be
> done by Oscar in his authenticated session. Structural/data checks below were verified via the API.

## Checklist

### KPI row
- [ ] **Total Events = 71** (blue).
- [ ] **Critical Events = 14** (red).
- [ ] **Warning Events = 34** (orange).
- [ ] **Affected Forecast Keys = 12** (blue).

### Latest Event
- [ ] Shows exactly one row, the most recent (`detected_on` 2026-07-13, highest `drift_event_id`).
- [ ] Columns: Event ID, Timestamp, Forecast Key, Drift Family, Drift Score, Drift Status.
- [ ] Panel height is tight (no excess empty space below the single row).

### Charts
- [ ] **Events by Drift Family** donut: Shape 26 / Stability 24 / Volatility 15 / Performance 6; legend shows value + %.
- [ ] **Events by Drift Status** donut: Critical 14 / Warning 34 / Watch 13 / Healthy 10; **explicit severity colors** (Healthy green / Watch yellow / Warning orange / Critical red — fixed `byName` overrides, not palette-by-position).
- [ ] **Events by Forecast Key** horizontal bars, sorted descending, 12 keys.
- [ ] Family colors are visually **distinct from** severity colors (no confusion family↔status).

### Governed Event Log
- [ ] 71 rows, newest first.
- [ ] Columns present: Event ID, Timestamp (UTC), Forecast Key, Region, Forecast Version, Previous Version, Drift Family, Drift Score (2 dp), Drift Status (colored), Event Status (Open), Explanation (wrapped), Run ID.
- [ ] Drift Status cells colored by band; Drift Family cells colored (non-severity palette).
- [ ] Per-column filter icons work (native search): try Forecast Key and a word in Explanation.
- [ ] No global horizontal scrollbar; Explanation wraps.

### Footer
- [ ] **Latest Governed Run**: Run 1, Success, finished 2026-07-13T22:44 UTC, signals 168, events 71.
- [ ] **Data Quality**: 18 / 18 (green).

### Filters
- [ ] Region = NAM → Total drops to 29; clear → back to 71.
- [ ] Drift Status = Critical → 14; Drift Family = shape → 26; Forecast Key = NAM-MSIT → 9.
- [ ] Forecast Version = v2026-05-01 → 5. Combine NAM + Critical → 9.
- [ ] "All" on every filter → 71.

### Navigation & chrome
- [ ] "AEGIS Sections" dropdown lists all dashboards; selecting one does **not** carry this dashboard's time range (keepTime=false) and **keeps** variables (includeVars=true).
- [ ] Nav markdown panel highlights **Events**.
- [ ] Time picker hidden; timezone UTC.
- [ ] **No** action buttons (resolve/ack/close/edit) anywhere — read-only.

## Decision

- **ACCEPTED by Oscar on 2026-07-20.** Latest Event shows the full row without clipping; Events by Drift
  Status uses the correct explicit colors (Healthy green / Watch yellow / Warning orange / Critical red);
  data and all other panels working. Token advanced to `E7D7_EVENTS_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  **E7D.8 (Historical Timeline) not started — awaits explicit authorization.**
