# E7D.1 — Overview MVP · Closure Summary

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: **E7D.1 — Overview MVP (analytical panels)** · Date: 2026-07-19
Dashboard: **AEGIS Forecast Drift — Overview** · uid `aegis-forecast-drift-foundation` (retained) · folder
`AEGIS Forecast Drift` (uid `afsjccp27s0e8d`) · published **version 7** (repaired ×2, polished ×1),
`status=success`, `inFolder=True`, 15 panels.
URL: `http://localhost:3000/d/aegis-forecast-drift-foundation`

> **STATUS: COMPLETED — VISUALLY ACCEPTED.**
> Oscar **visually confirmed** the Overview renders data and the numbers are correct, then requested a final
> **visual polish (v7)** — donut severity colors, a 2024-anchored time axis, a slimmer nav/header, and a
> corrected filter-semantics note (see **Polish** below) — and **formally accepted** the stage.

## What was delivered
The Overview was transformed from the E7C/E7D.0 **foundation preview** into a complete, governed analytical
dashboard that answers all 8 required questions, adapting the Power BI V1 Overview logic to Grafana + the
read-only governed V2 CSV snapshot. **The dashboard does not cook data** — all logic stays in the V1 engine;
Grafana only reads, filters (shared filter contract) and aggregates via transformations for display.

### Components built (7)
| # | Component | Panels | Result |
|---|-----------|--------|--------|
| A | KPI row | Total Signals 168 · Total Events 71 · Avg Drift 28.8 · Critical 14 · Warning 34 · Watch 38 · Healthy 82 | ✅ |
| B | Drift Status Distribution donut | 82 / 38 / 34 / 14, severity palette | ✅ |
| C | Avg Drift Score over time | 14 forecast-version points (timestamp X-axis), thresholds 20/40/70, UTC; respects region/key/status/run filters | ✅ |
| D | Signals by dominant family (h-bars) | Stability 88 · Volatility 45 · Shape 27 · Performance 8, neutral color | ✅ |
| E | Forecast Keys by drift risk (table) | 12 keys, avg desc (NAM-SDF 42.74 top), max-status band, total signals | ✅ |
| F | Latest Governed Run | Run 1 · Success · 2026-07-13 22:44 UTC · 168 · 71 | ✅ |
| G | Data Quality — Checks Passed | 18 / 18 (green) | ✅ |

## Validation
- **Analytical reconciliation: 21 / 21 metrics matched, 0 mismatches** (`E7D1_overview_reconciliation.md`).
- Internal consistency: severity KPIs and family counts each sum to 168; events/signals cross-reconcile
  across signals, event-history and runs.
- Filter logic validated via literal-equivalent expressions (region APC→14, Critical→14, version→12,
  All→168, events→71).
- Visual validation checklist prepared for Oscar (`E7D1_overview_visual_validation.md`); Grafana login is
  required to render, so live visual sign-off is reserved for Oscar.

## Key technical decisions
- **Time dimension = `forecast_version`** (14 clean monthly buckets); `detected_on` constant and `target_date`
  noisy were rejected.
- **`forecast_version` filtered via a non-date `v`-prefixed label** (`fv_label = 'v' + forecast_version`) to
  avoid both the Grafana frontend time-inference on the variable and the Infinity string-date-arithmetic
  `IN` bug; the trend panel keeps `forecast_version` as `timestamp` for its X-axis. `run_id` filtered as
  quoted string. No Overview question left unanswerable by a CSV limitation.
- **"Top Forecast Keys"** replaces the V1 "Top Services" mockup (`service` empty in governed data).
- Severity palette only where severity applies; family bars neutral. Dashboard timezone = UTC.

