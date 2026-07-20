# E7D.2 — Forecast MVP · Query Contract

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-forecast` · 2026-07-19

This dashboard reuses the **stable E7D.1 mechanism** verbatim. All queries are Infinity `csv` / `url` /
backend-parser targets against the read-only V2 snapshot; aggregation is done by Grafana **transformations**,
never in SQL.

## Template variables (5) — Infinity `queryType` wrapper
Every variable `query` is wrapped as `{ queryType:"infinity", refId:"variable", infinityQuery:{ … } }`
(a flat `InfinityQuery` without the wrapper is treated as legacy and returns empty options — the E7D.1 v3
defect). Common settings: `includeAll:true`, `multi:true`, `allValue:null`, `refresh:1`, `sort:1`.

| Variable | Source CSV | columns | computed_columns |
|----------|-----------|---------|------------------|
| `forecast_key` | signals | `forecast_key` | — |
| `forecast_version` | signals | `forecast_version` (string) | `__value = 'v' + forecast_version` |
| `region` | signals | `region` | — |
| `drift_status` | signals | `drift_status` | — |
| `run_id` | runs | `calculation_run_id` | — |

**Why the `v`-prefixed value for `forecast_version`:** the raw values are ISO dates. The Grafana frontend
infers ISO-date variable options as *time* (red-triangle values) and Infinity's backend string `IN` on
hyphenated dates triggers a string-arithmetic bug. Mapping the variable's `__value` to `'v' + date`
(e.g. `v2025-12-01`) yields a plain string used in `fv_label IN (...)`.

## Shared filter expression (signal panels)
Each signal panel selects the technical filter columns (with `text == selector`, never renamed) plus a
computed `fv_label = 'v' + forecast_version`, and applies:

```
region IN (${region:singlequote}) &&
forecast_key IN (${forecast_key:singlequote}) &&
fv_label IN (${forecast_version:singlequote}) &&
drift_status IN (${drift_status:singlequote}) &&
calculation_run_id IN (${run_id:singlequote})
```

**Filtered columns must keep `text == selector`** — `filterExpression` resolves by column `text`; any alias
on a filtered column breaks the filter (the E7D.1 panel 23/24 defect). Display names are applied downstream
via `displayName` overrides or an `organize` rename **after** the query.

## Panel-by-panel contract
| id | Panel | Type | Measure | Transform | Filter |
|----|-------|------|---------|-----------|--------|
| 10 | Overall Forecast Drift Score | gauge | mean `forecast_drift_score` | reduce mean | full |
| 20 | Drift Family Distribution | piechart (donut) | count by `dominant_drift_family` | groupBy family / count | full |
| 21 | Drift Status Distribution | piechart (donut) | count by `drift_status` | groupBy status / count | full |
| 30 | Avg Drift Score Over Time | timeseries | mean score per version | groupBy `forecast_version` (timestamp) / mean | **no fv clause** |
| 40 | Forecast Keys by Avg Drift Score | barchart (h) | mean score per key | groupBy key / mean → sortBy desc | full |
| 50 | Drift Score Heatmap | table | one score per key×version | 14 targets → joinByField → filterFieldsByName → organize | fixed cross-tab |
| 60 | Latest Governed Run | table | run metadata | — | `calculation_run_id` only |
| 70 | Data Quality — Checks Passed | stat | `checks_passed / checks_total` | reduce lastNotNull | `calculation_run_id` only |

## Trend exception (panel 30)
`forecast_version` is selected as **`timestamp`** for the X-axis, and the `fv_label` clause is **dropped** so
the full 14-version history renders regardless of the Forecast Version filter. It still honors Region,
Forecast Key, Drift Status and Run ID. Thresholds are dashed at 20 / 40 / 70; the series is renamed
"Avg Drift Score" via an override.

## Run / Data-Quality panels (60, 70)
Source = `forecast_drift_runs.csv`, filtered by `calculation_run_id IN (${run_id:singlequote})`. The Run ID
column keeps `text == selector` and is displayed as "Run ID" via a `displayName` override; `run_finished_at`
uses `unit: time:YYYY-MM-DD HH:mm`; the DQ stat renders a computed `checks_passed + ' / ' + checks_total`.

## Colors
- **Severity** palette (green / yellow 20 / orange 40 / red 70) only where severity applies: gauge, status
  donut, trend thresholds, heatmap cells.
- **Neutral, non-severity** colors for categories: family donut (`stability` #3274D9, `volatility` #B877D9,
  `shape` #37A2B8, `performance` #FF7EB6) and the forecast-key bars (fixed blue). Dashboard timezone = UTC.
