# E7D.4 — Shape MVP · Visual Validation

Dashboard: **AEGIS Forecast Drift — Shape** · `http://localhost:3000/d/aegis-forecast-drift-shape`
Published: v2, folder *AEGIS Forecast Drift* (`afsjccp27s0e8d`), 10 panels, `inFolder=True`.

Structural validation (headless) and reconciliation (API replay) are **green** (see
`E7D4_shape_reconciliation.md`). This file records **Oscar's human visual acceptance**, which the automation
cannot self-certify.

## Checklist (to confirm in Oscar's own authenticated Grafana session)
- [ ] Nav bar shows all sections; **Shape** is bold/current.
- [ ] **A** Average Shape Drift Score ≈ **26.03** (amber band).
- [ ] **B** Shape Signals Computable = **168**.
- [ ] **C** Shape Coverage = **100.0 %** (green).
- [ ] **D** Maximum Shape Drift Score = **100.00** (red band).
- [ ] **E** Shape Drift Score Over Time renders 14 version points; peak at **2025-12-01 (62.60)**, secondary
      **2026-03-07 (44.08)**, low **2026-04-16 (9.59)**.
- [ ] **F** Shape Signal Details lists signals sorted by score desc; top rows are Critical (score 100);
      columns = Forecast Key / Forecast Version / Previous Version / Region / Drift Status / Shape Drift Score /
      Computable. No empty MAPE/auxiliary columns.
- [ ] **H** Latest Governed Run shows run 1, Success, 2026-07-13 22:44 UTC, 168 signals / 71 events.
- [ ] **I** Data Quality — Checks Passed shows **18/18**.
- [ ] Filters (Forecast Key / Version / Region / Drift Status / Run) update A/B/D/F and keep trend history when a
      version is selected; coverage stays 100 %.
- [ ] No empty panel; no "shell/coming soon" text.

## Sign-off
- Visual acceptance by Oscar: **[x] ACCEPTED (2026-07-19)** — metrics, details table and governance approved. Post-acceptance polish applied to the trend panel (see below) and re-approved.
- Token promoted to `E7D4_SHAPE_MVP_COMPLETED_VISUALLY_ACCEPTED`.

## Post-acceptance polish (trend panel id30, v3)
- Dashboard time range start moved to **2024-04-01** (first real forecast version) to remove the empty pre-2024 space.
- Trend `lineInterpolation` changed **smooth → linear** (no over-smoothed interpolation between versions).
- Real per-version points kept visible (`showPoints: always`).
- **No change** to queries, metrics, filters, KPIs, the details table or any other dashboard. Republished **only** Shape → v3. KPIs re-verified intact: 26.03 / 168 / 100.0 % / 100.00 / DQ 18/18.

**Status token (current): `E7D4_SHAPE_MVP_COMPLETED_VISUALLY_ACCEPTED`.**
