# E7D.8 — Historical Timeline · Temporal Schema

Defines the governed temporal model behind the timeline. Every claim here was verified live against the governed snapshot (via `/api/ds/query` and the raw CSVs) on 2026-07-20.

## Governed temporal fields (and why only one is a real axis)
| Field | Distinct values | Verdict | Use in dashboard |
|-------|-----------------|---------|------------------|
| `forecast_version` | 14 in signals; **12 among events** (2024-04-01 → 2026-05-01) | Real temporal spread | **Primary timeline axis** (Date Basis = *Forecast Version*) |
| `detected_on` | 1 instant (2026-07-13 22:38 UTC) for all 71 | No spread | Surfaced as a fact in the note, not as rows |
| `created_at` | = `detected_on` | No spread | Not an axis |
| `changed_at` | = `detected_on` | No spread | Not an axis |

**Conclusion:** the only honest chronological axis is `forecast_version`. Placing 71 events on `detected_on` would produce a single vertical clump misrepresenting history, so it is deliberately avoided.

## Lifecycle (event_history) — no fabricated transitions
`forecast_drift_event_history.csv` has 71 rows:
- `old_status` = empty (71/71)
- `new_status` = `Open` (71/71)
- `changed_by` = `drift_engine`; `note` = "auto-created on detection"

→ **Zero** true status transitions. The dashboard reports this as **Lifecycle Records (Initial Open) = 71, transitions = 0** and does not synthesize any Acknowledged / Investigating / Resolved history.

## Events per forecast_version (governed, sums to 71)
| forecast_version | events |
|------------------|--------|
| 2024-04-01 | 1 |
| 2024-06-01 | 2 |
| 2024-08-01 | 2 |
| 2025-06-01 | 8 |
| 2025-07-01 | 8 |
| 2025-12-01 | 10 |
| 2026-01-01 | 8 |
| 2026-02-01 | 7 |
| 2026-03-07 | 7 |
| 2026-04-06 | 8 |
| 2026-04-16 | 5 |
| 2026-05-01 | 5 |
| **Total** | **71** |

Note: `2024-05-01` and `2024-07-01` exist in the signals domain but carry **0** events (12 of 14 versions produce events).

## Computed temporal columns (Infinity backend)
Because the Infinity backend coerces raw date strings, the timeline uses computed columns:
- `fv_label` = `'v' + forecast_version` → a stable string key (e.g. `v2026-05-01`) used for both `IN (...)` filtering and Date-Range membership.
- `date_basis` = constant `'Forecast Version'`.
- `timeline_type` = constant `'Drift by Forecast Version'`.

Constant computed columns were verified to return literal values through the backend.

## Distributions at Date Range = All (governed)
- **Drift Status:** Critical 14 · Warning 34 · Watch 13 · Healthy 10
- **Drift Family:** shape 26 · stability 24 · volatility 15 · performance 6
- **Forecast Keys affected:** 12
- **Explanation coverage:** 71/71
- **Regions:** NAM 29 · EUR 14 · APC 7 · IND 7 · JPN 4 · CAN 3 · GBR 3 · AUS 2 · LAM 2
