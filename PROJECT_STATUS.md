# PROJECT STATUS — AEGIS Forecast Drift Framework

**Feature 6986096 — Integrate Cross-Functional Capacity Feedback Signals to Align and Improve Capacity Mitigation Actions**
Last updated: 2026-07-19

> Microsoft internal / confidential. Engineering stages (E-prefix) build the product; product/document versions (V1/V2/V3) are separate. See `engineering/ROADMAP.md`.

## Current stage
**E7D.7 — Events MVP (governed event log): REPAIRED — PENDING VISUAL ACCEPTANCE (Oscar).**
> **Visual repair (v5–v6):** (1) **Events by Drift Status** donut now colors each slice with **explicit
> `byName` fixed-color overrides** (Healthy green / Watch yellow / Warning orange / Critical red) instead
> of `palette-classic` (which colored by position and ignored the value mappings); (2) **Latest Event**
> panel kept at `h:4` (a trial `h:3` clipped the single data row) to show Event ID / Event Timestamp
> / Forecast Key / Drift Family / Drift Score / Drift Status without excess space. **No queries, filters, metrics,
> Event Log or other dashboards changed.** KPIs re-verified unchanged (Total **71**, Critical **14**,
> Warning **34**, Affected Forecast Keys **12**, Data Quality **18/18**).
> Transformed the **Events** section (uid `aegis-forecast-drift-events` **retained**) from the E7D.0
> structural shell into a **read-only** operational dashboard over the governed drift-**event** log.
> **Key data finding:** `forecast_drift_event_history.csv` is a **thin** 7-column lifecycle table (all
> `new_status = Open`, single `changed_at`) — **not** the rich event source; the **71 governed events are
> the subset of `forecast_drift_signals.csv` where `is_event = 1`**, which carries every rich field
> (forecast_key, region, dominant_drift_family, forecast_drift_score, drift_status, explanation,
> event_status). **13 panels:** Total Events (**71**), Critical (**14**), Warning (**34**), Affected
> Forecast Keys (**12**); Latest Event; **Events by Drift Family** donut (shape 26 / stability 24 /
> volatility 15 / performance 6, non-severity palette); **Events by Drift Status** donut (Critical 14 /
> Warning 34 / Watch 13 / Healthy 10, severity palette); **Events by Forecast Key** barchart (single
> detection instant → **no over-time trend**); the full **Governed Event Log** (71 rows, newest first,
> native column-filter search, wrapped Explanation); **Latest Governed Run** (1 · Success · 168 · 71) and
> **Data Quality** (18/18). **Read-only by design** — no resolve/ack/close/edit, no invented lifecycle
> states (only governed `event_status = Open` shown verbatim), no invented Severity (`drift_status` is
> the governed band; `severity` alias not surfaced), no invented Service/Scenario/Event Type (empty /
> single-valued / absent in the snapshot). **6 data-driven filters:** forecast_key, forecast_version
> (via `fv_label`), region, drift_status, run_id, **drift_family** (local). *Documented deviation vs the
> E7D.0 filter matrix:* Events **adds** `forecast_version` + `drift_family` because the event rows are the
> `signals` subset where both are native dimensions. **Nothing hardcoded** — 71 derives from
> `is_event = 1`; the mockup's "170 events" is illustrative only, the **CSV is the sole source of truth**.
> **Infinity rule reaffirmed:** every column in a `filterExpression` must be a **selected** column (or
> `computed_columns`); `fv_label = 'v'+forecast_version` requires `forecast_version` to be selected (a
> harness that omitted it returned 0 — the dashboard panels select it → filter returns the correct 5).
> **Reconciliation 0 discrepancies** (KPIs + family/status distributions + affected keys + explanation
> 71/71 + event_status Open + max score 84.72 + run footer + **9 filter scenarios**: All 71, NAM 29,
> Critical 14, Run1 71, shape 26, NAM-MSIT 9, v2026-05-01 5, back-to-All 71, NAM+Critical 9). Published
> **only** the Events dashboard via `V2/scripts/push-e7d7-events.ps1` (token **DPAPI-decrypted in memory
> only**, never printed) → **v6**, `success`, `inFolder`, 13 panels, `keepTime=false`, `includeVars=true`,
> saved range **2026-07-01 → 2026-07-31** (timepicker hidden, UTC); shell backed up at
> `V2/grafana/dashboards/archive/aegis-forecast-drift-events-shell.json`. **Allowed exception applied:**
> the shared `links` block keeps `keepTime=false`/`includeVars=true`. **Historical Timeline, Top Forecast
> Keys, Top Scenarios and Settings & Data Quality NOT started.** Overview, Forecast, Performance, Shape,
> Stability, Volatility **untouched**; datasource, nginx, Docker, CSVs, Python, Power BI V1, weights,
> thresholds, alerts, plugins, token, DPAPI, MCP all **unchanged**; dashboard JSON secret-scanned clean;
> **no manual commit**. Agent browser session is unauthenticated → **live render awaits Oscar's
> confirmation** (`engineering/E7_grafana/E7D7_events_visual_validation.md`). Deliverables:
> `engineering/E7_grafana/E7D7_events_*` (6 docs) + rebuilt
> `V2/grafana/dashboards/aegis-forecast-drift-events.json` + shell archive +
> `V2/scripts/push-e7d7-events.ps1`. **Open risk R1** unchanged. Token
> **E7D7_EVENTS_MVP_REPAIRED_PENDING_VISUAL_ACCEPTANCE**. **Stop before E7D.8.**
> URL `http://localhost:3000/d/aegis-forecast-drift-events`.

