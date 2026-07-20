# E7D.6 — Volatility MVP · Visual Validation

Dashboard: **AEGIS Forecast Drift — Volatility** · `http://localhost:3000/d/aegis-forecast-drift-volatility`
Published: v2, folder *AEGIS Forecast Drift* (`afsjccp27s0e8d`), 13 panels, `inFolder=True`.

Structural validation (headless, 0 failures) and reconciliation (API replay, 0 discrepancies) are **green** (see
`E7D6_volatility_reconciliation.md`). This file records **Oscar's human visual acceptance**, which the automation
cannot self-certify.

## Checklist (to confirm in Oscar's own authenticated Grafana session)
- [ ] Nav bar shows all sections; **Volatility** is bold/current; **Stability** and **Shape** link back correctly.
- [ ] Header notes governed weight **10 %** and partial computability **144/168 (85.7 %)**.
- [ ] **A** Average Volatility Drift Score ≈ **56.04** (amber/orange band).
- [ ] **B** Volatility Signals Computable = **144**.
- [ ] **D** Volatility Coverage = **85.7 %** (green ≥ 0.9? no → amber/green per 0.7/0.9 steps; 0.857 is amber).
- [ ] **E** Maximum Volatility Drift Score = **100.00** (red band).
- [ ] **F** Volatility Drift Score Over Time renders **12** version points; axis starts **2024-06**; peak at
      **2026-01-01 (78.13)**; the first two versions (2024-04, 2024-05) are **absent** (non-computable). Lines
      linear, points visible.
- [ ] **G** Volatility Drift Score by Forecast Key (horizontal barchart) sorted desc; top **NAM-SDF (82.21)**,
      then NAM-MULTITENANT (71.04), NAM-MSIT (67.62), EUR-MSIT (66.88), IND-GO LOCAL (59.27); values labelled.
- [ ] **H** Volatility Signal Details sorted by score desc; columns = Forecast Key / Forecast Version / Previous
      Version / Region / Drift Status / Volatility Drift Score / Computable. Non-computable rows show blank score
      and **Computable = No**.
- [ ] **I** Volatility Profile — Governed Auxiliary Metrics (family-scores) shows Volatility Class + Rolling
      StdDev / CoV / MAD / Oscillation Count / Sign-Change Freq for the 144 computed rows, sorted by Rolling CoV
      desc; class colour mapping (stable/variable/erratic/erratic_single_spike).
- [ ] **J** Non-computable Summary shows **INSUFFICIENT_VERSIONS = 24**.
- [ ] **K** Latest Governed Run shows run 1, Success, 2026-07-13 22:44 UTC, 168 signals / 71 events.
- [ ] **L** Data Quality — Checks Passed shows **18/18**.
- [ ] Filters (Forecast Key / Version / Region / Drift Status / Run) update A/B/D/E/F/G/H; the two family-scores
      tables (I/J) respond to Forecast Key + Forecast Version; selecting a **non-computable version**
      (2024-04-01 / 2024-05-01) drops Coverage to **0 %** and empties the averages without error.
- [ ] No empty panel; no red query-error triangles; no "shell/coming soon" text.

## Sign-off
- Visual acceptance by Oscar: **[x] ACCEPTED** — 2026-07-19, confirmed in his authenticated Grafana session
  (principal KPIs validated). Conditional polish applied and republished as **v3**:
  - **F** Volatility Drift Score Over Time — saved range confirmed to begin at the first real bucket
    (`from = 2024-06-01`); `lineInterpolation=linear` and `showPoints=always` preserved; query and 12 buckets
    unchanged. The "empty space from 2021" was a client-side time-range override, not in the saved model.
  - **I** Volatility Profile — `rolling_stddev` (raw 221.6 → 1,270,234, no governed unit) switched from the
    ambiguous `short` (K/Mil) to explicit **`locale`** unit (full thousands-grouped integer); data unchanged.
- Token promoted to `E7D6_VOLATILITY_MVP_COMPLETED_VISUALLY_ACCEPTED`.

## Navigation-contract fix (v4) — confirm in Oscar's session
- [ ] **Overview → Volatility**: trend starts **2024-06-01**, ends ~**2026-06-01**, **12** buckets, no space from 2021.
- [ ] **Shape → Volatility**: same; no `from`/`to` inherited in the URL.
- [ ] **Stability → Volatility**: same; no `from`/`to` inherited in the URL.
- [ ] **Back to Overview**: Overview shows its own saved range (no Volatility range stuck).
- [ ] Selected filters (Forecast Key / Forecast Version / Region / Drift Status / Run ID) are **preserved** across nav.
- [ ] KPIs remain **56.04 / 144 / 85.7 % / 100.00**; Non-computable **24**; DQ **18/18**.
- Root cause: AEGIS Sections dropdown `keepTime:true` carried the live time range. Fixed to `keepTime:false` +
  `includeVars:true` (preserve filters) on **all 11** dashboards (foundation, forecast, performance, shape,
  stability, volatility, events, timeline, top-keys, top-scenarios, settings). Only the `links` block changed.

**Status token (current): `E7D6_VOLATILITY_MVP_COMPLETED_VISUALLY_ACCEPTED`.**
