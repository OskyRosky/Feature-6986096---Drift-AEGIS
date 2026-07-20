# E7D.3 — Performance MVP · Query Contract

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-performance` · 2026-07-19

Every panel reads the governed **V2** CSV snapshot through datasource `aegis-forecast-drift-csv`
(`yesoreyeram-infinity-datasource`), backend parser, and filters with the shared `filterExpression` contract.
Grafana performs no business logic — only read, filter and transform-based aggregation.

## Shared filter expression (the five bound filters)
```
region IN (${region:singlequote}) && forecast_key IN (${forecast_key:singlequote})
  && fv_label IN (${forecast_version:singlequote}) && drift_status IN (${drift_status:singlequote})
  && calculation_run_id IN (${run_id:singlequote})
```
`fv_label` is a per-row computed column `'v' + forecast_version` (avoids Grafana's ISO-date → `time`
inference that empties a raw-date variable). **Every panel that filters by version selects `forecast_version`
as a column** so the computed `fv_label` resolves (a computed column referencing an unselected field yields an
empty label → no match).

## The computability predicate (critical)
`performance_drift_score` is empty for non-computable rows. Infinity coerces empty cells oddly:
- A **numeric** `performance_drift_score >= 0` filter returns **HTTP 400** (empty cell → null comparison) and
  otherwise treats empty as truthy.
- A **ternary** computed column (`x == '' ? 0 : 1`) is **not supported** (returns empty).

**Working contract:** select `performance_drift_score` as **`type:"string"`** (so `text == selector`) and
filter with the literal clause **`performance_drift_score != ''`**. For a numeric mean, add a
`convertFieldType` transform (string → number). For the coverage flag, use a **boolean computed column**
`{ selector: "performance_drift_score != ''", text: "is_comp", type: "number" }` → per-row `1`/`0`.

## Per-panel contract

### A — Average Performance Drift Score (`stat`, id 10)
- URL `forecast_drift_signals.csv`; columns: `performance_drift_score` (string) + 5 dims; computed `fv_label`.
- `filterExpression` = shared **`&& performance_drift_score != ''`**.
- transform `convertFieldType performance_drift_score → number`; `reduceOptions.calcs=["mean"]`,
  `fields=/^performance_drift_score$/`; unit `short`, decimals 2; severity thresholds 20/40/70, `colorMode:value`.

### B — Performance Signals Computable (`stat`, id 11)
- Same query as A. `reduceOptions.calcs=["count"]`, `fields=/^performance_drift_score$/`; decimals 0, fixed blue.

### C — Average MAPE Change (`stat`, id 12)
- Columns: `metric_name` (string) + `metric_delta_pct` (number) + 5 dims; computed `fv_label`.
- `filterExpression` = shared **`&& metric_name == 'MAPE_deep'`**.
- `reduceOptions.calcs=["mean"]`, `fields=/^metric_delta_pct$/`; unit **`percent`** (no ×100), decimals 2.

### D — Performance Coverage (`stat`, id 13)
- Columns: `performance_drift_score` (string) + 5 dims; computed `fv_label` **and** `is_comp` (number).
- `filterExpression` = shared **only** (no computability clause — denominator = all filtered rows).
- `reduceOptions.calcs=["mean"]`, `fields=/^is_comp$/`; unit **`percentunit`** (×100), decimals 1; thresholds
  red < 0.7 · yellow ≥ 0.7 · green ≥ 0.9.

### E — Performance Drift Score Over Time (`timeseries`, id 30)
- Columns: `forecast_version` (**timestamp**) + `performance_drift_score` (string) + region/forecast_key/
  drift_status/calculation_run_id.
- `filterExpression` = region + forecast_key + drift_status + run_id **`&& performance_drift_score != ''`**
  — **drops the `fv_label` clause** (ignores the Forecast Version filter by design).
- transforms `convertFieldType score → number` → `groupBy forecast_version(groupby) + performance_drift_score(mean)`;
  dashed thresholds 20/40/70; axis auto (not forced 0–100); override `performance_drift_score (mean)` →
  displayName **Avg Performance Drift Score**.

### F — Performance Signal Details (`table`, id 50)
- Columns: forecast_key, forecast_version, previous_forecast_version, drift_status, performance_drift_score
  (string), metric_value, previous_metric_value, metric_delta_pct + region/calculation_run_id (filter only);
  computed `fv_label` + `is_comp` (number).
- `filterExpression` = shared (shows both computable and non-computable rows).
- transforms `convertFieldType score → number` → `sortBy score desc` → `organize` (exclude region /
  calculation_run_id / fv_label; rename to display headers). Overrides: score dec 2; MAPE Change unit
  `percent`; Current/Previous MAPE dec 3; Computable `1→Yes(green) / 0→No(red)`; Drift Status severity color.

### G — Non-computable Performance Summary (`table`, id 40)
- URL `forecast_drift_family_scores.csv`; columns: not_computable_reason, drift_family, eligibility_status,
  forecast_key, forecast_version; computed `fv_label`.
- `filterExpression` = **`drift_family == 'performance' && eligibility_status == 'NOT_COMPUTABLE'`** `&&`
  forecast_key + `fv_label` (only these two shared filters — family scores lack region/status/run_id).
- transforms `groupBy not_computable_reason(groupby) + drift_family(count)` → `organize` rename
  (`drift_family (count)` → **Signals**) → `sortBy Signals desc`.

### H — Latest Governed Run (`table`, id 60)
- URL `forecast_drift_runs.csv`; columns calculation_run_id, run_status, run_finished_at (timestamp),
  signals_written, events_created; `filterExpression = calculation_run_id IN (${run_id:singlequote})`.
  Status `Success → green`. (Cloned verbatim from the E7D.2 Forecast run panel.)

### I — Data Quality — Checks Passed (`stat`, id 70)
- URL `forecast_drift_runs.csv`; computed `checks_passed + ' / ' + checks_total → dq`; `lastNotNull` of `dq`;
  green background. (Cloned verbatim from the E7D.2 Forecast DQ panel.)

## Invariants enforced
- Datasource referenced **by UID** everywhere; no secrets in the JSON.
- Every `filterExpression` field exists as a **technical column** (`text == selector`); **no filtered column
  is renamed before filtering** (display renames happen in `organize`/`displayName` only).
- All five variables carry the `queryType:"infinity"` wrapper.
- No shell / preview language remains; no intentionally empty panels.
