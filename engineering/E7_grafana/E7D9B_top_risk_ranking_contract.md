# E7D.9B — Top Risk · Ranking Contract

Primary ranking metric = **AVG(`forecast_drift_score`)** over the non-null signals in the current filtered universe. No new score; no weight recompute; no family-score blending.

## Numerator / denominator / aggregation / universe

| Metric | Numerator | Denominator | Aggregation | Universe |
|--------|-----------|-------------|-------------|----------|
| Average Drift Score (KPI, per dimension) | Σ `forecast_drift_score` | count of non-null `forecast_drift_score` | mean | filtered signals |
| Signals | — | — | count `drift_event_id` | filtered signals |
| Drift Events | — | — | Σ (`is_event == '1' ? 1 : 0`) | filtered signals |
| Critical | — | — | Σ (`drift_status == 'Critical' ? 1 : 0`) | filtered signals |
| Warning | — | — | Σ (`drift_status == 'Warning' ? 1 : 0`) | filtered signals |
| Max Drift Score | — | — | max `forecast_drift_score` | filtered signals |
| Worst Drift Status | — | — | max `sev_rank` → label | filtered signals |
| Avg Family Score | Σ `family_score` (COMPUTED) | count COMPUTED | mean | filtered family_scores |

`sev_rank` order-only hierarchy (NOT a score, never averaged): Healthy 1 · Watch 2 · Warning 3 · Critical 4. Displayed via value mapping → colored label.

## Tie-break order
Avg Drift Score desc → Critical desc → Drift Events desc → Max Drift Score desc → name asc. (Panels sort on Avg Drift Score desc; remaining columns disambiguate visually.)

## Rankings (All filters — recomputed from CSV, sole truth)

**Forecast Keys (avg desc):** NAM-SDF 42.74 · NAM-MULTITENANT 40.79 · NAM-MSIT 34.01 · EUR-MULTITENANT 33.24 · APC-MULTITENANT 30.06 · IND-GO LOCAL 29.00 · EUR-MSIT 28.62 · JPN-GO LOCAL 24.55 · AUS-GO LOCAL 22.37 · GBR-GO LOCAL 21.72 · LAM-MULTITENANT 19.80 · CAN-GO LOCAL 19.10. (14 signals each.)

**Highest-Risk key:** NAM-SDF (Region NAM, Avg 42.74, Max 80.00, 14 signals, 10 events, 4 Critical, 2 Warning, Worst = Critical).

**Regions (avg desc):** NAM 39.18 (42 sig, 9 crit) · EUR 30.93 · APC 30.06 · IND 29.00 · JPN 24.55 · AUS 22.37 · GBR 21.72 · LAM 19.80 · CAN 19.10.

**Forecast Versions (avg desc, ranked by risk not chronology):** 2025-12-01 53.25 · 2026-03-07 46.49 · 2025-07-01 44.21 · 2026-01-01 39.95 · 2025-06-01 34.32 · 2026-04-06 34.10 · 2024-06-01 25.49 · 2026-02-01 25.15 · 2026-05-01 21.69 · 2024-08-01 20.11 · 2026-04-16 16.26 · 2024-04-01 16.16 · 2024-07-01 14.87 · 2024-05-01 11.62. (12 signals each.)

**Drift Families (avg family_score desc, nulls excluded):** volatility 56.04 (144 computable / 24 not) · stability 38.93 (168 / 0) · shape 26.03 (168 / 0) · performance 7.71 (156 / 12).

## Deviation
Per-key Dominant Drift Family is not a ranking column (14 versions per key, no governed single dominant family, no `groupBy` mode). Dominant family is shown per-signal (Risk Details) and decomposed per-key × family (Risk Matrix).
