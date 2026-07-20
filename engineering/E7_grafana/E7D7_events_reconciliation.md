# E7D.7 — Events Dashboard · Reconciliation

**Stage:** E7D.7 · **Date:** 2026-07-19
**Method:** live Grafana query API (`/api/ds/query`) vs governed CSV ground truth
(`forecast_drift_signals.csv` / `forecast_drift_runs.csv`). **Result: zero difference.**

## KPIs & distributions

| Metric | CSV (ground truth) | Grafana (live API) | Δ |
|---|---:|---:|:--:|
| Total Events (`is_event = 1`) | 71 | 71 | 0 |
| Critical | 14 | 14 | 0 |
| Warning | 34 | 34 | 0 |
| Watch | 13 | 13 | 0 |
| Healthy | 10 | 10 | 0 |
| Family — shape | 26 | 26 | 0 |
| Family — stability | 24 | 24 | 0 |
| Family — volatility | 15 | 15 | 0 |
| Family — performance | 6 | 6 | 0 |
| Affected Forecast Keys | 12 | 12 | 0 |
| Explanation populated | 71 / 71 | 71 / 71 | 0 |
| `event_status` distinct | Open | Open | 0 |
| Max drift score | 84.72 | 84.72 | 0 |

## Latest governed run (footer panels)

| Field | CSV | Grafana | Δ |
|---|---|---|:--:|
| Run status | Success | Success | 0 |
| Signals written | 168 | 168 | 0 |
| Events created | 71 | 71 | 0 |
| Checks passed / total | 18 / 18 | 18 / 18 | 0 |
| Run finished at | 2026-07-13T22:44 UTC | 2026-07-13T22:44 UTC | 0 |

## Cross-check: events_created (run) == Total Events (log) == 71 ✅

## Filter tests (Phase 12, live API)

| Test | Expected (CSV) | Grafana | Status |
|---|---:|---:|:--:|
| All (`is_event=1`) | 71 | 71 | ✅ |
| Region = NAM | 29 | 29 | ✅ |
| Drift Status = Critical | 14 | 14 | ✅ |
| Run ID = 1 | 71 | 71 | ✅ |
| Drift Family = shape | 26 | 26 | ✅ |
| Forecast Key = NAM-MSIT | 9 | 9 | ✅ |
| Forecast Version = v2026-05-01 | 5 | 5 | ✅¹ |
| Back to All | 71 | 71 | ✅ |
| NAM + Critical (combo) | 9 | 9 | ✅ |

¹ The `fv_label` predicate returns 5 **when `forecast_version` is a selected column** (as it is in all
dashboard panels). A harness that filtered `fv_label` without selecting `forecast_version` returned 0 —
confirming the "column must be selected" Infinity rule; the dashboard panels select it, so they are correct.

**Conclusion:** every KPI, distribution, footer value and filter reconciles exactly with the governed
CSV. The dashboard does not cook, invent or hardcode any value (71 is derived from `is_event = 1`).
