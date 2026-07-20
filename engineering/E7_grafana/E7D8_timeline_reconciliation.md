# E7D.8 — Historical Timeline · Reconciliation

All figures verified live via `/api/ds/query` (GATES A–F) on 2026-07-20 against the governed V2 snapshot (run 1). Every difference is either zero or explained.

## 1. Drift detection (governed events)
| Metric | Value | Source |
|--------|-------|--------|
| Total drift events (`is_event = 1`) | 71 | signals |
| Critical / Warning / Watch / Healthy | 14 / 34 / 13 / 10 | signals |
| Affected forecast keys | 12 | signals (distinct) |
| Run `events_created` | 71 | runs |
| **Diff (events vs events_created)** | **0** | ✔ |

## 2. Forecast-version timeline (the axis)
| Metric | Value |
|--------|-------|
| Timeline records (drift events by version) | 71 |
| Distinct forecast versions (among events) | 12 |
| Distinct forecast versions (signals domain) | 14 (2 carry 0 events) |
| Earliest / latest version | 2024-04-01 / 2026-05-01 |
| **Sum of per-version event counts** | **71** ✔ |

## 3. Lifecycle
| Metric | Value |
|--------|-------|
| Lifecycle records (event_history) | 71 |
| Initial `Open` records | 71 |
| True status transitions | 0 |
| **Diff (records vs events)** | **0** ✔ |

## 4. Date Range (functional proof — GATE B)
| Window | Events | Expected | Result |
|--------|--------|----------|--------|
| All available history | 71 | 71 | PASS |
| Year to date | 40 | 40 | PASS |
| Last 180 days | 32 | 32 | PASS |
| Last 90 days | 5 | 5 | PASS |
| Last 60 days | 0 | 0 | PASS |
| Last 30 days | 0 | 0 | PASS |
| Year 2024 | 5 | 5 | PASS |
| Year 2025 | 26 | 26 | PASS |
| Year 2026 | 40 | 40 | PASS |

Cross-check: Year2024 (5) + Year2025 (26) + Year2026 (40) = **71** ✔. YTD (40) == Year 2026 (40) ✔ (all governed 2026 versions are ≤ the reference date).

## 5. Data quality / provenance
| Metric | Value |
|--------|-------|
| Latest run | run 1, `Success` |
| Run finished | 2026-07-13 22:44 UTC |
| Signals written | 168 |
| Events created | 71 |
| Checks passed / total | 18 / 18 |

## KPI coincidence (documented, not an error)
`Timeline Records` (71) == `Drift Events` (71) because every timeline record is exactly one governed drift event. Both KPI descriptions state this explicitly.

## Overall
All reconciliations close to zero difference; the only "gaps" (2 versions with 0 events; Last 60/30 days = 0) are governed realities, surfaced honestly.
