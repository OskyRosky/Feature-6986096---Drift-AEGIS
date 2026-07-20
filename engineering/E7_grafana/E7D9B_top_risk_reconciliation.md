# E7D.9B — Top Risk · Reconciliation

Baselines recomputed directly from the served CSVs (`V2/data/processed/current/`, sole truth) and matched against the panel definitions. All diffs = 0.

> **v5 repair note (2026-07-20):** the family Avg (id51) and Risk Matrix (id60) values below are the governed **excl-empty** means. In published version 4 those two panels incorrectly averaged non-computable scores as 0 (id51 Volatility rendered 48.03, matrix NAM-SDF Volatility 70.47). Version 5 fixes this (id51 = query A `family_score != ''` mean + query B counts, joined by family; id60 = four per-metric `!= ''` queries joined by key), so the live dashboard now renders exactly the values in this document. Confirmed visually by Oscar.

## Gate A — Cardinality (PASS)
| Check | Value | Expected |
|-------|-------|----------|
| signals rows | 168 | 168 |
| signals distinct `drift_event_id` | 168 | 168 |
| family_scores rows | 672 | 672 (168×4) |
| family_scores distinct `drift_event_id` | 168 | 168 |
| family rows per event (min/max) | 4 / 4 | 4 / 4 |
| family_scores computable | 636 | 636 |
| Risk Details row count | 168 | 168 |

No signals-based panel exceeds 168. No signals×family_scores join is performed anywhere.

## Global KPIs (All filters)
| KPI | Panel | CSV | Match |
|-----|-------|-----|-------|
| Forecast Keys Monitored | id10 | 12 | ✅ |
| Average Drift Score | id11 | 28.83 | ✅ |
| Critical Signals | id12 | 14 | ✅ |
| Drift Events | id13 | 71 | ✅ |
| Highest-Risk Forecast Key | id14 | NAM-SDF (42.74) | ✅ |
| Data Quality | id90 | 18 / 18 | ✅ |

## Forecast Key ranking (id20/id21) — avg desc
NAM-SDF 42.74 (max 80.00, 14 sig, 10 evt, 4 crit, 2 warn) · NAM-MULTITENANT 40.79 (84.72, 2 crit, 6 warn) · NAM-MSIT 34.01 (3 crit) · EUR-MULTITENANT 33.24 · APC-MULTITENANT 30.06 · IND-GO LOCAL 29.00 (84.22) · EUR-MSIT 28.62 (0 crit) · JPN-GO LOCAL 24.55 · AUS-GO LOCAL 22.37 · GBR-GO LOCAL 21.72 (84.60, 1 crit) · LAM-MULTITENANT 19.80 · CAN-GO LOCAL 19.10. ✅

## Region ranking (id30) — avg desc
NAM 39.18 (42 sig, 9 crit) · EUR 30.93 · APC 30.06 · IND 29.00 · JPN 24.55 · AUS 22.37 · GBR 21.72 · LAM 19.80 · CAN 19.10. ✅

## Forecast Version ranking (id40) — avg desc
2025-12-01 53.25 · 2026-03-07 46.49 · 2025-07-01 44.21 · 2026-01-01 39.95 · 2025-06-01 34.32 · 2026-04-06 34.10 · 2024-06-01 25.49 · 2026-02-01 25.15 · 2026-05-01 21.69 · 2024-08-01 20.11 · 2026-04-16 16.26 · 2024-04-01 16.16 · 2024-07-01 14.87 · 2024-05-01 11.62. ✅

## Drift Family ranking + computability (id50/id51)
| Family | Avg | Max | Computable | Non-computable |
|--------|-----|-----|-----------|----------------|
| volatility | 56.04 | 100.00 | 144 | 24 |
| stability | 38.93 | 100.00 | 168 | 0 |
| shape | 26.03 | 100.00 | 168 | 0 |
| performance | 7.71 | 100.00 | 156 | 12 |

Computable + Non-computable = 168 per family (reconciles to signal universe). ✅

## Risk Matrix (id60) — per-key mean of native family columns (sample)
| Key | Performance | Shape | Stability | Volatility |
|-----|-------------|-------|-----------|-----------|
| NAM-SDF | 8.80 | 42.22 | 54.78 | 82.21 |
| NAM-MULTITENANT | 13.37 | 39.14 | 54.16 | 71.04 |
| NAM-MSIT | 18.39 | 28.15 | 43.18 | 67.62 |
| EUR-MSIT | 2.24 | 24.66 | 38.16 | 66.88 |
| CAN-GO LOCAL | 0.00 | 17.65 | 27.24 | 42.89 |

Matrix built from signals native columns (no join) and reconciles with the standalone family ranking. ✅

## Latest Governed Run (id80)
Run 1 · Success · finished 2026-07-13T22:44:10Z · signals_written 168 · events_created 71 · checks 18/18. ✅

## Live datasource confirmation
`/api/ds/query` against the live datasource returned data for all three sources (signals, family_scores, runs). Ternary computed columns validated live (NAM-SDF `sev_rank` = 1,2,2,2,3,4,4,4…; Critical Σ = 4).
