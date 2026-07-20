# E7D.5 — Stability MVP · Reconciliation

Method: each panel query was replayed **headlessly** against `POST /api/ds/query` (Infinity backend parser),
then aggregated in-process exactly as the panel reducer does. Template vars do not resolve via the API, so
literal filter clauses were injected. Ground truth = the governed V2 CSV snapshot
(`forecast_drift_signals.csv`, 168 rows) and the Power BI V1 baselines.

## KPIs (filters = All)
| Metric | Formula | CSV expected | Grafana (API replay) | Δ | Status |
|--------|---------|-------------:|---------------------:|--:|:------:|
| Average Stability Drift Score | mean(`stability_drift_score`) | 38.93 | **38.93** | 0.00 | ✅ |
| Stability Signals Computable | count(`stability_drift_score` ≠ '') | 168 | **168** | 0 | ✅ |
| Stability Coverage | mean(`is_comp`→number) | 100.0 % | **100.0 %** | 0.0 | ✅ |
| Maximum Stability Drift Score | max(`stability_drift_score`) | 100.00 | **100.00** | 0.00 | ✅ |

## Trend — Stability Drift Score Over Time (mean per forecast_version, n=12 each)
| Version | CSV mean | Grafana | Status |
|---------|---------:|--------:|:------:|
| 2024-04-01 | 27.63 | 27.63 | ✅ |
| 2024-05-01 | 19.51 | 19.51 | ✅ |
| 2024-06-01 | 41.04 | 41.04 | ✅ |
| 2024-07-01 | 21.05 | 21.05 | ✅ |
| 2024-08-01 | 29.94 | 29.94 | ✅ |
| 2025-06-01 | 37.39 | 37.39 | ✅ |
| 2025-07-01 | 60.23 | 60.23 | ✅ |
| **2025-12-01** | **74.14** | **74.14** | ✅ (peak) |
| 2026-01-01 | 54.03 | 54.03 | ✅ |
| 2026-02-01 | 29.33 | 29.33 | ✅ |
| 2026-03-07 | 55.36 | 55.36 | ✅ |
| 2026-04-06 | 56.47 | 56.47 | ✅ |
| **2026-04-16** | **16.08** | **16.08** | ✅ (low) |
| 2026-05-01 | 22.84 | 22.84 | ✅ |

## Filter tests (dynamic denominator + coverage)
| Test | denom | computable | coverage | avg | max | Status |
|------|------:|-----------:|---------:|----:|----:|:------:|
| All | 168 | 168 | 100.0 % | 38.93 | 100 | ✅ |
| forecast_key = NAM-SDF | 14 | 14 | 100.0 % | 54.78 | 100 | ✅ |
| region = NAM | 42 | 42 | 100.0 % | 50.71 | 100 | ✅ |
| drift_status = Critical | 14 | 14 | 100.0 % | 95.35 | 100 | ✅ |
| forecast_version = v2025-12-01 | 12 | 12 | 100.0 % | 74.14 | 100 | ✅ |
| non-existent key | 0 | 0 | — | — | — | ✅ (empty, no error) |
| back to All | 168 | 168 | 100.0 % | 38.93 | 100 | ✅ |

**Observations**
- Denominator is fully dynamic (168 → 14 → 42 → 14 → 12 → 168).
- Coverage stays **100 %** under every filter — Stability is fully computable (0 non-computable), consistent with
  the omitted Non-computable Summary panel.
- The `v2025-12-01` slice reproduces the trend peak (74.14) exactly, confirming KPI ↔ trend consistency.
- The `NAM-SDF` slice matches the top-key baseline (avg 54.78, n=14); `Critical` slice avg 95.35 confirms banding.

**Verdict:** 0 discrepancies against CSV / Power BI baselines. Data path validated.
