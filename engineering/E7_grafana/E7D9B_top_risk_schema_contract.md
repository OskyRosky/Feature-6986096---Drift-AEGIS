# E7D.9B — Top Risk · Schema Contract

Served CSVs: `V2/data/processed/current/` via nginx `aegis-csv` → Infinity datasource `aegis-forecast-drift-csv` (backend CSV parser). Line counts confirmed live: signals 169 (168+header), family_scores 673, event_history 72, runs 2.

## forecast_drift_signals.csv — 168 rows, unique key `drift_event_id` (168 distinct)
Governed per-signal fact. Columns used by Top Risk:

| Column | Use |
|--------|-----|
| `drift_event_id` | unique key, count |
| `forecast_key` | key ranking / group |
| `region` | region ranking / group |
| `forecast_version` | version ranking / group; `fv_label = 'v' + forecast_version` |
| `drift_status` | Healthy / Watch / Warning / Critical — severity, conditional counts |
| `is_event` | 0/1 — drift-event count |
| `forecast_drift_score` | **primary ranking metric** (0 empty rows) |
| `performance_drift_score`, `shape_drift_score`, `stability_drift_score`, `volatility_drift_score` | native family scores → Risk Matrix (no join) |
| `dominant_drift_family` | per-signal dominant family |
| `detected_on`, `previous_forecast_version`, `explanation` | Risk Details context |
| `calculation_run_id` | run filter |

`service` column is empty (0 non-empty) — excluded. `scenario` = Enterprise only — excluded per no-invention rule.

## forecast_drift_family_scores.csv — 672 rows = 168 × 4 families (long format)
Governed per-family fact. One row per (`drift_event_id`, `drift_family`).

| Column | Use |
|--------|-----|
| `drift_family` | performance / shape / stability / volatility |
| `family_score` | family ranking metric; 36 empty (perf 12, vol 24) |
| `eligibility_status` | COMPUTED (636) / NOT_COMPUTABLE (36) |
| `forecast_key`, `forecast_version` | only filterable dimensions present |

No `region` / `drift_status` / `calculation_run_id` → family panels honor Forecast Key + Forecast Version only.

## forecast_drift_runs.csv — 1 row
`calculation_run_id`, `run_status` (Success), `run_finished_at` (2026-07-13T22:44:10Z), `signals_written` (168), `events_created` (71), `checks_passed`/`checks_total` (18/18) → Latest Governed Run + Data Quality.

## Cardinality contract
- signals-based panels: row universe ≤ 168 after filters. Never joined to family_scores.
- Risk Matrix uses the **native** family score columns inside signals → no fan-out.
- family_scores used **standalone** only (id50 barchart avg, id51 computability). Aggregated independently; never joined-then-counted.
- **Gate result: PASS** — signals 168 (168 distinct id), family_scores 672 (168 distinct id, min=max=4 rows/id).

## Expression capability (validated via `/api/ds/query`)
- Infinity `computed_columns` equality (`col == 'x'`) returns **boolean**; the `type:number` hint is ignored.
- **Ternary** (`col == 'x' ? 1 : 0`, nested) returns a real **number** → used for all conditional counts (`is_critical`, `is_warning`, `is_event_num`) and the severity rank (`sev_rank` 1..4).