**E7D.6 — Volatility MVP (analytical panels): COMPLETED — VISUALLY ACCEPTED (Oscar, 2026-07-19).**
> Built the **Volatility** section (uid `aegis-forecast-drift-volatility` **retained**) from the E7D.0 structural
> shell into a full governed analytical dashboard for the volatility drift family (governed weight **10%**).
> **Deliberately NOT a mechanical clone of Stability/Shape** — Volatility is only **partially computable**:
> **13 panels** — **A** Average Volatility Drift Score (**56.04**, bands 20/40/70); **B** Volatility Signals
> Computable (**144**); **D** Volatility Coverage (**85.7 %** = 144 ÷ 168); **E** Maximum Volatility Drift Score
> (**100.00**); **F** Volatility Drift Score over time (**12** `forecast_version` points, UTC — **ignores the
> Forecast Version filter**, axis starts **2024-06-01**; peak **78.13** @ 2026-01-01); **G** Volatility Drift
> Score by Forecast Key (**horizontal barchart**, NAM-SDF **82.21** top); **H** Volatility Signal Details
> (per-signal, score desc, Computable Yes/No, full width, shows non-computable rows); **I** Volatility Profile —
> Governed Auxiliary Metrics (from `forecast_drift_family_scores.csv`: `rolling_stddev/cov/mad`,
> `oscillation_count`, `sign_change_freq`, `volatility_class`; 144 rows); **J** Non-computable Summary
> (**INSUFFICIENT_VERSIONS = 24**); **K** Latest Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71);
> **L** Data Quality 18/18. **No value is hardcoded** — every KPI reduces the datasource live. **Scope decisions
> justified by the data:** the **24 non-computable** signals are exactly the first two versions of each of the 12
> keys (`2024-04-01`, `2024-05-01`), governed by `not_computable_reason = INSUFFICIENT_VERSIONS` → a
> **Non-computable Summary panel IS built** (unlike Stability/Shape at 168/168); **Coverage is a first-class KPI**
> (85.7 %, denominator = full filtered universe, dynamic); averages/max **exclude** non-computable signals (never
> zeroed); the governed **auxiliary metrics live in family_scores.csv (not signals.csv)** and are surfaced in a
> dedicated **Volatility Profile** table honoring only `forecast_key` + `forecast_version` (family_scores has no
> region/status/run columns — documented two-table exception); a **ranking barchart** (new panel type) answers the
> key-level dispersion question; the trend starts at the **first computable bucket 2024-06-01**. **Reused the
> stable E7D.1–E7D.5 mechanism verbatim** (`queryType`-wrapped variables, `v`-prefixed `fv_label`, quoted
> `run_id`, `convertFieldType` before numeric reducers; note Infinity requires **`==`** for equality in the
> family_scores filters). **Structural validator 0 failures. Reconciliation 0 discrepancies** (4 KPI + 12-bucket
> trend + key ranking + aux 144 + non-computable 24 + 8 filter scenarios, incl. the decisive non-computable
> Published **only** the Volatility
> dashboard via `V2/scripts/push-e7d6-volatility.ps1` (token **DPAPI-decrypted in memory only**, never printed) →
> **v3** (post-acceptance polish), `success`, `inFolder=True`, 13 panels; shell backed up at
> `V2/grafana/dashboards/archive/aegis-forecast-drift-volatility-shell.json`. **Post-acceptance polish (v3):**
> confirmed the trend's saved time range begins at the first real bucket (`from = 2024-06-01`; `linear` +
> `showPoints=always` preserved; query/12 buckets unchanged — the "2021" gap was a client-side time override, not
> in the model); and set the Volatility Profile `rolling_stddev` (raw 221.6 → 1,270,234, no governed unit) to an
> explicit **`locale`** unit (full thousands-grouped integer) instead of the ambiguous `short` K/Mil — no data
> recalculated; KPIs re-verified unchanged. **Shared navigation-contract fix (v4):** the **AEGIS Sections**
> dropdown (`dashboard.links`, tag `aegis-nav`) had `keepTime: true` → it carried the previous dashboard's **live**
> time range into the target (the real cause of the "from 2021" trend when navigating in via AEGIS nav). Set
> `keepTime: false` (target loads its **own** saved range) + `includeVars: true` (preserve the 5 global filters)
> and republished this to **all 11 dashboards** (foundation, forecast, performance, shape, stability, volatility,
> events, timeline, top-keys, top-scenarios, settings) — **only the `links` block changed** (no queries, data,
> panels, filters, thresholds or time ranges). **Overview, Forecast, Performance, Shape, Stability and the other 5
> dashboards otherwise untouched** (nav `links` block only); datasource, nginx, Docker, CSVs, Python, Power BI V1,
> weights, thresholds, alerts, plugins, token, DPAPI, MCP all **unchanged**; repo secret-free; **no manual
> commit**. The agent browser session is unauthenticated, so the **live render awaits Oscar's confirmation**
> (`engineering/E7_grafana/E7D6_volatility_visual_validation.md`). Deliverables:
> `engineering/E7_grafana/E7D6_volatility_*` (5 docs) + rebuilt
> `V2/grafana/dashboards/aegis-forecast-drift-volatility.json` + shell archive +
> `V2/scripts/push-e7d6-volatility.ps1`. **Open risk R1** unchanged. Token
> **E7D6_VOLATILITY_MVP_COMPLETED_VISUALLY_ACCEPTED**. **Stop before E7D.7 (Events).**
> URL `http://localhost:3000/d/aegis-forecast-drift-volatility`.

**E7D.5 — Stability MVP (analytical panels): COMPLETED — VISUALLY ACCEPTED (2026-07-19).**
> Built the **Stability** section (uid `aegis-forecast-drift-stability` **retained**) from the E7D.0 structural
> shell into a full governed analytical dashboard for the stability drift family (governed weight **30%**) by
> **cloning the visually-accepted Shape (E7D.4) structure** and swapping the governed metric to
> `stability_drift_score`: **8 analytical components / 10 panels** — **A** Average Stability Drift Score
> (**38.93**, bands 20/40/70); **B** Stability Signals Computable (**168**); **C** Stability Coverage
> (**100.0 %** = 168 ÷ 168, green ≥ 0.9); **D** Maximum Stability Drift Score (**100.00**); **E** Stability Drift
> Score over time (14 `forecast_version` points, UTC — **ignores the Forecast Version filter**; peak **74.14** @
> 2025-12-01, secondary **56.47** @ 2026-04-06 / **55.36** @ 2026-03-07, low **16.08** @ 2026-04-16); **F**
> Stability Signal Details (per-signal, score desc, Computable Yes/No, full width); **H** Latest Governed Run
> (1 · Success · 2026-07-13 22:44 UTC · 168 · 71); **I** Data Quality 18/18. **No value is hardcoded** — every
> KPI reduces the datasource live. **Scope decisions justified by the data:** Stability is **168/168 computable
> (0 non-computable)** so the **Non-computable Summary panel is intentionally omitted** (Details widened to full
> width); the governed snapshot exposes a **single** stability metric (`stability_drift_score`) with **no**
> auxiliary/MAPE-equivalent, so the 4th KPI slot is **Maximum Stability Drift Score** and the Details table
> carries no Current/Previous columns. The richer stability auxiliaries in `forecast_drift_family_scores.csv`
> (`structural_break_flag`, `cumulative_revision_pct`, `version_count`) are **populated but intentionally not
> integrated** into this single-source MVP — recorded as a future enhancement. **Reused the stable
> E7D.1–E7D.4 mechanism verbatim** (`queryType`-wrapped variables, `v`-prefixed `fv_label`, quoted `run_id`, no
> aliasing of filtered columns, transform aggregation; boolean fix `convertFieldType is_comp → number` before
> `mean` on Coverage); the accepted Shape v3 polish (time range from **2024-04-01**, trend `lineInterpolation`
> **linear**, points visible) was applied from the start. **Structural validator 0 real failures.**
> **Reconciliation all-matched, 0 discrepancies** (4 KPI + 14-bucket trend + 6 filter scenarios:
> All→168/38.93/100 %, NAM-SDF→14/54.78, region NAM→42/50.71, Critical→14/95.35, v2025-12-01→12/74.14, missing
> key→0/empty). Published **only** the Stability dashboard via `V2/scripts/push-e7d5-stability.ps1` (token
> **DPAPI-decrypted in memory only**, never printed) → **v2**, `success`, `inFolder=True`, 10 panels; shell
> backed up at `V2/grafana/dashboards/archive/aegis-forecast-drift-stability-shell.json`. **Overview, Forecast,
> Performance, Shape and the other 6 dashboards untouched**; datasource, nginx, Docker, CSVs, Python, Power BI
> V1, weights, thresholds, alerts, plugins, token, DPAPI, MCP all **unchanged**; repo secret-free; **no manual
> commit**. The agent browser session is unauthenticated, so the **live render awaits Oscar's confirmation**
> (`engineering/E7_grafana/E7D5_stability_visual_validation.md`). Deliverables:
> `engineering/E7_grafana/E7D5_stability_*` (5 docs) + rebuilt
> `V2/grafana/dashboards/aegis-forecast-drift-stability.json` + shell archive +
> `V2/scripts/push-e7d5-stability.ps1`. **Open risk R1** unchanged. **Oscar visually accepted on 2026-07-19**
> (metrics, trend, details table and governance). Token **E7D5_STABILITY_MVP_COMPLETED_VISUALLY_ACCEPTED**.
> URL `http://localhost:3000/d/aegis-forecast-drift-stability`.

