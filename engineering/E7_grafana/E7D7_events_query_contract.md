# E7D.7 — Events Dashboard · Query Contract

**Stage:** E7D.7 · **Date:** 2026-07-19
**Datasource:** `aegis-forecast-drift-csv` (Infinity, `parser: backend`, CSV over nginx `aegis-csv`).
No token, no credentials, relative governed URLs only.

## Shared filters (template variables)

| Variable | Label | Source column | CSV |
|---|---|---|---|
| `forecast_key` | Forecast Key | `forecast_key` | signals |
| `forecast_version` | Forecast Version | `forecast_version` → value `fv_label = 'v'+version` | signals |
| `region` | Region | `region` | signals |
| `drift_status` | Drift Status | `drift_status` | signals |
| `run_id` | Run ID | `calculation_run_id` | runs |
| `drift_family` | Drift Family (local, 6th) | `dominant_drift_family` | signals |

All variables: `includeAll`, `multi`, `All` option, data-driven, no hardcoded values.
> Note vs E7D.0 filter matrix: Events **adds** `forecast_version` (via `fv_label`) because the event
> rows are the `signals` subset, where `forecast_version` **is** a native dimension (12 values among
> events). A local **Drift Family** filter is added (governed, 4 values). Documented deviation.

## Canonical event predicate

Every signal-based panel filters events with:

```
is_event == '1'
&& region IN (${region:singlequote})
&& forecast_key IN (${forecast_key:singlequote})
&& fv_label IN (${forecast_version:singlequote})
&& drift_status IN (${drift_status:singlequote})
&& calculation_run_id IN (${run_id:singlequote})
&& dominant_drift_family IN (${drift_family:singlequote})
```

**Infinity rules honored:** equality uses `==` (single `=` → HTTP 400); `IN (...)` and `!=` valid;
**every column referenced in a `filterExpression` must be a selected column** (or a
`computed_columns` entry). `fv_label` is a computed column `'v' + forecast_version`, so
`forecast_version` **must also be selected** wherever `fv_label` is filtered (learned: filtering
`fv_label` without selecting `forecast_version` silently returns 0 rows). Numeric/timestamp columns
are typed at the column (`type: number` / `type: timestamp`) and converted for display.

## Panels

| id | Panel | Type | Source | Extra predicate | Reduce / transform |
|---|---|---|---|---|---|
| 1 | Navigation | text | — | — | shared markdown nav (Events bold) |
| 2 | Header | text | — | — | title + subtitle |
| 10 | Total Events | stat | signals | — | count `drift_event_id` → 71 |
| 11 | Critical Events | stat | signals | `&& drift_status == 'Critical'` | count → 14 (red) |
| 12 | Warning Events | stat | signals | `&& drift_status == 'Warning'` | count → 34 (orange) |
| 13 | Affected Forecast Keys | stat | signals | — | groupBy `forecast_key` → count groups → 12 |
| 20 | Latest Event | table | signals | — | sortBy `detected_on` desc, then `drift_event_id` desc, limit 1 |
| 30 | Events by Drift Family | piechart (donut) | signals | — | groupBy `dominant_drift_family` count; family palette (non-severity) |
| 31 | Events by Drift Status | piechart (donut) | signals | — | groupBy `drift_status` count; severity palette |
| 32 | Events by Forecast Key | barchart (horizontal) | signals | — | groupBy `forecast_key` count, sorted |
| 40 | Governed Event Log | table | signals | — | sortBy `detected_on` desc, then `drift_event_id` desc; column filters enabled |
| 50 | Latest Governed Run | table | runs | `calculation_run_id IN (${run_id:...})` | run status / finished / signals / events_created |
| 60 | Data Quality | table | runs | `calculation_run_id IN (${run_id:...})` | checks_passed / checks_total = 18 / 18 |

## Formatting

- Counts: 0 decimals. Drift score: 2 decimals. Timestamps: `YYYY-MM-DD HH:mm` (UTC, dashboard timezone `utc`).
- `drift_status` colored via value mappings (Healthy green / Watch yellow / Warning orange / Critical red), `color-text` cell.
- `dominant_drift_family` mapped to Capitalized labels with a **non-severity** palette (blues/purples) to avoid confusing family with severity.
- Event Log: vertical scroll, no global horizontal scroll, Explanation wraps, per-column filter icons (native search).

## Search (Phase 8)

Implemented via **native table column filters** (`filterable: true` on the Event Log) — stable, no
plugin, no HTTP 400 risk. A free-text Text Box variable was **deferred** (not needed for the MVP;
native column filters cover Forecast Key / Explanation / etc.).

## Time range (Phase 5)

Event detection is a single instant (2026-07-13 UTC). Saved dashboard range = **2026-07-01 → 2026-07-31**
(tight window, no multi-year empty space), timepicker hidden, `keepTime = false` so navigation never
inherits another dashboard's range. Infinity CSV ignores the dashboard time range for filtering, so
counts are unaffected by the window.