## Artifacts
- `engineering/E7_grafana/E7D1_overview_requirements.md`
- `engineering/E7_grafana/E7D1_overview_query_contract.md`
- `engineering/E7_grafana/E7D1_overview_reconciliation.md`
- `engineering/E7_grafana/E7D1_overview_visual_validation.md`
- `engineering/E7_grafana/E7D1_overview_closure_summary.md` (this file)
- Updated governed export `V2/grafana/dashboards/aegis-forecast-drift-foundation.json`
- New publish script `V2/scripts/push-e7d1-overview.ps1` (single-dashboard, DPAPI in-memory token)
- Updated `PROJECT_STATUS.md`, `engineering/ROADMAP.md`, `V2/README.md`

## Scope & safety honored
Modified **only** the Overview + its artifacts/publish script. Did **not** build or modify any of the other
10 dashboards, the datasource, nginx, Docker, CSVs, Python, Power BI V1, weights, thresholds, alerts,
plugins, token, DPAPI or MCP. No dashboard deleted. Token DPAPI-decrypted **in memory only**, never printed;
repo remains secret-free. **No manual commit** (R1 auto-commit process untouched). Foreign dashboard
`advs2xz` untouched.

## Repair (2026-07-19) — why v3 rendered "No data" and how v5 fixes it
The v3 closure prematurely declared COMPLETED; live Grafana showed empty filters and "No data" on all
panels. Root cause was **not** the query logic (which reconciled) but two structural defects invisible to
raw `/api/ds/query` tests:

1. **Template variables lacked the `queryType:"infinity"` wrapper.** All 5 variable `query` objects were
   stored as flat `InfinityQuery` payloads. The Infinity plugin (`src/app/variablesQuery/index.ts`,
   `migrateLegacyQuery`) treats any target without `queryType` as a **legacy** query and returns an empty
   result → **all 5 dropdowns were empty** → `${var:singlequote}` interpolated to nothing →
   `region IN ()` → backend "invalid filter expression" on **every** panel. **Fix:** each variable query is
   now wrapped as `{ queryType:"infinity", refId:"variable", infinityQuery:{ …csv/url/backend query… } }`.
2. **Panels 23 & 24 aliased a *filtered* column.** `forecast_key`→"Forecast Key" (panel 23) and
   `calculation_run_id`→"Run ID" (panel 24) renamed columns that the `filterExpression` referenced, so the
   backend raised `No parameter 'forecast_key' / 'calculation_run_id' found`. **Fix:** the filtered column's
   `text` now equals its selector; the display header is restored via an organize/rename transformation
   (panel 23) and a `displayName` field override (panel 24).

Confirmed from plugin source (`src/interpolate.ts`) that the **frontend does interpolate**
`filterExpression` for backend queries — so once the variables populate, the shared filter contract works.
The broken published JSON was archived to
`V2/grafana/dashboards/archive/aegis-forecast-drift-foundation-e7d1-broken.json`.

**Post-repair verification (v5):** end-to-end per-panel test replaying each *published* target with the
`All`-expanded interpolation → **13 / 13 filter panels PASS, 0 FAIL** (Total Signals 168, Events 71,
Critical 14, Warning 34, Watch 38, Healthy 82, distribution/trend/family 168, keys 168, Latest Run 1,
Data Quality 1 row = 18/18). Baseline and filter reconciliation re-run and PASS.

## Repair #2 (2026-07-19) — the `forecast_version` red triangle
After Repair #1, four of the five dropdowns populated but **`forecast_version` alone showed a red error
triangle**, and because the shared filter AND-chains `forecast_version IN (…)`, every signal panel went back
to "No data". The five variable definitions were byte-identical except the selector, so structure was not the
cause. The real cause: `forecast_version`'s values are **ISO dates** (`2024-04-01`). Grafana's **frontend**
infers ISO-date variable option values as a `time` field, which breaks that variable → empty options →
`${forecast_version:singlequote}` interpolates to nothing → `forecast_version IN ()` → the whole expression
fails. (Panels 24/25 filter only by `run_id`, so they kept working — matching what Oscar saw.)