**E7D.4 — Shape MVP (analytical panels): COMPLETED — VISUALLY ACCEPTED (2026-07-19).**
> Rebuilt the **Shape** section (uid `aegis-forecast-drift-shape` **retained**) from the E7D.0 structural shell
> into a full governed analytical dashboard for the shape drift family (governed weight **40%**): **8 analytical
> components / 10 panels** — **A** Average Shape Drift Score (**26.03**, bands 20/40/70); **B** Shape Signals
> Computable (**168**); **C** Shape Coverage (**100.0 %** = 168 ÷ 168, green ≥ 0.9); **D** Maximum Shape Drift
> Score (**100.00**); **E** Shape Drift Score over time (14 `forecast_version` points, UTC — **ignores the
> Forecast Version filter**; peak **62.60** @ 2025-12-01, secondary **44.08** @ 2026-03-07, low **9.59** @
> 2026-04-16); **F** Shape Signal Details (per-signal, score desc, Computable Yes/No, full width); **H** Latest
> Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71); **I** Data Quality 18/18. **No value is
> hardcoded** — every KPI reduces the datasource live. **Scope decisions justified by the data:** Shape is
> **168/168 computable (0 non-computable)** so the **Non-computable Summary panel is intentionally omitted** (no
> empty panel; Details widened to full width); the governed snapshot exposes a **single** shape metric
> (`shape_drift_score`) with **no** auxiliary/MAPE-equivalent, so the 4th KPI slot is **Maximum Shape Drift
> Score** instead of an aux-metric KPI, and the Details table carries no Current/Previous auxiliary columns.
> **Reused the stable E7D.1/E7D.2/E7D.3 mechanism verbatim** (`queryType`-wrapped variables, `v`-prefixed
> `fv_label`, quoted `run_id`, no aliasing of filtered columns, transform aggregation; the E7D.3 boolean fix —
> `convertFieldType is_comp → number` before `mean` — applied to Coverage); Run + Data Quality cloned 1:1.
> **Structural validator 0 failures.** **Reconciliation all-matched, 0 discrepancies** (4 KPI + 14-bucket trend +
> 6 filter scenarios: All→168/26.03/100 %, NAM-SDF→14/42.22, region NAM→42/36.50, Critical→14/89.45,
> v2025-12-01→12/62.60, missing key→0/empty). Published **only** the Shape dashboard via
> `V2/scripts/push-e7d4-shape.ps1` (token **DPAPI-decrypted in memory only**, never printed) → **v2**, `success`,
> `inFolder=True`, 10 panels; shell backed up at
> `V2/grafana/dashboards/archive/aegis-forecast-drift-shape-shell.json`. **Overview, Forecast, Performance and
> the other 7 dashboards untouched**; datasource, nginx, Docker, CSVs, Python, Power BI V1, weights, thresholds,
> alerts, plugins, token, DPAPI, MCP all **unchanged**; repo secret-free; **no manual commit**. The agent browser
> session is unauthenticated, so the **live render awaits Oscar's confirmation**
> (`engineering/E7_grafana/E7D4_shape_visual_validation.md`). Deliverables:
> `engineering/E7_grafana/E7D4_shape_*` (5 docs) + rebuilt
> `V2/grafana/dashboards/aegis-forecast-drift-shape.json` + shell archive + `V2/scripts/push-e7d4-shape.ps1`.
> **Oscar visually accepted on 2026-07-19** (metrics, details table and governance). A minor post-acceptance
> polish (v3) was applied to the trend panel only — time range starts at the first real data (**2024-04-01**,
> removing the empty pre-2024 space) and `lineInterpolation` **smooth → linear** with real per-version points
> kept visible; no query / metric / filter / KPI / table / other-dashboard change; KPIs re-verified intact
> (26.03 / 168 / 100.0 % / 100.00 / DQ 18/18). **Do not start E7D.5 (Stability).** **Open risk R1** unchanged.
> Token **E7D4_SHAPE_MVP_COMPLETED_VISUALLY_ACCEPTED**.
> URL `http://localhost:3000/d/aegis-forecast-drift-shape`.

