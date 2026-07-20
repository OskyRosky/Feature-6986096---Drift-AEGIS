# E7D.3 — Performance MVP · Reconciliation

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-performance` · 2026-07-19

All numbers below were computed **live** against the datasource via `/api/ds/query` (backend parser) with the
real panel query semantics, and compared to the governed CSV baselines. **No value is hardcoded** in the
dashboard — every panel reduces the datasource at render time.

## KPI reconciliation (filters = All)
| # | KPI | Expected (baseline) | Grafana query (live) | Diff | Status |
|---|-----|---------------------|----------------------|------|--------|
| A | Average Performance Drift Score | ≈ 7.71 | **7.7111** (mean over 156 computable) | 0.00 | ✅ |
| B | Performance Signals Computable | 156 | **156** (count `performance_drift_score != ''`) | 0 | ✅ |
| C | Average MAPE Change | ≈ 0.81 % | **0.8066 %** (mean `metric_delta_pct`, 8 `MAPE_deep` rows) | 0.00 | ✅ |
| D | Performance Coverage | ≈ 92.9 % | **92.9 %** (156 ÷ 168) | 0.0 | ✅ |

## Internal-consistency checks
| Check | Expected | Live | Status |
|-------|----------|------|--------|
| Computable + Non-computable = filtered universe | 156 + 12 = 168 | 156 + 12 = 168 | ✅ |
| Coverage division | 156 ÷ 168 = 0.9286 | 0.9286 → 92.9 % | ✅ |
| MAPE source cardinality | 8 `MAPE_deep` rows | 8 | ✅ |
| Non-computable reason (governed) | NO_REALIZED_OVERLAP = 12 | NO_REALIZED_OVERLAP = 12 | ✅ |

## E — trend per forecast version (panel semantics: string + `!= ''`, then mean)
156 computable rows across **13 buckets** (2026-05-01 correctly **excluded** — its 12 signals are all
non-computable). The number-typed shortcut wrongly emits a spurious `2026-05-01 → 0` bucket because empty
coerces to `0`; the panel uses **string typing + `convertFieldType`**, which excludes it.

| Version | Avg perf drift score | n |
|---------|---------------------|---|
| 2024-04-01 | 0.73 | 12 |
| 2024-05-01 | 1.93 | 12 |
| 2024-06-01 | 0.00 | 12 |
| 2024-07-01 | 3.30 | 12 |
| 2024-08-01 | 3.72 | 12 |
| 2025-06-01 | **38.19** (peak) | 12 |
| 2025-07-01 | 15.46 | 12 |
| 2025-12-01 | 0.00 | 12 |
| 2026-01-01 | 0.00 | 12 |
| 2026-02-01 | 2.52 | 12 |
| 2026-03-07 | **23.19** (peak) | 12 |
| 2026-04-06 | 2.88 | 12 |
| 2026-04-16 | 8.33 | 12 |

Matches the Power BI V1 reference ("peaks ≈ 38 and ≈ 23, several zeros").

## F — details spot-check (top keys by avg perf drift score)
NAM-MSIT 18.39 · EUR-MULTITENANT 15.29 · NAM-MULTITENANT 13.37 · APC-MULTITENANT 9.13 · NAM-SDF 8.8 ·
GBR-GO LOCAL 7.69 · LAM-MULTITENANT 7.69 · IND-GO LOCAL 6.21 · AUS-GO LOCAL 3.71 · EUR-MSIT 2.24 ·
CAN-GO LOCAL 0 · JPN-GO LOCAL 0. Max `performance_drift_score` = 100.

## Filter-response tests (literal clauses injected to simulate resolved `${var}`)
| Scenario | n (computable) | mean | Status |
|----------|----------------|------|--------|
| All | 156 | 7.71 | ✅ |
| `forecast_key = NAM-MSIT` | 13 | 18.39 | ✅ |
| `region = NAM` | 39 | 13.52 | ✅ |
| `forecast_version = v2025-06-01` (with `forecast_version` selected) | 12 | 38.19 | ✅ |
| `forecast_version = v2026-03-07` | 12 | 23.19 | ✅ |
| `drift_status = Critical` | 14 | 30.03 | ✅ |
| `forecast_key = DOES-NOT-EXIST` | 0 | — (empty) | ✅ |

> **Harness note:** a first filter-test run returned 0 for the version scenario because the harness omitted
> selecting `forecast_version`, so `fv_label = 'v' + forecast_version` computed over a missing field. Every
> real version-filtering panel selects `forecast_version`, so the filter resolves correctly (re-confirmed
> 12 / 38.19). This re-affirms the query-contract rule.

## H / I — governed run
Run **1** · **Success** · Finished **2026-07-13 22:44 UTC** · Signals Written **168** · Events Created **71** ·
Data Quality **18 / 18**.

## D (v3) — Coverage panel repair & dynamic-denominator proof
**Defect (v2):** the *Performance Coverage* stat rendered **completely empty** while every other panel worked.
**Root cause:** coverage reduces the computed flag `is_comp` (`performance_drift_score != ''`) with a `mean`
reducer, but despite `type:"number"` on the computed column **Infinity returns `is_comp` as a `boolean` field**
(frame schema `is_comp : boolean`, values `True/False`); Grafana's `mean` over a boolean yields no value → empty
render. (Panel A works because it applies `convertFieldType` before `mean`; panel B works because `count`
operates on any type.)
**Fix (v3):** added one `convertFieldType is_comp → number` transformation (True→1 / False→0) **before** the
`mean` reducer — no layout / query / filter / unit (`percentunit`) / decimals (1) change. Mean of 156×1 + 12×0
over 168 = 0.928571 → `percentunit` ×100 → **92.9 %** (single ×100).
**Dynamic-denominator proof** (headless, boolean→number→mean emulated — denominator is the row count per
filter, **not hardcoded to 168**):

| Scenario | Denominator (rows) | Numerator (Σ is_comp) | Coverage |
|----------|--------------------|-----------------------|----------|
| All | **168** | 156 | 92.9 % |
| `forecast_key = NAM-MSIT` | **14** | 13 | 92.9 % |
| `region = NAM` | **42** | 39 | 92.9 % |
| `forecast_version = v2025-06-01` | **12** | 12 | 100 % |
| back to All | **168** | 156 | 92.9 % |

Both numerator and denominator recompute per filter; coverage is a ratio, not a constant.

## Verdict
**All KPI, consistency, trend, details and filter checks matched — 0 mismatches.** Structural pre-publish
validator: **0 failures** (JSON valid, uid/title correct, 5 `queryType`-wrapped variables, every
`filterExpression` field exists as a technical column, no premature aliasing, datasource by UID, secret-free,
no legacy variable format, no empty panels; Overview/Forecast unmodified). Live rendering to be confirmed by
Oscar (the agent browser session is unauthenticated).
