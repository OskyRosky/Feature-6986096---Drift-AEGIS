# E7D.4 — Shape MVP · Reconciliation

Method: each panel query was replayed **headlessly** against `POST /api/ds/query` (Infinity backend parser),
then aggregated in-process exactly as the panel reducer does. Template vars do not resolve via the API, so
literal filter clauses were injected. Ground truth = the governed V2 CSV snapshot
(`forecast_drift_signals.csv`, 168 rows) and the Power BI V1 baselines.

## KPIs (filters = All)
| Metric | Formula | CSV expected | Grafana (API replay) | Δ | Status |
|--------|---------|-------------:|---------------------:|--:|:------:|
| Average Shape Drift Score | mean(`shape_drift_score`) | 26.03 | **26.03** | 0.00 | ✅ |
| Shape Signals Computable | count(`shape_drift_score` ≠ '') | 168 | **168** | 0 | ✅ |
| Shape Coverage | mean(`is_comp`→number) | 100.0 % | **100.0 %** | 0.0 | ✅ |
| Maximum Shape Drift Score | max(`shape_drift_score`) | 100.00 | **100.00** | 0.00 | ✅ |

## Trend — Shape Drift Score Over Time (mean per forecast_version, n=12 each)
| Version | CSV mean | Grafana | Status |
|---------|---------:|--------:|:------:|
| 2024-04-01 | 15.27 | 15.27 | ✅ |
| 2024-05-01 | 10.55 | 10.55 | ✅ |
| 2024-06-01 | 25.28 | 25.28 | ✅ |
| 2024-07-01 | 11.36 | 11.36 | ✅ |
| 2024-08-01 | 17.76 | 17.76 | ✅ |
| 2025-06-01 | 28.51 | 28.51 | ✅ |
| 2025-07-01 | 43.48 | 43.48 | ✅ |
| **2025-12-01** | **62.60** | **62.60** | ✅ (peak) |
| 2026-01-01 | 39.83 | 39.83 | ✅ |
| 2026-02-01 | 20.17 | 20.17 | ✅ |
| **2026-03-07** | **44.08** | **44.08** | ✅ |
| 2026-04-06 | 23.03 | 23.03 | ✅ |
| 2026-04-16 | 9.59 | 9.59 | ✅ (low) |
| 2026-05-01 | 12.87 | 12.87 | ✅ |

## Filter tests (dynamic denominator + coverage)
| Test | denom | computable | coverage | avg | max | Status |
|------|------:|-----------:|---------:|----:|----:|:------:|
| All | 168 | 168 | 100.0 % | 26.03 | 100 | ✅ |
| forecast_key = NAM-SDF | 14 | 14 | 100.0 % | 42.22 | 100 | ✅ |
| region = NAM | 42 | 42 | 100.0 % | 36.50 | 100 | ✅ |
| drift_status = Critical | 14 | 14 | 100.0 % | 89.45 | 100 | ✅ |
| forecast_version = v2025-12-01 | 12 | 12 | 100.0 % | 62.60 | 100 | ✅ |
| non-existent key | 0 | 0 | — | — | — | ✅ (empty, no error) |
| back to All | 168 | 168 | 100.0 % | 26.03 | 100 | ✅ |

**Observations**
- Denominator is fully dynamic (168 → 14 → 42 → 14 → 12 → 168).
- Coverage stays **100 %** under every filter — Shape is fully computable (0 non-computable), consistent with the
  omitted Non-computable Summary panel.
- The `v2025-12-01` slice reproduces the trend peak (62.60) exactly, confirming the KPI ↔ trend consistency.
- The `NAM-SDF` slice matches the top-key baseline (avg 42.22, n=14).

**Verdict:** 0 discrepancies against CSV / Power BI baselines. Data path validated.
