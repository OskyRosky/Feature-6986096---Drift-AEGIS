# E7D.4 — Shape MVP · Query Contract

Datasource: **AEGIS Forecast Drift CSV** (`yesoreyeram-infinity-datasource`, uid `aegis-forecast-drift-csv`,
referenced by UID). Parser `backend`. Docker-internal URLs (never `localhost` inside queries):
`http://aegis-csv/forecast_drift_signals.csv`, `/forecast_drift_family_scores.csv`, `/forecast_drift_runs.csv`.

## Template variables (5)
All `queryType:"infinity"` wrapper, `includeAll:true`, `multi:true`, `allValue:null`, `refresh:1`, `sort:1`.

| Var | Source column | Notes |
|-----|---------------|-------|
| `forecast_key` | `forecast_key` (signals) | |
| `forecast_version` | `forecast_version` (signals) | computed column `__value = 'v' + forecast_version` → option value is the `fv_label` string |
| `region` | `region` (signals) | |
| `drift_status` | `drift_status` (signals) | |
| `run_id` | `calculation_run_id` (runs) | |

## Shared filter contract (KPIs A/B/D + Details F)
```
region IN (${region:singlequote})
  && forecast_key IN (${forecast_key:singlequote})
  && fv_label IN (${forecast_version:singlequote})
  && drift_status IN (${drift_status:singlequote})
  && calculation_run_id IN (${run_id:singlequote})
  && shape_drift_score != ''
```
- `fv_label` = computed `'v' + forecast_version`; the version filter matches on this **label**, never on a raw
  date, so it aligns with the variable's `__value`.
- `${var:singlequote}` renders `'a','b'` so `IN (...)` stays valid for multi-select + All.

## Per-panel contract
| id | Panel | Query columns / computed | Transforms | Reducer |
|----|-------|--------------------------|-----------|---------|
| 10 | **A** Average Shape Drift Score | select `shape_drift_score`+dims; filter (shared) | `convertFieldType shape_drift_score→number` | **mean** (dec 2, thr 20/40/70) |
| 11 | **B** Shape Signals Computable | select `shape_drift_score`+dims; filter (shared) | — | **count** |
| 13 | **C** Shape Coverage | computed `is_comp = shape_drift_score != ''` (number); filter **without** the computability clause (denominator = all filtered rows) | `convertFieldType is_comp→number` | **mean** → % (percentunit dec1, thr red / 0.7 yellow / 0.9 green) |
| 14 | **D** Maximum Shape Drift Score | select `shape_drift_score`+dims; filter (shared) | `convertFieldType shape_drift_score→number` | **max** (dec 2, thr 20/40/70) |
| 30 | **E** Shape Drift Score Over Time | `forecast_version` (timestamp) + `shape_drift_score`; filter (shared) **minus** the `fv_label` clause (keeps full history when a version is selected) | `convertFieldType shape_drift_score→number` + `groupBy forecast_version → mean` | series mean |
| 50 | **F** Shape Signal Details | `forecast_key, forecast_version, previous_forecast_version, region, drift_status, shape_drift_score, is_comp`; filter (shared) | `convertFieldType` + `sortBy shape_drift_score desc` + `organize` (rename/reorder) | table |
| 60 | **H** Latest Governed Run | runs.csv, latest by `run_finished_at` | filter `calculation_run_id IN (${run_id})` | table |
| 70 | **I** Data Quality — Checks Passed | runs.csv computed `dq = checks_passed + '/' + checks_total` | `lastNotNull` | stat |

## Boolean-computed-column rule (critical)
A computed column such as `shape_drift_score != ''` or `is_comp` returns to Grafana as a **boolean** frame field.
Numeric reducers (`mean`, `max`) over a boolean yield **empty**. Every numeric reduction over such a column
**must** be preceded by `convertFieldType → number` (applied on id10/13/14/30). This is the same fix that
resolved the E7D.3 Coverage empty-panel bug.
