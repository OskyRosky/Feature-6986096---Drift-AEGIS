# E7D.7 — Events Dashboard · Schema Contract

**Stage:** E7D.7 · **Date:** 2026-07-19
**Sources (governed V2 snapshot, read-only):** `forecast_drift_signals.csv` (168 rows),
`forecast_drift_runs.csv` (1 row). Served docker-internally via nginx `aegis-csv` through datasource
`aegis-forecast-drift-csv` (Infinity, backend parser).

## Key finding — there is no rich "events" CSV

`forecast_drift_event_history.csv` is a **thin lifecycle-history** table (7 columns, 71 rows):
`event_history_id, drift_event_id, old_status(empty), new_status(=Open), changed_at, changed_by(=drift_engine), note(=auto-created on detection)`.
It carries **no** forecast_key / region / family / score / explanation.

**The events are the subset of `forecast_drift_signals.csv` where `is_event = 1` (71 of 168 rows).**
All rich event fields live in `signals`. The dashboard therefore reads `signals` filtered by
`is_event == '1'` — no cross-CSV join required.

## Event schema actually used (from signals, is_event = 1)

| Field (mockup intent) | Available | Source column | Cardinality / value | Use in Grafana |
|---|:--:|---|---|---|
| Event ID | ✅ | `drift_event_id` | 71 distinct | Event Log column |
| Event Timestamp | ✅ (constant) | `detected_on` (= `created_at`) | single: 2026-07-13T22:38 UTC | Timestamp column / Latest Event |
| Forecast Key | ✅ | `forecast_key` | 12 | KPI, filter, column, bar chart |
| Region | ✅ | `region` | 9 | filter, column |
| Forecast Version | ✅ | `forecast_version` (via `fv_label = 'v'+version`) | 12 (among events) | filter, column |
| Previous Version | ✅ | `previous_forecast_version` | 14 | column |
| Drift Family | ✅ | `dominant_drift_family` | 4 (shape/stability/volatility/performance) | filter, family chart, column |
| Drift Score | ✅ | `forecast_drift_score` | max 84.72 | column, Latest Event |
| Drift Status (severity) | ✅ | `drift_status` | 4 (Healthy/Watch/Warning/Critical) | KPIs, status chart, colored column |
| Explanation | ✅ | `explanation` | 71/71 populated | Event Log column (wrapped) |
| Lifecycle Status | ✅ (constant) | `event_status` | single: Open | Event Log column |
| Run | ✅ | `calculation_run_id` | 1 | filter, column, footer |

## Mockup fields intentionally ABSENT (governed snapshot lacks them)

| Field | Why not shown |
|---|---|
| **Service** | `service` column is empty (0 distinct). Forecast Key is used instead. |
| **Scenario** | `scenario` single value (`Enterprise`) — no informational filter/column. |
| **Separate Severity** | `severity` (61/168 non-null, 3 values) is a partial alias of `drift_status`; surfacing it would duplicate status. `drift_status` is the governed severity band. |
| **Event Type** | No `event_type` column exists. (`reason_code` exists but is not the mockup's "type"; omitted to keep the log lean — available for a future iteration.) |
| **Resolved / Acknowledged / Investigating** | No such governed lifecycle values exist. Only `event_status = Open`. |
| **Target Date as event time** | `target_date` exists (76 distinct) but is the *forecast horizon*, not the event time; not used as a timestamp. |

## Field-role decisions

- **Primary timestamp:** `detected_on` (single instant → no events-over-time trend; replaced by Events by Forecast Key).
- **Family field:** `dominant_drift_family`.
- **Severity/status field:** `drift_status` (governed bands).
- **Explanation field:** `explanation` (present for all 71).
- **Lifecycle field:** `event_status` = Open (governed, constant).