**E7D.3 — Performance MVP (analytical panels): COMPLETED — VISUALLY ACCEPTED (2026-07-19).**
> Transformed the **Performance** section (uid `aegis-forecast-drift-performance` **retained**) from the E7D.0
> structural shell (3 text panels) into a full governed analytical dashboard for the performance drift family
> (governed weight **20%**): **9 analytical components / 11 panels** — **A** Average Performance Drift Score
> (**7.71**, severity bands 20/40/70); **B** Performance Signals Computable (**156**); **C** Average MAPE Change
> (**0.81 %**, `MAPE_deep` rows, percent unit); **D** Performance Coverage (**92.9 %** = 156 ÷ 168, green ≥ 0.9);
> **E** Performance Drift Score over time (13 `forecast_version` points, thresholds 20/40/70, UTC — **ignores the
> Forecast Version filter**; peaks **38.19** @ 2025-06-01 and **23.19** @ 2026-03-07); **F** Performance Signal
> Details (per-signal, sorted by score desc, Computable Yes/No, severity status); **G** Non-computable
> Performance Summary (**NO_REALIZED_OVERLAP 12**, from family scores); **H** Latest Governed Run (1 · Success ·
> 2026-07-13 22:44 UTC · 168 · 71); **I** Data Quality 18/18. **No value is hardcoded** — every KPI reduces the
> datasource live. **Computability predicate solved**: `performance_drift_score` is empty for non-computable
> rows and Infinity coerces empty cells unreliably (numeric `>= 0` → HTTP 400 / truthy-empty; ternary computed
> columns unsupported), so the score is selected as **string** and filtered with `performance_drift_score != ''`
> (156 rows), converted to number via `convertFieldType` for the mean/trend, with a **boolean computed flag**
> for coverage. **Reused the stable E7D.1/E7D.2 mechanism verbatim** (`queryType`-wrapped variables, `v`-prefixed
> `fv_label`, quoted `run_id`, no aliasing of filtered columns, transform aggregation); Run + Data Quality
> panels cloned 1:1 from Forecast. **Reconciliation all-matched, 0 mismatches** (4 KPI + 4 consistency +
> 13-bucket trend + details spot-check + 7 filter scenarios: All→156/7.71, NAM-MSIT→13/18.39, region NAM→39,
> v2025-06-01→12/38.19, Critical→14/30.03, missing key→0); pre-publish structural validator **0 failures**.
> Published **only** the Performance dashboard via `V2/scripts/push-e7d3-performance.ps1` (token **DPAPI-decrypted
> in memory only**, never printed) → **v2**, `success`, `inFolder=True`, 11 panels; shell backed up at
> `V2/grafana/dashboards/archive/aegis-forecast-drift-performance-shell.json`. **Oscar's v2 visual review found
> one defect** (all other panels confirmed working): **Performance Coverage rendered completely empty**. **Root
> cause:** coverage reduces the computed flag `is_comp` (`performance_drift_score != ''`) with `mean`, but
> despite `type:"number"` Infinity returns `is_comp` as a **boolean** field (`is_comp : boolean`, `True/False`),
> and `mean` over a boolean yields no value → empty. **Fix (v3):** added a single `convertFieldType is_comp →
> number` transform to that panel (True→1/False→0) before the `mean` reducer — no layout/query/filter/unit change
> — giving 156÷168 = **92.9 %**. **Denominator confirmed dynamic, not hardcoded** (headless boolean→number→mean:
> All 168/156→92.9 %, Forecast Key NAM-MSIT 14/13→92.9 %, Region NAM 42/39→92.9 %, Version v2025-06-01
> 12/12→100 %, back to All 168/156→92.9 %). Republished **only** Performance → **v3**, `success`, `inFolder=True`,
> 11 panels. **Overview, Forecast and the other
> 8 dashboards untouched**; datasource `aegis-forecast-drift-csv`, nginx, Docker, CSVs, Python, Power BI V1,
> weights, thresholds, alerts, plugins, token, DPAPI, MCP all **unchanged**; repo secret-free; **no manual
> commit** (R1 auto-commit untouched). **Documented data limitations**: only `MAPE_deep` rows expose
> Current/Previous MAPE in the details table (blank elsewhere by design); the Non-computable Summary honors only
> Forecast Key + Forecast Version (family scores lack region/status/run_id). The agent browser session is
> unauthenticated, so the **live render awaits Oscar's confirmation**
> (`engineering/E7_grafana/E7D3_performance_visual_validation.md`). Deliverables:
> `engineering/E7_grafana/E7D3_performance_*` (5 docs) + rebuilt
> `V2/grafana/dashboards/aegis-forecast-drift-performance.json` + shell archive +
> `V2/scripts/push-e7d3-performance.ps1`. **Do not start E7D.4.** **Open risk R1** unchanged.
> **Oscar visually accepted v3 on 2026-07-19** (Performance Coverage 92.9 %; all other components working).
> Token **E7D3_PERFORMANCE_MVP_COMPLETED_VISUALLY_ACCEPTED**.
> URL `http://localhost:3000/d/aegis-forecast-drift-performance`.

**E7D.2 — Forecast MVP (analytical panels): COMPLETED — VISUALLY ACCEPTED (2026-07-19).**
> Oscar's first visual review of **v2** found **two mandatory defects** (all other panels confirmed working):
> (1) **Drift Status Distribution** colored slices **by position** (`palette-classic` ignored the value
> mappings) — **fixed** with explicit per-value `byName` overrides (Healthy→green / Watch→yellow / Warning→
> orange / Critical→red, `color.mode:fixed`), so color is bound to value/series not position; (2) the **Drift
> Score Heatmap rendered empty** (only the Forecast Key column) — **root cause:** the 14-target Infinity pivot
> fired 14 GETs to one URL, Infinity **coalesced responses per URL** so only target A returned data and the
> join left just `forecast_key`. **Fixed** by rebuilding the heatmap as a **single Infinity query** pivoted by
> the native **`groupingToMatrix`** transform (`sortBy fv_label` → `groupingToMatrix` → `organize`) — one
> query = no coalescing = stable 12×14 matrix that also now **honors the shared filters**. Republished **v3**.
> Source-data gate re-confirmed (single query 168 rows / 12 keys / 14 versions; APC-MULTITENANT v2024-04-01 =
> 25.6). **Oscar's second visual review (2026-07-19) confirmed both repairs** — the status donut shows the
> correct severity colors and the heatmap renders all 12 keys × 14 versions with values and colored
> backgrounds; all other panels (filters, trend, gauge, ranking, Latest Run, Data Quality) render correctly.
> Token **E7D2_FORECAST_MVP_COMPLETED_VISUALLY_ACCEPTED**.

