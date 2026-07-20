# E7D.6 — Volatility MVP · Reconciliation

Method: each panel's exact Infinity query was replayed **headlessly** through `POST /api/ds/query` (literal filter
clauses injected in place of template variables, which the API does not expand) and the reduced result compared to
the governed CSV ground truth. Both source CSVs (`forecast_drift_signals.csv`, `forecast_drift_family_scores.csv`)
were exercised.

## KPIs (filters = All)
| KPI | Formula | CSV expected | Grafana (API replay) | Δ | Status |
|-----|---------|-------------:|---------------------:|--:|:------:|
| Average Volatility Drift Score | mean(volatility_drift_score, computable) | 56.04 | 56.04 | 0 | ✅ |
| Volatility Signals Computable | count(volatility_drift_score≠'') | 144 | 144 | 0 | ✅ |
| Non-computable | 168 − 144 | 24 | 24 | 0 | ✅ |
| Volatility Coverage | mean(is_comp→number) | 85.7 % | 85.7 % | 0 | ✅ |
| Maximum Volatility Drift Score | max(volatility_drift_score) | 100.00 | 100.00 | 0 | ✅ |

## Drift trend (mean volatility_drift_score per version, computable)
| Version | CSV mean | Grafana | n | Status |
|---------|---------:|--------:|--:|:------:|
| 2024-06-01 | 30.62 | 30.62 | 12 | ✅ |
| 2024-07-01 | 33.54 | 33.54 | 12 | ✅ |
| 2024-08-01 | 32.84 | 32.84 | 12 | ✅ |
| 2025-06-01 | 40.58 | 40.58 | 12 | ✅ |
| 2025-07-01 | 56.54 | 56.54 | 12 | ✅ |
| 2025-12-01 | 59.74 | 59.74 | 12 | ✅ |
| 2026-01-01 | **78.13** (peak) | 78.13 | 12 | ✅ |
| 2026-02-01 | 77.78 | 77.78 | 12 | ✅ |
| 2026-03-07 | 76.09 | 76.09 | 12 | ✅ |
| 2026-04-06 | 73.76 | 73.76 | 12 | ✅ |
| 2026-04-16 | 59.29 | 59.29 | 12 | ✅ |
| 2026-05-01 | 53.55 | 53.55 | 12 | ✅ |
| **Buckets** | 12 (first 2024-06-01) | 12 | — | ✅ |

The two non-computable versions (`2024-04-01`, `2024-05-01`) are correctly **absent** from the trend.

## Ranking by Forecast Key (barchart, top 5, mean, computable)
| Forecast Key | CSV mean | Grafana | Status |
|--------------|---------:|--------:|:------:|
| NAM-SDF | 82.21 | 82.21 | ✅ |
| NAM-MULTITENANT | 71.04 | 71.04 | ✅ |
| NAM-MSIT | 67.62 | 67.62 | ✅ |
| EUR-MSIT | 66.88 | 66.88 | ✅ |
| IND-GO LOCAL | 59.27 | 59.27 | ✅ |

## Governed auxiliary metrics (family_scores, volatility)
| Check | CSV expected | Grafana | Status |
|-------|-------------:|--------:|:------:|
| Volatility Profile rows (COMPUTED) | 144 | 144 | ✅ |
| `rolling_cov` populated | 144 | 144 | ✅ |
| Non-computable rows (NOT_COMPUTABLE) | 24 | 24 | ✅ |
| Non-computable reason | INSUFFICIENT_VERSIONS ×24 | INSUFFICIENT_VERSIONS ×24 | ✅ |

## Filter tests (signals KPIs — dynamic)
| Test | denom | computable | coverage | avg | max | Status |
|------|------:|-----------:|---------:|----:|----:|:------:|
| All | 168 | 144 | 85.7 % | 56.04 | 100 | ✅ |
| forecast_key = NAM-SDF | 14 | 12 | 85.7 % | 82.21 | 100 | ✅ |
| region = NAM | 42 | 36 | 85.7 % | 73.63 | 100 | ✅ |
| drift_status = Critical | 14 | 14 | 100 % | 87.90 | 100 | ✅ |
| version = v2026-01-01 (computable) | 12 | 12 | 100 % | 78.13 | 100 | ✅ |
| version = v2024-04-01 (**non-computable**) | 12 | 0 | **0 %** | — (empty) | — | ✅ |
| forecast_key = (missing) | 0 | 0 | — | empty, no error | ✅ |
| back to All | 168 | 144 | 85.7 % | 56.04 | 100 | ✅ |

The non-computable version test is the decisive proof of partial-computability handling: 12 signals exist for
`2024-04-01` but **0** are computable → Coverage correctly reports **0 %** and averages are empty (not zero).

## Result
**0 discrepancies.** All KPIs, the 12-bucket trend, the key ranking, the governed auxiliary metrics, the
non-computable summary, and every filter test reconcile exactly against the governed V2 CSV snapshot.
