# E7D.11 — Computability Contract

**Stage:** E7D.11 · **Date:** 2026-07-20
**Source:** `V2/data/processed/current/forecast_drift_family_scores.csv` (672 rows = 168 signals × 4 families).

## Governed rule
`eligibility_status` ∈ {`COMPUTED`, `NOT_COMPUTABLE`} (check **DQ-18**). `NOT_COMPUTABLE` family rows carry a **null** `family_score` — never treated as zero (check **DQ-17**). Non-computable rows carry a `not_computable_reason`.

## Coverage by family (run 1)
| Family | COMPUTED | NOT_COMPUTABLE | Total | Coverage |
|---|---:|---:|---:|---:|
| Performance | 156 | 12 | 168 | 92.9% |
| Shape | 168 | 0 | 168 | 100% |
| Stability | 168 | 0 | 168 | 100% |
| Volatility | 144 | 24 | 168 | 85.7% |
| **Total** | **636** | **36** | **672** | **94.6%** |

Verified live through the Grafana Infinity datasource (`/api/ds/query`): Performance 156/168, Shape 168/168, Stability 168/168, Volatility 144/168.

## Non-computable reasons
| Family | Reason | Rows |
|---|---|---:|
| Performance | `NO_REALIZED_OVERLAP` | 12 |
| Volatility | `INSUFFICIENT_VERSIONS` | 24 |

- **`NO_REALIZED_OVERLAP`** — no realized actuals overlap the forecast horizon, so a performance error cannot be computed.
- **`INSUFFICIENT_VERSIONS`** — fewer than the governed minimum of 4 versions (`MIN_VERSIONS.volatility = 4`), so volatility cannot be computed.

## Dashboard panels
- **Computability Coverage by Family** (id 60) — live `groupBy(drift_family, eligibility_status)` count.
- **Non-Computable Reasons by Family** (id 62) — live, filtered `eligibility_status == 'NOT_COMPUTABLE'`, grouped by family + reason.

Both panels read governed data; no non-computable score is averaged or coerced to zero.
