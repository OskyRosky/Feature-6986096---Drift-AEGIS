# E7D.9B — Top Risk · Query Contract

Datasource `aegis-forecast-drift-csv` (Infinity, backend CSV). All signals panels share the filter expression; family panels use the reduced expression.

**Shared signals filter:**
```
region IN (${region:singlequote}) && forecast_key IN (${forecast_key:singlequote})
  && fv_label IN (${forecast_version:singlequote}) && drift_status IN (${drift_status:singlequote})
  && calculation_run_id IN (${run_id:singlequote})
```
`fv_label = 'v' + forecast_version` (computed) — raw ISO-date columns are coerced by the backend and would match 0 rows; the `v`-prefix keeps them string. The `forecast_version` template variable therefore emits `__value = 'v' + forecast_version` (display text = raw date).

**Family filter (id50):** `forecast_key IN (${forecast_key:singlequote}) && fv_label IN (${forecast_version:singlequote}) && family_score != ''`.

**Family filter (id51, post-repair v5):** two queries — **A** (mean/max) adds `&& family_score != ''`; **B** (computable/non-computable counts) uses the base `forecast_key IN (...) && fv_label IN (...)` over all rows. Joined by `drift_family` (`joinByField`, outer). Empty scores are counted but never averaged.

## Panels

| id | Title | Source | Aggregation | Notes |
|----|-------|--------|-------------|-------|
| 1 | Nav (shared) | — | — | E7D.9A shell, unchanged |
| 2 | Header | — | — | executive summary text |
| 10 | Forecast Keys Monitored | signals | distinct count `forecast_key` | groupBy key → reduce count = 12 |
| 11 | Average Drift Score | signals | mean `forecast_drift_score` | thresholds 20/40/70, 2 dp = 28.83 |
| 12 | Critical Signals | signals | count (`drift_status=='Critical'`) | red = 14 |
| 13 | Drift Events | signals | count (`is_event=='1'`) | = 71 |
| 14 | Highest-Risk Forecast Key | signals | groupBy key,region → mean/sum/max → sort desc → limit 1 | NAM-SDF |
| 20 | Top Forecast Keys | signals | groupBy key → mean → sort desc | 12 bars, thresholds |
| 21 | Forecast Key Risk Summary | signals | groupBy key,region → mean,max,count,Σcrit,Σwarn,Σevent,max sev | drill links |
| 30 | Top Regions | signals | groupBy region → mean → sort desc | 9 bars |
| 40 | Top Forecast Versions | signals | groupBy version → mean → sort desc | 14 bars, risk-ranked |
| 50 | Top Drift Families | family_scores | filter `family_score != ''` → groupBy family → mean → sort desc | 4 bars |
| 51 | Drift Family Computability | family_scores (2 queries) | A: `family_score != ''` → groupBy family mean,max · B: all rows → groupBy family Σcomp,Σnoncomp · joinByField drift_family (outer) | brand colors; empties counted, never averaged |
| 60 | Risk Matrix (Key × Family) | signals native cols (4 queries) | per family: `<col> != ''` → convert that col → groupBy key mean · joinByField forecast_key (outer) | no fan-out; empties → null (not 0); color-background |
| 70 | Consolidated Risk Details | signals | sort `forecast_drift_score` desc | 168 rows @ All, 12 cols |
| 80 | Latest Governed Run | runs | — | filtered by run_id |
| 90 | Data Quality — Checks Passed | runs | lastNotNull `dq` | `checks_passed + ' / ' + checks_total`, green bg |

## Computed columns (validated)
- `fv_label = 'v' + forecast_version`
- `is_critical = drift_status == 'Critical' ? 1 : 0` (number)
- `is_warning = drift_status == 'Warning' ? 1 : 0`
- `is_event_num = is_event == '1' ? 1 : 0`
- `sev_rank = drift_status == 'Critical' ? 4 : (drift_status == 'Warning' ? 3 : (drift_status == 'Watch' ? 2 : 1))`
- `is_comp = family_score != '' ? 1 : 0`, `is_noncomp = family_score == '' ? 1 : 0`
- `dq = checks_passed + ' / ' + checks_total`

## Transform hygiene
- `forecast_drift_score` (and family score columns) selected as string then `convertFieldType → number` before mean/max.
- No `organize` transform is applied on top of a backend computed column beyond rename (avoids the known DQ regression).
- `groupBy` aggregated fields are referenced by their Grafana names, e.g. `forecast_drift_score (mean)`.
- **Family averages exclude empties before the mean** (per-query `... != ''` filter) — never rely on `convertFieldType` to null-out empty strings (it coerces `''` to 0, which `mean` would count). Multi-query panels (id51, id60) use per-query `filter: byRefId` transforms + `joinByField` (outer) so each metric is averaged only over its computable universe.

## Drill-through (id21, Forecast Key column data links)
- `/d/aegis-forecast-drift-forecast?var-forecast_key=${__value.text}`
- `/d/aegis-forecast-drift-events?var-forecast_key=${__value.text}`
- `/d/aegis-forecast-drift-timeline?var-forecast_key=${__value.text}`

No time range inherited (keepTime = false at nav dropdown; data links carry no from/to).
