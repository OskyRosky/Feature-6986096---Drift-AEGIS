# E7D.8 — Historical Timeline · Query Contract

Datasource: Infinity `aegis-forecast-drift-csv` (backend parser, CSV over `http://aegis-csv/...`). All filtered columns are selected or computed (Infinity filter-column rule).

## Shared filter expression (event panels: 10, 11, 12, 13, 20, 30, 32, 40)
```
is_event == '1'
  && region IN (${region:singlequote})
  && forecast_key IN (${forecast_key:singlequote})
  && fv_label IN (${forecast_version:singlequote})
  && drift_status IN (${drift_status:singlequote})
  && calculation_run_id IN (${run_id:singlequote})
  && dominant_drift_family IN (${drift_family:singlequote})
  && contains('${date_range:raw}', '|' + fv_label + '|')
```
Computed column present on every event panel: `fv_label = 'v' + forecast_version`.

## Panel-by-panel
| id | Panel | Source CSV | Key columns / computed | Transform | Reduce/agg |
|----|-------|-----------|------------------------|-----------|------------|
| 10 | Timeline Records | signals | drift_event_id + filter cols; fv_label | — | count `drift_event_id` |
| 11 | Drift Events | signals | drift_event_id + filter cols; fv_label | — | count `drift_event_id` |
| 12 | Forecast Versions | signals | forecast_version + filter cols; fv_label | groupBy forecast_version (count is_event) | count distinct versions |
| 13 | Affected Forecast Keys | signals | forecast_key + filter cols; fv_label | groupBy forecast_key (count is_event) | count distinct keys |
| 14 | Lifecycle Records | event_history | event_history_id, new_status | — | count `event_history_id` (global) |
| 20 | Historical Timeline | signals | drift_event_id, forecast_version, forecast_key, dominant_drift_family, forecast_drift_score, drift_status, explanation; fv_label, date_basis | sortBy forecast_version DESC → sortBy drift_event_id DESC → organize | table |
| 30 | Drift Events by Forecast Version | signals | forecast_version, drift_event_id + filter cols; fv_label | groupBy forecast_version (count) → sortBy forecast_version ASC | barchart |
| 32 | Timeline Records by Forecast Key | signals | forecast_key, drift_event_id + filter cols; fv_label | groupBy forecast_key (count) → sortBy count DESC | barchart |
| 40 | Historical Details | signals | drift_event_id, forecast_version, forecast_key, region, previous_forecast_version, dominant_drift_family, forecast_drift_score, drift_status, event_status, explanation; fv_label, date_basis, timeline_type | sortBy forecast_version DESC → sortBy drift_event_id DESC → organize | table (filterable) |
| 50 | Latest Governed Run | runs | calculation_run_id, run_status, run_finished_at (timestamp), signals_written, events_created | organize | table (global) |
| 51 | Data Quality | runs | checks_passed, checks_total; `dq_label = checks_passed + ' / ' + checks_total + ' checks passed'` | organize (hide numerics) | last `dq_label` (global) |

## Constant / expression computed columns (verified)
- `'Forecast Version'` → `date_basis`
- `'Drift by Forecast Version'` → `timeline_type`
- `checks_passed + ' / ' + checks_total + ' checks passed'` → `dq_label` → renders `18 / 18 checks passed`

## Global (run-scoped) panels
Panels 14, 50, 51 read run-level facts and intentionally do **not** respond to the timeline filters (their CSVs carry no forecast_key/region/status/version columns). Documented in each panel description.

## Color palettes (parity with the AEGIS suite)
- Family: performance `#5794F2`, shape `#B877D9`, stability `#1F78C1`, volatility `#C0A3E5`.
- Severity: Healthy green, Watch yellow, Warning orange, Critical red.
