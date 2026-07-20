# E7D.11 — Governed Settings Contract (Weights & Thresholds)

**Stage:** E7D.11 · **Date:** 2026-07-20
**Source of truth:** `V1/python/drift_engine/config/settings.py` (read-only; displayed, never edited by the dashboard).

## Family weights (`WEIGHTS`, version `w1.0`)
| Family | Weight |
|---|---:|
| Performance | 20% |
| Shape | 40% |
| Stability | 30% |
| Volatility | 10% |
| **Total** | **100%** |

Validated at runtime by check **DQ-07 `weights_sum_100`** (observed 100.0, PASS).

## Status thresholds (`BANDS`, version `t1.0`)
Boundary semantics (verbatim from `settings.py`): **inclusive lower, exclusive upper; Critical top inclusive.**

| Status | Range | Lower | Upper |
|---|---|---|---|
| 🟢 Healthy | [0, 20) | inclusive | exclusive |
| 🟡 Watch | [20, 40) | inclusive | exclusive |
| 🟠 Warning | [40, 70) | inclusive | exclusive |
| 🔴 Critical | [70, 100] | inclusive | inclusive |

### Boundary behavior (test vectors)
| Score | Expected status |
|---:|---|
| 0 | Healthy |
| 19.999 | Healthy |
| 20 | Watch |
| 39.999 | Watch |
| 40 | Warning |
| 69.999 | Warning |
| 70 | Critical |
| 100 | Critical |

## Minimum versions (`MIN_VERSIONS`)
Performance 2 · Shape 2 · Stability 2 · Volatility **4**. The Volatility minimum of 4 is why 24 volatility family rows are `NOT_COMPUTABLE` with reason `INSUFFICIENT_VERSIONS`.

## Governed versions
Calculation `E5A-v1` · Formula `f1.0` · Threshold `t1.0` · Weight `w1.0`.

## Presentation rule
Settings is displayed as **read-only reference**, clearly labeled as governed by the V1 engine. The dashboard reads governed values only — *el dashboard no cocina datos*.
