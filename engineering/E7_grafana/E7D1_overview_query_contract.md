# E7D.1 — Overview MVP · Query & Transform Contract

**Dashboard:** AEGIS Forecast Drift — Overview · uid `aegis-forecast-drift-foundation` · schemaVersion 39 · timezone `utc`
**Datasource:** `aegis-forecast-drift-csv` (uid `aegis-forecast-drift-csv`, type `yesoreyeram-infinity-datasource`)
**Parser:** `backend` for every target. **Aggregation:** Grafana transformations only (no server-side rollup).

> All expressions below were validated empirically against the live datasource via read-only
> `/api/ds/query` before publishing (see `E7D1_overview_reconciliation.md`).

## 1. Validated filter mechanism
- Filter fields must be **selected as columns**; the `filterExpression` can only reference selected columns
  (a missing column raises `No parameter 'X' found`).
- Supported operators: `==`, `&&`, `||`, `IN ( … )`, parentheses. Word `AND`/`OR` is **not** supported.
- **CORRECTED:** the expression resolves against the column's **field name after aliasing** — i.e. its
  `text` (or the selector when `text` is empty), **not** the raw selector. Therefore **any column referenced
  in `filterExpression` must have `text` equal to its selector**; aliasing a filtered column to a display
  name breaks the filter (this was the panel 23/24 defect in v3). Use a `displayName` field override or an
  organize/rename transformation for display headers instead of the column `text`.
