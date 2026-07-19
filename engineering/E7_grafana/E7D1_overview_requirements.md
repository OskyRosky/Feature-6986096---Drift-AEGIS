# E7D.1 — Overview MVP · Requirements & Design

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: **E7D.1 — Overview MVP (analytical panels)** · Date: 2026-07-19
Dashboard: **AEGIS Forecast Drift — Overview** · uid `aegis-forecast-drift-foundation` · folder `AEGIS Forecast Drift` (uid `afsjccp27s0e8d`)

> Scope guard: E7D.1 transforms **only** the Overview (the E7C/E7D.0 foundation-preview) into a complete
> analytical dashboard. The other 10 section dashboards are **not** touched. No datasource, nginx, Docker,
> CSV, Python, Power BI, weight, threshold, alert, plugin, token or MCP change. No dashboard deleted. No
> manual commit. **The dashboard does not cook data** — all logic is computed upstream in the governed V1
> engine and materialized into the read-only V2 CSV snapshot; Grafana only reads, filters and aggregates
> for display.

## 1. Purpose
Give a decision-maker a single governed screen that answers, at a glance, the general state of Forecast
Drift for the current governed snapshot. It adapts the Power BI V1 Overview logic to Grafana + governed V2
data, preserving semantics (families, severity bands, scoring) exactly.

## 2. Questions the Overview must answer
| # | Question | Component |
|---|----------|-----------|
| 1 | How many drift signals / events exist? | A — KPIs (Total Signals, Total Events) |
| 2 | What is the average general drift? | A — KPI (Avg Drift Score) |
| 3 | How many Healthy / Watch / Warning / Critical? | A — severity KPIs + B — donut |
| 4 | How does drift evolve over time? | C — trend (by forecast version) |
| 5 | Which drift families dominate? | D — family bar chart |
| 6 | Which Forecast Keys carry the highest risk? | E — key risk table |
| 7 | What is the latest governed run? | F — Latest Governed Run table |
| 8 | What is the Data Quality state? | G — Data Quality stat |

## 3. Governed model semantics (reused, not redefined)
- **Scoring weights**: Performance 20% · Shape 40% · Stability 30% · Volatility 10%.
- **Severity bands** (on `forecast_drift_score`): Healthy 0–20 · Watch 20–40 · Warning 40–70 · Critical 70+.
- **Severity palette**: Healthy = green · Watch = yellow · Warning = orange · Critical = red.
- **Drift families** (`dominant_drift_family`, lowercase in data): performance · shape · stability · volatility.
- **Event**: a signal with `is_event = 1` (governance-promoted). Events = 71 of 168 signals.
- **Verified invariant**: `drift_status` equals the severity band of `forecast_drift_score` for **all 168**
  rows (0 mismatches). Therefore a key's *max drift status* = the band of its maximum score.

## 4. Data sources (read-only, served by `aegis-csv` nginx)
| Dataset | URL | Rows | Used by |
|---------|-----|------|---------|
| Signals | `http://aegis-csv/forecast_drift_signals.csv` | 168 | A–E |
| Runs | `http://aegis-csv/forecast_drift_runs.csv` | 1 | F, G |
| Family scores | `forecast_drift_family_scores.csv` | 672 | (not required — family read from signals) |
| Event history | `forecast_drift_event_history.csv` | 71 | (not required for Overview) |

## 5. Shared filters (from the E7D.0 shared-filter contract — unchanged set)
Five multi-value template variables, all `All` by default (→ full 168):
`forecast_key` (12) · `forecast_version` (14) · `region` (9) · `drift_status` (4) · `run_id` (1).
Every signal panel binds all five; run/DQ panels bind `run_id`. Behaviour: with all `All`, panels reconcile
to the global totals; narrowing any variable narrows every bound panel consistently.

## 6. Components (Phase 5)
- **A. KPI row** — 7 stat panels: Total Signals, Total Events, Avg Drift Score (colored by band),
  Critical, Warning, Watch, Healthy (severity-colored counts).
- **B. Drift Status Distribution** — donut; `groupBy(drift_status) → count`; severity palette; slices sorted
  by value descending (which is naturally Healthy > Watch > Warning > Critical for this snapshot).
- **C. Average Drift Score Over Time** — timeseries by **forecast version** (chosen time dimension; see §7);
  `groupBy(forecast_version) → mean(score)`; dashed threshold lines at 20 / 40 / 70.
- **D. Signals by Dominant Drift Family** — horizontal bar chart; `groupBy(family) → count`, sorted
  descending; **neutral color** (family is a category, not a severity); labels capitalized for display.
- **E. Forecast Keys by Drift Risk** — table; `groupBy(forecast_key) → mean(score), max(score), count`;
  columns Forecast Key · Avg Drift Score (band-colored) · Max Drift Status (band text+color) · Total Signals;
  sorted by Avg descending.
- **F. Latest Governed Run** — table from runs.csv: Run ID · Status (Success = green) · Finished At (UTC) ·
  Signals Written · Events Created.
- **G. Data Quality — Checks Passed** — stat from runs.csv; computed column
  `checks_passed + ' / ' + checks_total` → "18 / 18"; green; per-check detail deferred to Settings & Data
  Quality (E7D.11).

## 7. Design decisions & rationale
- **Time dimension = `forecast_version`.** `detected_on` is a single constant value (unusable as a trend);
  `target_date` has 30 unevenly-scattered months (noisy). `forecast_version` has 14 clean monthly buckets
  (12 signals each) and is the governed forecast lineage axis → the meaningful drift-evolution axis.
- **Dashboard timezone = UTC.** All timestamps (run finished, forecast version axis) render in UTC to match
  the governed data.
- **"Top Forecast Keys", not "Top Services".** The V1 mockup "Top Services" is not reproducible: the
  `service` column is empty in governed data. The governed equivalent is the **forecast key** (region ×
  workload), so the risk ranking is keyed on `forecast_key` (consistent with the E7D.0 rename).
- **Family bars use a neutral palette** to avoid implying severity; only the status donut/KPIs/bands use the
  severity palette.
- **No server-side aggregation.** The Infinity CSV backend does not aggregate server-side; all rollups use
  Grafana **transformations** (`groupBy`), identical in spirit to the accepted E7C donut.

## 8. Known limitation (documented per spec)
The Infinity CSV **filterExpression** tokenizer parses hyphenated date literals as arithmetic when the
column is typed as string (e.g. `'2024-04-01'` → `2019`), and the Grafana **frontend** additionally infers
ISO-date *variable option values* as a `time` field, which red-triangles the `forecast_version` dropdown and
empties it. **Resolution (Repair #2, v6):** `forecast_version` is filtered through a non-date **`v`-prefixed
label** — a `computed_columns` field `fv_label = 'v' + forecast_version` — in the variable (as `__value`) and
in all 10 signal panels; the filter clause becomes `fv_label IN (${forecast_version:singlequote})`. This
sidesteps both the string date-arithmetic bug and the frontend time-inference. The trend panel keeps
`forecast_version` as a **timestamp** column for its time X-axis (and omits the version clause). Numeric
run-id literals must be quoted strings (`calculation_run_id IN ('1')`). No Overview question is left
unanswerable by a CSV limitation.