**E7D.2 — Forecast MVP — build detail (published v3, 2026-07-19):**
> Transformed the **Forecast** section (uid `aegis-forecast-drift-forecast` **retained**) from the E7D.0
> structural shell (3 text panels) into a full governed analytical dashboard: **8 components / 10 panels** —
> **A** Overall Forecast Drift Score gauge (mean **28.8**, severity bands 0/20/40/70); **B** Drift Family
> Distribution donut (Stability 88 · Volatility 45 · Shape 27 · Performance 8, **neutral** colors); **C**
> Drift Status Distribution donut (Healthy 82 · Watch 38 · Warning 34 · Critical 14, **severity** colors);
> **D** Avg Drift Score over time (14 `forecast_version` points, thresholds 20/40/70, UTC — **ignores the
> Forecast Version filter** to preserve full history); **E** Forecast Keys by avg drift score (12 keys, desc,
> **NAM-SDF 42.74** top, neutral); **F** **Drift Score Heatmap** (12 keys × 14 versions, one governed score
> per cell, severity background — a single-query pivot via the native `groupingToMatrix` transform, replacing
> the unstable 14-target join, since Grafana has no native categorical pivot); **G** Latest Governed Run (1 · Success · 2026-07-13 22:44
> UTC · 168 · 71); **H** Data Quality 18/18. **Reused the stable E7D.1 mechanism verbatim** (`queryType`-
> wrapped variables, `v`-prefixed `fv_label` filter, quoted `run_id`, no aliasing of filtered columns,
> transform-based aggregation). **Reconciliation 18/18** (8 panel metrics + 4 consistency + 6 filter
> scenarios: All→168, Critical→14, NAM-SDF→14, NAM→42, v2025-12-01→12 mean 53.3); pre-publish structural
> validator **0 failures**; single-query heatmap source gate **168 rows / 12 keys / 14 versions**. Published
> **only** the Forecast dashboard via `V2/scripts/push-e7d2-forecast.ps1` (token **DPAPI-decrypted in memory
> only**, never printed) → **v3** (v2 was the initial build, repaired per Oscar's review above), `success`,
> `inFolder=True`, 10 panels. Shell backed up at
> `V2/grafana/dashboards/archive/aegis-forecast-drift-forecast-shell.json`. **Overview and the other 9
> dashboards untouched**; datasource `aegis-forecast-drift-csv`, nginx, Docker, CSVs, Python, Power BI V1,
> weights, thresholds, alerts, plugins, token, DPAPI, MCP all **unchanged**; repo secret-free; **no manual
> commit (R1 auto-commit untouched). Token **E7D2_FORECAST_MVP_COMPLETED_VISUALLY_ACCEPTED**;
> visually accepted by Oscar 2026-07-19 (`engineering/E7_grafana/E7D2_forecast_visual_validation.md`).
> Deliverables: `engineering/E7_grafana/E7D2_forecast_*` (6 docs) + rebuilt
> `V2/grafana/dashboards/aegis-forecast-drift-forecast.json` + shell archive +
> `V2/scripts/push-e7d2-forecast.ps1`. Do **not** start E7D.3. **Open risk R1** unchanged.
> URL `http://localhost:3000/d/aegis-forecast-drift-forecast`.

**E7D.1 — Overview MVP (analytical panels): COMPLETED — VISUALLY ACCEPTED (2026-07-19).**
> The first published build (**v3**) rendered **"No data" on every panel** inside Grafana (empty filters)
> even though external `/api/ds/query` tests passed. **Root cause (two defects):** (1) the 5 template
> variables were stored as **flat Infinity queries without the `queryType:"infinity"` wrapper**, so the
> plugin treated them as legacy → empty dropdowns → `${var:singlequote}` → `region IN ()` → backend error on
> every panel; (2) panels 23/24 **aliased a filtered column** (`Forecast Key`/`Run ID`), which the backend
> filter could not resolve (`No parameter 'forecast_key'/'calculation_run_id' found`). **Both fixed** (variable
> wrapper restored; filtered columns' `text`==selector with display headers moved to rename/`displayName`)
> and republished as **v5**. A **second defect** then surfaced: the `forecast_version` variable alone showed a
> red error triangle because Grafana's frontend infers its **ISO-date** option values as a `time` field,
> emptying that variable → `forecast_version IN ()` → all signal panels "No data" again. **Fixed (v6)** by
> filtering on a non-date **`v`-prefixed label** (`fv_label = 'v' + forecast_version`) across the variable and
> 10 signal panels (the trend panel keeps `forecast_version:timestamp` for its X-axis and drops the version
> clause). Broken JSON archived at
> `V2/grafana/dashboards/archive/aegis-forecast-drift-foundation-e7d1-broken.json`. Post-repair **end-to-end
> per-panel replay of the published targets (All-expanded interpolation): 13/13 filter panels PASS, 0 FAIL.**
> Oscar **visually confirmed** the data and numbers, then requested a final **visual polish (v7)** — donut
> severity colors (Healthy green / Watch yellow / Warning orange / Critical red), a 2024-anchored time axis
> (`2024-03-01 → 2026-06-01`, removing the empty 2022 gap), a slimmer nav/header (`h:3→h:2`, no content or
> links removed, panels reflowed), and a corrected filter-semantics note (KPIs/distribution/families/ranking
> honor all five filters; the **trend intentionally ignores Forecast Version** to preserve full history).
> Polish re-validated **13/13 PASS**, data still visible; **Oscar formally accepted**. Do **not** start E7D.2
> until authorized.

Transformed the **Overview** (uid `aegis-forecast-drift-foundation` **retained**) from the E7C/E7D.0
foundation-preview into a complete **governed analytical dashboard** — **7 components / 15 panels** — adapting
the Power BI V1 Overview logic to Grafana + the read-only governed V2 CSV snapshot (**the dashboard does not
cook data**). Components: **A** KPI row (Total Signals **168** · Total Events **71** · Avg Drift **28.8** ·
Critical **14** · Warning **34** · Watch **38** · Healthy **82**); **B** Drift Status donut (82/38/34/14,
severity palette); **C** Avg Drift Score over time (14 `forecast_version` points, dashed thresholds 20/40/70,
UTC); **D** Signals by dominant family (Stability 88 · Volatility 45 · Shape 27 · Performance 8, **neutral**
color); **E** Forecast Keys by drift risk (12 keys, avg desc — **NAM-SDF 42.74** top — with band-colored
Max Drift Status); **F** Latest Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71); **G** Data
Quality **18 / 18**. All **5 shared filters** bound via a single `filterExpression` (backend parser); the
Infinity date-arithmetic bug **and** the frontend ISO-date variable time-inference were **fixed** by
filtering `forecast_version` through a non-date **`v`-prefixed label** (`fv_label`) and quoting `run_id`
(no Overview question left unanswerable by a CSV limitation). **Analytical reconciliation 21/21, 0
mismatches** via read-only `/api/ds/query`; severity KPIs and family counts each sum to 168. Published via
`V2/scripts/push-e7d1-overview.ps1` (service-account token **DPAPI-decrypted in memory only**, never
printed): Overview → **v7** (repaired ×2, polished ×1), `status=success`, `inFolder=True`, 15 panels. Foreign `advs2xz`
**untouched**; datasource `aegis-forecast-drift-csv`, nginx, Docker, CSVs, Python, Power BI V1, weights,
thresholds **unchanged**; no alerts/plugins; no dashboard deleted; **the other 10 dashboards were not
touched**; **no manual commit**; MCP/token/DPAPI unchanged; repo secret-free. Token:
**E7D1_OVERVIEW_MVP_COMPLETED_VISUALLY_ACCEPTED**. Deliverables: `engineering/E7_grafana/E7D1_*`
(5 docs) + updated `V2/grafana/dashboards/aegis-forecast-drift-foundation.json` + broken-build archive +
`V2/scripts/push-e7d1-overview.ps1`. **Open risk R1** unchanged.
URL `http://localhost:3000/d/aegis-forecast-drift-foundation`.
Next: **E7D.2** — **awaiting visual review + explicit authorization**.

**E7D.0 — Dashboard Information Architecture & Shared Navigation: COMPLETE (2026-07-19).**
Materialized the **product backbone** in Grafana: **11 dashboards** in folder **`AEGIS Forecast Drift`**
(uid `afsjccp27s0e8d`), all sharing one navigation contract, one shared-filter contract and one visual
design system. **Overview** = the E7C dashboard retitled to **`AEGIS Forecast Drift — Overview`**
(uid `aegis-forecast-drift-foundation` **retained** — the proposed `aegis-forecast-drift-overview` was
**not** adopted because a safe UID change requires deleting the existing dashboard, which is prohibited),
keeping its E7C functional panels, now with the shared nav bar, the corrected **`Forecast Key`** label and
the new **`forecast_version`** variable (14 values). **10 structural shells** created (Forecast, Performance,
Shape, Stability, Volatility, Events, Historical Timeline, **Top Forecast Keys** [replaces mockup *Top
Services* — `service` empty], **Top Scenarios** [single `Enterprise`], Settings & Data Quality) — each with
shared navigation + applicable shared filters + a purpose/roadmap text panel; **no analytical panels**.
Shared filters (data-driven, no empties): region 9 / forecast_key 12 / forecast_version 14 / drift_status 4 /
run_id 1. Published via `V2/scripts/push-e7d0-structure.ps1` (service-account token DPAPI-decrypted **in
memory only**, never printed): Overview → **v2**, 10 shells → **v1**, all `status=success`, all `inFolder=True`.
Foreign dashboard `advs2xz` **untouched**; datasource `aegis-forecast-drift-csv` **unchanged**; MCP
`✓ Connected`; token-literal repo scan **CLEAN**. **No E7D.1**, no alerts, no threshold/weight/data change;
token not revoked; DPAPI not deleted; MCP not unregistered; no dashboard deleted; **no manual commit**.
Token: **E7D0_INFORMATION_ARCHITECTURE_COMPLETED**. Deliverables: `engineering/E7_grafana/E7D0_*` (8 docs)
+ 11 governed JSON exports in `V2/grafana/dashboards/`. **Open risk R1** unchanged.
Next: **E7D.1 — Overview MVP** — **awaiting visual review + explicit authorization**.

**E7C — Grafana Dashboard Foundation Preview: COMPLETE (2026-07-18).** Built the visual/technical
foundation of the AEGIS Forecast Drift dashboard **via MCP** (consume-only). Created folder
**`AEGIS Forecast Drift`** (uid `afsjccp27s0e8d`) and dashboard **`AEGIS Forecast Drift`**
(uid `aegis-forecast-drift-foundation`, version 1) inside it: a **header** + **4 Infinity query
variables** (`forecast_key` 12 / `region` 9 / `drift_status` 4 / `run_id` 1 — all data-derived,
All option, multi) + **4 preview panels** — A Latest Governed Run (runs.csv), B Total Drift
Signals (**168**), C Drift Status Distribution (Healthy 82 / Watch 38 / Warning 34 / Critical 14),
D Top 10 by `forecast_drift_score`. Datasource `aegis-forecast-drift-csv` health **OK**;
read-only `/api/ds/query` per-panel rows **1/168/168/168** (no No-data). Pre-existing dashboard
`advs2xz` **inspected and untouched**. Governed export
`V2/grafana/dashboards/aegis-forecast-drift-foundation.json` (secret-free, datasource by UID).
Severity palette reserved (Healthy=green/Watch=yellow/Warning=orange/Critical=red). **Foundation
preview only** — no E7D, no full panel set, no alerts, no threshold/weight/data change; token
**not revoked**, DPAPI **not deleted**, MCP **not unregistered**, V1 untouched, **no manual commit**.
Precheck PASS: Grafana running, aegis-csv healthy, MCP `✓ Connected`, DPAPI present+decryptable,
`HEAD==origin/main==4b7c6cc` (auto-commit still only holds E7B.2; E7B.3/4/5 + E7C uncommitted).
Token: **E7C_DASHBOARD_FOUNDATION_PREVIEW_COMPLETED**. Deliverables:
`engineering/E7_grafana/E7C_*` (4 docs) + governed dashboard JSON. **Open risk R1** unchanged.
URL: `http://localhost:3000/d/aegis-forecast-drift-foundation/aegis-forecast-drift`.
Next: **E7D — Grafana Dashboard MVP** — **awaiting visual review + explicit authorization**.

**E7B.5 — MCP Connection Closure (Operational Readiness): COMPLETE (2026-07-18).**
Executed as a **NON-DESTRUCTIVE** closure (scope corrected): the token and MCP connection
**remain active** because E7C/E7D still need them. E7B.5 did **not** revoke the token, delete
the DPAPI secret, run `remove-grafana-mcp-token.ps1`, run `claude mcp remove grafana`, or
unregister the MCP. Readiness re-verified: MCP `grafana` **`✓ Connected`** (local, stdio,
`Environment: empty`); datasource **`aegis-forecast-drift-csv`** visible via `list_datasources`
(2 clean JSON lines); **no secrets** in repo (REPO_SCAN=CLEAN), Claude config (no token
prefix), or git tree (0 tracked secret files); DPAPI secret present outside repo; token **expires
2026-09-01**; **definitive revocation deferred to E7D close**. Grafana container running;
**no dashboards created; E7C not started.** Git integrity: `HEAD==origin/main==4b7c6cc`;
last auto-commit `4b7c6cc "add"` (E7B.2 deliverables). Token:
**E7B5_MCP_OPERATIONAL_READINESS_COMPLETED**. Deliverable:
`engineering/E7_grafana/E7B5_operational_readiness.md`. **Open risk R1:** external
auto-commit/push to `origin/main` — watch, do not modify. **No blockers for E7C.**
Next: **E7C — Dashboard Foundation** — **awaiting explicit authorization**.

**E7B.4 — Register MCP in Claude Code + Connectivity Smoke Test: COMPLETE (2026-07-18).**
Registered the official `mcp-grafana` v0.17.2 server in **Claude Code** as stdio server
**`grafana`**, **local scope** (`~/.claude.json`, outside repo, not committed), command =
the secure wrapper `V2/scripts/start-mcp-grafana.ps1` (**`Environment: empty`** — no token
in config; the wrapper decrypts the DPAPI token in memory). Hardened the wrapper so
**stdout carries only MCP JSON-RPC** and all diagnostics go to stderr. **Standalone MCP
smoke test** (`initialize` + `list_datasources`) returned clean JSON including
`aegis-forecast-drift-csv`; `claude mcp list`/`get grafana` report **`✓ Connected`**.
**No dashboards/folders created; no writes; E7C not started.** Token stays DPAPI-encrypted
outside repo; **expires 2026-09-01; revoke at E7D close**. Integrity unchanged: Grafana &
aegis-csv healthy; V2 168/672/71/1; V1 intact. Pre-registration post-auto-commit check:
`HEAD==origin/main==4b7c6cc`, no secret tracked/physical in repo. Token:
**E7B4_MCP_REGISTRATION_SMOKE_COMPLETED**. Deliverables: `engineering/E7_grafana/E7B4_*`
(5 docs) + hardened `V2/scripts/start-mcp-grafana.ps1`. **Open risk R1:** external
auto-commit/push to `origin/main` (last `4b7c6cc`, no secrets) — watch, do not modify.
**No blockers for E7B.5.** Next: **E7B.5 — MCP connection closure (revoke token, security
validation)** — **awaiting explicit authorization**.

**E7B.3 — Grafana Service Account & Secure Token: COMPLETE (2026-07-18).** Created the
dedicated Grafana service account **`aegis-mcp`** (login `sa-1-aegis-mcp`, org role
**Editor**, **not** admin) and a short-lived token with explicit expiration. **Verified**
that `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` **is** supported in v0.17.2 (binary strings +
README @ tag) but **rejected** it (plaintext at rest); instead the token is stored
**encrypted with Windows DPAPI (CurrentUser)** at `%LOCALAPPDATA%\AEGIS\secrets\grafana\`
(**outside the repo**) and decrypted **only in process memory** by the launch wrapper,
which sets `GRAFANA_SERVICE_ACCOUNT_TOKEN` process-scoped and restricts MCP tools to
`search,datasource,dashboard,folder`. Created four ASCII, **secret-free** scripts in
`V2/scripts/` (`store-`, `start-`, `verify-`, `remove-grafana-mcp-token.ps1`). User
created the account+token and stored it (`TOKEN_STORED=True`). **Authenticated read-only**
validation PASSED: identity `sa-1-aegis-mcp`, Editor permissions (no `users:read`/
`server.admin`), datasource `aegis-forecast-drift-csv` visible — **no writes, no MCP
registration, no dashboards created, token never printed**. Integrity unchanged: Grafana
& aegis-csv healthy; V2 168/672/71/1; V1 intact. Token: **E7B3_SERVICE_ACCOUNT_TOKEN_COMPLETED**.
Deliverables: `engineering/E7_grafana/E7B3_*` (5 docs) + `V2/scripts/*grafana-mcp-token.ps1`.
**Token not revoked** — kept until E7C/E7D complete or expiration. **Open risk R1:** external
auto-commit/push to `origin/main` (fired overnight as `4b7c6cc`, no secrets) — watch, do
not modify. **No blockers for E7B.4.** Next: **E7B.4 — Register MCP in Claude Code +
connectivity smoke test** — **awaiting explicit authorization**.

**E7B.2 — Install Pinned Grafana MCP Server: COMPLETE (2026-07-17).** Installed the
**official** `mcp-grafana` **v0.17.2** binary (windows/amd64) **outside the repo** at
`%LOCALAPPDATA%\AEGIS\mcp-grafana\v0.17.2\`, verified integrity (SHA256 `939eb0f4…eb62616`
matched **both** the release page **and** the official `checksums.txt`), and validated it
runs locally (`--version`=0.17.2; `--help` shows stdio + `--disable-write`/tool flags).
Created reproducible **secret-free** scripts in `V2/scripts/` (`install-mcp-grafana.ps1`
idempotent, `verify-mcp-grafana.ps1` read-only, `mcp-grafana-install-manifest.json`).
**No connection to Grafana; no service account; no token; no Claude Code registration;
no `.mcp.json`.** Binary kept out of the repo so R1 cannot publish it; PATH not modified.
Integrity unchanged: Grafana & aegis-csv healthy; V2 168/672/71/1; V1 intact. Token:
**E7B2_MCP_INSTALLATION_COMPLETED**. Deliverables: `engineering/E7_grafana/E7B2_*` (5 docs)
+ `V2/scripts/*`. **Open risk R1:** external auto-commit/push to `origin/main` — watch,
do not modify (fired as `b60f2b9` on the prior E7B.1 corrections). **No blockers for E7B.3.**
Next: **E7B.3 — Service account `aegis-mcp` + token** — **awaiting explicit authorization**.

**E7B.1 — Grafana MCP Connection Preflight: COMPLETE (2026-07-17).** Documentation-only
stage (no runtime mutation): produced six deliverables + status updates, but **nothing
installed, no service account/token, no MCP config**. Determined
the safe, reproducible way to connect Claude Code to Grafana via the official
`mcp-grafana` server (**v0.17.2**, requires Grafana ≥9.0; we have 13.0.1). **Selected
Architecture A:** native binary on the Windows host, **stdio**,
`GRAFANA_URL=http://localhost:3000`, Claude Code **local scope**, token via
`GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` (git-ignored) — zero impact on `aegis-net`/existing
containers, trivial rollback. Designed least-privilege service account `aegis-mcp`,
secret handling, tool allow-list (`datasource`+`search`/`dashboard` only, `--disable-write`
for reads, write scoped to a single temp smoke dashboard), and the E7B.2–E7B.5 plan.
**Known limitation:** no native Infinity/CSV query tool (CSV read only via Infinity
panel + `run_panel_query`, disabled by default). Integrity unchanged: Grafana & aegis-csv
healthy; V2 168/672/71/1; V1==V2; V1 intact. Token: **E7B1_MCP_PREFLIGHT_COMPLETED**.
Deliverables: `engineering/E7_grafana/E7B1_*` (6 docs). **Open risk R1:** external
auto-commit/push to `origin/main` — watch, do not modify. **No blockers for E7B.2.**
Next: **E7B.2 — Install pinned MCP server** — **awaiting explicit authorization**.

**E7B.0 — Formal Closure of E7A.1 (Infinity Query Gate): COMPLETE (2026-07-17).**
Documentation-and-evidence-only stage (no MCP, no system changes). Formally
registered and closed **E7A.1 — Infinity Functional Query Validation Gate** using
manual evidence from the user's authenticated Grafana session: datasource **Health
check successful**; one Infinity query per dataset (CSV / Backend parser / URL /
Table / GET) returned **168 / 672 / 71 / 1** in the Query Inspector. CSV parsing,
tabular usability, and null/empty tolerance = PASS; explicit per-field Grafana
type hints (Time/Number) **deferred to E7C/E7D** (no auto timestamp→Time claim).
Updated `E7A_validation_results.csv` (V14 DEFERRED→PASS; added V18–V25) and closure
docs. Tokens: E7A.1 = **E7A_INFINITY_QUERY_GATE_COMPLETED**; E7B.0 =
**E7B0_E7A1_FORMAL_CLOSURE_COMPLETED**. Deliverables:
`engineering/E7_grafana/E7A1_infinity_manual_query_evidence.md`,
`engineering/E7_grafana/E7B0_closure_summary.md`. **Open risk R1:** external
auto-commit/push to `origin/main` (commits `add`) still active — detected/reported
only. Next: **E7B.1 — MCP Preflight** — **awaiting explicit authorization**.

**E7A.2 — V2 Governed Data Snapshot & Datasource Rewire: COMPLETE (2026-07-17).**
V2 is now a **self-contained Grafana product**. Created a byte-equivalent,
SHA256-verified governed snapshot of the four V1 datasets (+ metadata +
validation) under `V2/data/processed/`, plus an idempotent sync script
`V2/scripts/sync-governed-data.ps1` (allow-list copy, count + hash validation,
manifest `data_manifest.json`, no secrets). Rewired **only** the `aegis-csv` bind
mount from `V1/data/processed/current/` to `V2/data/processed/current/`
(read-only), keeping container name, `aegis-net`, `http://aegis-csv`, datasource
uid `aegis-forecast-drift-csv`, the Grafana container, volume, and port 3000
unchanged. Restarted only `aegis-csv`. Validated: mount RW=false on V2; 4 CSVs
served (**168 / 672 / 71 / 1**); V1==V2 hashes match; Grafana healthy (13.0.1) and
reaches `http://aegis-csv`; Infinity + datasource intact; `V1/data` clean; no
secrets. Token: E7A2_V2_DATA_SNAPSHOT_COMPLETED. Deliverables in
`engineering/E7_grafana/E7A2_*`. Next: **E7B — MCP connection** — **awaiting explicit
authorization**.

**E7A — Grafana Readiness & Data Source: COMPLETE (2026-07-16).** The existing
local Grafana (Enterprise **13.0.1**, container `grafana`, port 3000, volume
`grafana-storage`) was **preserved** (not recreated). Added a read-only CSV HTTP
server `aegis-csv` (nginx:1.27-alpine) under `V2/`, serving the four governed
CSVs from `V1/data/processed/current/` on an internal `aegis-net` network (no host
port). Installed **Infinity 3.10.1** into Grafana and provisioned datasource
**`AEGIS Forecast Drift CSV`** (uid `aegis-forecast-drift-csv`). Validated: Grafana
healthy; Infinity registered; datasource provisioned; all four CSVs reachable by
DNS with exact counts **168 / 672 / 71 / 1**; `text/csv`; mount read-only; datasets
and secrets untouched; volume backed up outside the repo. Token:
E7A_READINESS_DATASOURCE_COMPLETED. Deliverables in `engineering/E7_grafana/`.
Next: **E7B — MCP connection** (service account + token + `mcp-grafana`) — **awaiting
explicit authorization**; no dashboards, service accounts, or MCP created yet.

**E6 — Power BI MVP (local, consume-only): PARTIAL.** Governed semantic model
`AEGIS_Forecast_Drift` authored via Power BI MCP over `V1/data/processed/current/`:
5 tables, shared `DriftDataFolder` parameter, **4 active relationships** (incl.
Calendar), 24 presentation-only measures (no DAX business logic), exported +
corrected to importable TMDL (`V1/PBI/tmdl/`; re-import validated: 5 tables / 24
measures / 4 rels). Official file `V1/PBI/AEGIS_Forecast_Drift.pbix`. **Real Full
refresh executed in the running Desktop and validated in-model** (DAX):
signals 168 / family 672 / events 71 / runs 1 (Calendar 1096), 24 measures
compile with values identical to Python (status 14/34/38/82, deep, 18/18, True),
4 active relationships. 11 pages + AEGIS sidebar specified. Remaining: **save the
`.pbix`** and author the visual pages + sidebar. Token: E6_POWER_BI_MVP_PARTIAL
(stays PARTIAL until visuals are built). Next: build visuals (V1 Power BI only).

## Stage status
| Stage | Name | Status |
| --- | --- | --- |
| E0 | Foundation (Blueprint, Mockup, Git, Governance) | ✅ Complete |
| E1A | Source Discovery & Data Profiling — Document Discovery & Reuse | ✅ Complete |
| E1B | Source Discovery & Data Profiling — Live Data Validation | ✅ Complete (all 4 families computable) |
| E2 | Forecast Drift Information Model | ✅ Complete |
| E3 | Mathematical Drift Model | ✅ Complete |
| E4 | Output Schema Design | ✅ Complete |
| E5A | Python Drift Engine | ✅ Complete |
| E5B | Production Dataset Validation & Export Hardening | ✅ Complete (offline + live validated) |
| E6 | Power BI MVP (local, consume-only) | ◑ Partial (model + measures + specs + TMDL; .pbix visuals manual) |
| E7 | Grafana MVP (local, consume-only) | ◑ In progress (E7A ✅; E7A.1/E7A.2/E7B.0/E7B.1/E7B.2/E7B.3/E7B.4/E7B.5 ✅; E7C ✅ foundation dashboard `aegis-forecast-drift-foundation` (folder `afsjccp27s0e8d`, data OK); **E7D.0 ✅** product backbone = 11 dashboards (Overview + 10 shells, shared nav/filters/visual system); **E7D.1 ✅** Overview MVP (visually accepted); **E7D.2 ✅** Forecast MVP (visually accepted); **E7D.3 ✅** Performance MVP (visually accepted); **E7D.4 ✅** Shape MVP (visually accepted); **E7D.5 ✅** Stability MVP (visually accepted); **E7D.6 ✅** Volatility MVP (visually accepted); E7D.7–E7D.12 ⏳) |
| E8 | Cloud Deployment & Governance | ⏳ |

## Key validated facts (E1B)
- Source `forecast_substrateBE_hdd_region`: 48 monthly Enterprise ForecastVersions (2021-06 → 2026-05); 177,898 multi-version (Key, target) cells; one model per Key×version.
- Official metrics (`*_metrics`) carry MAPE/Bias/Accuracy but only 3 retained versions.
- Actuals 2019-07 → 2026-05; forecast horizon → 2030-04.

## Open gaps
G1 dedupe FV 2025-06-01 (resolved in E2 design) · G2 shallow metric history · G3 no Service column · G4 region↔forest mapping · G5 scenario scope (MVP=Enterprise) · G6 forward-only rule (resolved in E2 design) · G7 TTL view not probed.

## Deliverables index
- `engineering/ROADMAP.md`
- `engineering/E1_source_discovery_profiling/` — E1A source profiling, data dictionary, open questions, closure; E1B live data validation.
- `engineering/E2_information_model/` — information model, entity catalog, relationship matrix, drift-family input matrix, lineage map, open decisions, closure.

## Governance invariants
AEGIS produces governed drift signals; downstream consumes. Read-only against source; no data mutation; no productive SQL/PBI/Grafana yet. Confidential — no server host/credentials in repo.