- **`forecast_version` is filtered via a non-date `v`-prefixed label** (`fv_label = 'v' + forecast_version`,
  added as a `computed_columns` entry). A raw ISO date breaks two ways: a **string** column rejects
  `IN ('2024-04-01')` (parsed as date arithmetic → 0 rows), and the Grafana **frontend** infers ISO-date
  *variable option values* as a `time` field, which throws a red error triangle on the variable and empties
  it. The `v` prefix makes the value a plain non-date string, fixing both. (Repair #2, v6.)
- `run_id` compares as a **quoted string** (`'1'`); numeric `IN (1)` fails.

## 1b. Template variable declaration (CRITICAL — root cause of the v3 render failure)
Each of the 5 template variables must store its Infinity query wrapped with `queryType`, **not** as a flat
`InfinityQuery`:
```jsonc
"query": {
  "queryType": "infinity",
  "refId": "variable",
  "infinityQuery": { "type":"csv", "source":"url", "format":"table", "parser":"backend",
                     "url":"http://aegis-csv/…", "root_selector":"",
                     "columns":[{ "selector":"<field>", "text":"", "type":"string" }], "filters":[] }
}
```
A flat query (missing `queryType`) is treated as **legacy** by the plugin (`migrateLegacyQuery`), returns an
empty result, and leaves the dropdown empty → `${var:singlequote}` interpolates to nothing → `region IN ()`
→ backend error on every dependent panel. `forecast_key`/`forecast_version`/`region`/`drift_status` read
`forecast_drift_signals.csv`; `run_id` reads `forecast_drift_runs.csv` (column `calculation_run_id`).
All variables: `includeAll:true`, `multi:true`, `allValue:null`, `refresh:1`, `sort:1`.

**`forecast_version` exception (Repair #2):** its variable selects `forecast_version` as `string` and adds
`computed_columns:[{ "selector":"'v' + forecast_version", "text":"__value" }]`; the plugin uses the
`__value` field for the option text+value, so the dropdown lists non-date labels `v2024-04-01 …` — which
dodges the frontend ISO-date time-inference that otherwise red-triangles this one variable.

## 2. Shared filter expression (FEXPR) — all five signal filters
```
region IN (${region:singlequote}) && forecast_key IN (${forecast_key:singlequote}) && fv_label IN (${forecast_version:singlequote}) && drift_status IN (${drift_status:singlequote}) && calculation_run_id IN (${run_id:singlequote})
```
Grafana interpolates each multi-value variable via the `:singlequote` format (→ `'v1','v2',…`). With every
variable at `All`, FEXPR selects the full 168 signals. The `forecast_version` clause references the computed
`fv_label` (not the raw column). Run/DQ panels use `calculation_run_id IN (${run_id:singlequote})`.

Signal panels select these filter columns: `region` (string), `forecast_key` (string),
`forecast_version` (**string**, plus the computed `fv_label`), `drift_status` (string),
`calculation_run_id` (string), plus the panel-specific measure/dimension columns. The trend panel (§3C) is
the sole exception — it keeps `forecast_version` as `timestamp` for its X-axis and omits the version clause.

## 3. Panel-by-panel contract

### A. KPI stats (signals.csv)
| Panel id | Title | Extra columns | filterExpression suffix | Reduce | Color |
|---|---|---|---|---|---|
| 10 | Total Signals | `drift_event_id`→`signals` | — | count(`signals`) | text |
| 11 | Total Events | `signals`, `is_event`(number) | `&& is_event == 1` | count(`signals`) | text |
| 12 | Avg Drift Score | `forecast_drift_score`→`score` | — | mean(`score`), 1 dp | thresholds 20/40/70 |
| 13 | Critical | `signals` | `&& drift_status == 'Critical'` | count | fixed red |
| 14 | Warning | `signals` | `&& drift_status == 'Warning'` | count | fixed orange |
| 15 | Watch | `signals` | `&& drift_status == 'Watch'` | count | fixed yellow |
| 16 | Healthy | `signals` | `&& drift_status == 'Healthy'` | count | fixed green |

### B. Drift Status Distribution — donut (id 20, signals.csv)
- Columns: `drift_status`, `drift_event_id`→`signals` (+ filter columns). FEXPR.
- Transform: `groupBy` → `drift_status` (groupby), `signals` (count).
- Value mappings: Healthy→green, Watch→yellow, Warning→orange, Critical→red. `pieType: donut`, values shown.

### C. Average Drift Score Over Time — timeseries (id 21, signals.csv)
- Columns: `forecast_version` (**timestamp**, X-axis), `forecast_drift_score`→`score` (+ region/forecast_key/drift_status/run_id). FEXPR **without** the version clause (keeps region/key/status/run).
- Transform: `groupBy` → `forecast_version` (groupby), `score` (mean). Series renamed "Avg Drift Score".
- Thresholds (absolute, `thresholdsStyle: dashed`): green base · yellow 20 · orange 40 · red 70. Line fixed blue, 1 dp.

### D. Signals by Dominant Drift Family — barchart horizontal (id 22, signals.csv)
- Columns: `dominant_drift_family`→`family`, `signals` (+ filter columns). FEXPR.
- Transforms: `groupBy` → `family` (groupby), `signals` (count); then `sortBy` `signals (count)` desc.
- Value mappings capitalize: stability→Stability, volatility→Volatility, shape→Shape, performance→Performance.
- Color: **fixed blue** (neutral). Orientation horizontal, value shown.

### E. Forecast Keys by Drift Risk — table (id 23, signals.csv)
- Columns: `forecast_key`→`Forecast Key`, `forecast_drift_score`→`score`, `drift_event_id`→`signals` (+ region/forecast_version/drift_status/run_id). FEXPR.
- Transforms:
  1. `groupBy` → `Forecast Key` (groupby), `score` (mean, max), `signals` (count).
  2. `organize` → rename `score (mean)`→"Avg Drift Score", `score (max)`→"Max Drift Status", `signals (count)`→"Total Signals"; order 0–3.
  3. `sortBy` "Avg Drift Score" desc.
- Overrides:
  - **Avg Drift Score**: 2 dp, right, `color-text`, thresholds 20/40/70.
  - **Max Drift Status**: `color-text`, **range** value mappings 0–20→Healthy/green, 20–40→Watch/yellow, 40–70→Warning/orange, 70–100000→Critical/red.
  - **Total Signals**: 0 dp, right.

### F. Latest Governed Run — table (id 24, runs.csv)
- Columns: `calculation_run_id`→"Run ID", `run_status`→"Status", `run_finished_at`→"Finished At (UTC)" (**timestamp**), `signals_written`→"Signals Written" (number), `events_created`→"Events Created" (number).
- filterExpression: `calculation_run_id IN (${run_id:singlequote})`.
- Overrides: Finished At → `unit: time:YYYY-MM-DD HH:mm`; Status → `color-text` mapping Success→green.

### G. Data Quality — Checks Passed — stat (id 25, runs.csv)
- Columns: `checks_passed` (number), `checks_total` (number), `calculation_run_id` (string).
- `computed_columns`: `{ selector: "checks_passed + ' / ' + checks_total", text: "dq" }` → "18 / 18".
- filterExpression: `calculation_run_id IN (${run_id:singlequote})`. Reduce lastNotNull(`dq`). Background green.

## 4. Layout (24-col grid)
| Row (y,h) | Panels |
|---|---|
| 0,3 | Nav (id 1) |
| 3,3 | Header (id 2) |
| 6,4 | Total Signals · Total Events · Avg Drift · Critical · Warning · Watch · Healthy (10–16) |
| 10,8 | Donut (20, w8) · Trend (21, w16) |
| 18,9 | Family bars (22, w8) · Key risk table (23, w16) |
| 27,6 | Latest Governed Run (24, w16) · Data Quality (25, w8) |