A related Infinity constraint compounded it: a **string** column rejects `IN ('2024-04-01')` (the literal is
parsed as date arithmetic → 0 rows), so the earlier build had to type `forecast_version` as `timestamp`; and
Infinity computed columns expose **no** string/date cast functions, while epoch matching on a timestamp column
only works unquoted in *seconds* — too fragile to rely on.

**Fix (v6):** introduce a non-date **`v`-prefixed label** and filter on it everywhere.
- **Variable `forecast_version`:** selects `forecast_version` as `string` and adds
  `computed_columns: [{ selector: "'v' + forecast_version", text: "__value" }]`; the plugin uses the
  `__value` field for the option text+value, so options become `v2024-04-01 …` (non-date → no time-inference
  → no red triangle). The dropdown now *displays* the `v` prefix — an accepted cosmetic trade-off.
- **Signal panels 10–16, 20, 22, 23 (10 panels):** `forecast_version` column retyped `timestamp`→`string`,
  a `computed_columns` `fv_label = 'v' + forecast_version` added, and the filter clause changed from
  `forecast_version IN (…)` to `fv_label IN (${forecast_version:singlequote})`.
- **Trend panel 21:** keeps `forecast_version` as `timestamp` for its time X-axis (Infinity dedupes a column
  selected twice, so it cannot carry both a timestamp and a string copy); its `forecast_version` filter
  clause was **removed** — it still honours region/key/status/run and shows the full version trend. Wiring
  per-version self-filtering on this one panel is offered as a later refinement.

**Post-repair verification (v6):** JSON valid; 0 `forecast_version IN` remaining in filters; 10 panels carry
`fv_label`; exactly 1 `timestamp` column (panel 21) and 1 `__value` variable computed. End-to-end per-panel
test → **13 / 13 PASS, 0 FAIL** with the governed ground truth (168 / 71 / 14 / 34 / 38 / 82 / run 1 /
18-of-18). **Oscar visually confirmed the Overview now shows data.**

## Polish (v7 — visual acceptance)
Applied only cosmetic/display changes at Oscar's request; **no query, metric, filter, or analytical layout
change**:
1. **Donut severity colors** — panel 20 now uses `palette-classic` + value mappings so slices render Healthy
   **green**, Watch **yellow**, Warning **orange**, Critical **red**.
2. **Time axis anchored to 2024** — dashboard time range set to `2024-03-01 → 2026-06-01` (timepicker stays
   hidden), removing the empty 2022–2024 gap on the trend so the X-axis starts at the first real 2024 data.
3. **Slimmer chrome** — nav bar (panel 1) and header (panel 2) reduced from `h:3` to `h:2` each; all content
   and every navigation link retained; downstream panels reflowed up by 2 rows (no gaps/overlaps).
4. **Corrected filter semantics** — the header no longer claims *every* panel honors *all* filters. It now
   documents that KPIs, distribution, families and ranking honor all five filters, while the **trend
   intentionally ignores Forecast Version** to preserve the full historical evolution (also noted in panel
   21's description). Per Oscar, the trend keeps showing all versions by design.

**Post-polish verification (v7):** JSON valid; layout reflow clean; end-to-end per-panel replay **13 / 13
PASS, 0 FAIL** (168 / 71 / 14 / 34 / 38 / 82 / run 1 / 18-of-18) — data still fully visible. **Oscar formally
accepted.**

## Open risk
- **R1** (auto-commit ownership) unchanged.
- Minor cosmetic by design: the Forecast Version dropdown displays a `v` prefix (e.g. `v2024-04-01`).
- Trend panel 21 intentionally does not self-filter by forecast version (shows all versions) — accepted by
  Oscar to preserve historical context.

**Token: E7D1_OVERVIEW_MVP_COMPLETED_VISUALLY_ACCEPTED.** Stage E7D.1 is complete and visually accepted by
Oscar. Do **not** start E7D.2 until separately authorized.
