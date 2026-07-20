# E7D.2 — Forecast MVP · Reconciliation

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-forecast` · 2026-07-19
All figures validated against the read-only V2 snapshot via `/api/ds/query` using the **published** panel
targets, with variables expanded to their `Include All` equivalents.

## Panel data gate (All filters)
| # | Panel | Metric | Expected (ground truth) | Observed | Result |
|---|-------|--------|-------------------------|----------|--------|
| 1 | Overall Forecast Drift Score | mean `forecast_drift_score` | 28.83 | 28.8334 | ✅ |
| 2 | Drift Family Distribution | count by family | stability 88 · volatility 45 · shape 27 · performance 8 | 88 / 45 / 27 / 8 | ✅ |
| 3 | Drift Status Distribution | count by status | Healthy 82 · Watch 38 · Warning 34 · Critical 14 | 82 / 38 / 34 / 14 | ✅ |
| 4 | Avg Drift Score Over Time | signal rows feeding 14 version buckets | 168 → 14 points | 168 rows | ✅ |
| 5 | Forecast Keys by Avg Drift Score | distinct keys | 12 | 12 | ✅ |
| 6 | Drift Score Heatmap | targets × rows | 14 × 12 | 14 / 14 targets × 12 rows | ✅ |
| 7 | Latest Governed Run | rows · status | 1 · Success | 1 · Success | ✅ |
| 8 | Data Quality — Checks Passed | value | 18 / 18 | 18 / 18 | ✅ |

## Internal consistency
- Family counts sum to **168** (88 + 45 + 27 + 8). ✅
- Status counts sum to **168** (82 + 38 + 34 + 14). ✅
- Trend resolves to **14** forecast-version buckets (each n=12). ✅
- Heatmap: 12 keys × 14 versions, **one score per cell**, 0 duplicates. ✅

## Filter behavior (on the PUBLISHED dashboard, panel targets)
| Scenario | Expected signals | Observed | Result |
|----------|------------------|----------|--------|
| All | 168 | 168 | ✅ |
| Drift Status = Critical | 14 | 14 | ✅ |
| Forecast Key = NAM-SDF | 14 | 14 | ✅ |
| Region = NAM | 42 | 42 | ✅ |
| Forecast Version = v2025-12-01 | 12 | 12 | ✅ |
| Forecast Version = v2025-12-01 → mean score | 53.3 | 53.3 | ✅ |

## Forecast-key ranking (bars, avg desc — reference)
NAM-SDF 42.74 · NAM-MULTITENANT 40.79 · NAM-MSIT 34.01 · EUR-MULTITENANT 33.24 · APC-MULTITENANT 30.06 ·
IND-GO LOCAL 29.00 · EUR-MSIT 28.62 · JPN-GO LOCAL 24.55 · AUS-GO LOCAL 22.37 · GBR-GO LOCAL 21.72 ·
LAM-MULTITENANT 19.80 · CAN-GO LOCAL 19.10.

## Forecast-version trend (mean per version — reference)
2024-04-01 16.2 · 2024-05-01 11.6 · 2024-06-01 25.5 · 2024-07-01 14.9 · 2024-08-01 20.1 · 2025-06-01 34.3 ·
2025-07-01 44.2 · 2025-12-01 53.3 · 2026-01-01 40.0 · 2026-02-01 25.1 · 2026-03-07 46.5 · 2026-04-06 34.1 ·
2026-04-16 16.3 · 2026-05-01 21.7.

## Summary
**Reconciliation: 8/8 panel metrics + 4/4 internal-consistency checks + 6/6 filter scenarios = 18/18 matched,
0 mismatches.** The dashboard reads and filters the governed data only; no metric is computed in Grafana
beyond display-time reductions/transformations.
