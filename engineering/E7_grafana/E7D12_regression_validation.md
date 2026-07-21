# E7D.12 — Data Regression Validation (per dashboard)

All figures below were **recomputed from the live governed CSVs on 2026-07-20**
(not hardcoded) and match the established E7D baselines. Source of truth:
`V2/data/processed/current/*.csv`.

## Global inventory
| Dataset | Rows | Distinct key check |
|---|---|---|
| forecast_drift_signals | 168 | 168 distinct `drift_event_id`; 12 distinct `forecast_key` |
| forecast_drift_family_scores | 672 | 168 × 4 families |
| forecast_drift_event_history | 71 | 71 lifecycle transitions |
| forecast_drift_runs | 1 | checks_total = checks_passed = 18 |
| forecast_drift_data_quality_checks | 18 | 18 PASS / 0 FAIL; DQ-01…DQ-18 |

## 1. Overview
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Total Signals | 168 | 168 | PASS |
| Drift Events | 71 | 71 (`is_event = 1`) | PASS |
| Forecast Keys | 12 | 12 | PASS |
| Data Quality | 18/18 | 18/18 | PASS |

## 2. Forecast
Reads signals × family_scores; drill filters active. Row basis 168 signals / 672
family rows — consistent with global inventory. PASS.

## 3. Performance (family = performance)
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Computable | 156 | 156 | PASS |
| Coverage | 92.9% | 92.9% | PASS |
| Average score | 7.71 | 7.71 | PASS |
| Max score | 100 | 100 | PASS |
| Non-computable | 12 | 12 | PASS |

## 4. Shape (family = shape)
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Computable | 168 | 168 | PASS |
| Coverage | 100% | 100% | PASS |
| Average score | 26.03 | 26.03 | PASS |
| Max score | 100 | 100 | PASS |

## 5. Stability (family = stability)
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Computable | 168 | 168 | PASS |
| Coverage | 100% | 100% | PASS |
| Average score | 38.93 | 38.93 | PASS |
| Max score | 100 | 100 | PASS |

## 6. Volatility (family = volatility)
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Computable | 144 | 144 | PASS |
| Coverage | 85.7% | 85.7% | PASS |
| Average score | 56.04 | 56.04 | PASS |
| Max score | 100 | 100 | PASS |
| Non-computable | 24 | 24 | PASS |

## 7. Events (signals where `is_event = 1`)
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Events | 71 | 71 | PASS |
| Critical | 14 | 14 | PASS |
| Warning | 34 | 34 | PASS |
| Affected Keys | 12 | 12 | PASS |

(Additional observed severity breakdown over events: Watch 13, unset 10 — informational.)

## 8. Historical Timeline
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Events | 71 | 71 | PASS |
| Lifecycle transitions | 71 | 71 | PASS |
| Versions / Keys | 12 / 12 | 12 / 12 | PASS |
| Data Quality | 18/18 | 18/18 | PASS |

## 9. Top Risk
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Forecast Keys | 12 | 12 (14 signals each) | PASS |
| Average composite | 28.83 | 28.83 | PASS |
| Critical | 14 | 14 | PASS |
| Events | 71 | 71 | PASS |
| Top key (NAM-SDF) composite | 42.74 | 42.74 | PASS |
| Family averages (vol/stab/shape/perf) | 56.04 / 38.93 / 26.03 / 7.71 | 56.04 / 38.93 / 26.03 / 7.71 | PASS |
| Details rows | 168 | 168 | PASS |
| Data Quality | 18/18 | 18/18 | PASS |

Ranking (avg composite, descending): NAM-SDF 42.74, NAM-MULTITENANT 40.79,
NAM-MSIT 34.01, EUR-MULTITENANT 33.24, APC-MULTITENANT 30.06, IND-GO LOCAL 29.00,
EUR-MSIT 28.62, JPN-GO LOCAL 24.55, AUS-GO LOCAL 22.37, GBR-GO LOCAL 21.72,
LAM-MULTITENANT 19.80, CAN-GO LOCAL 19.10.

## 10. Settings & Data Quality
| Metric | Baseline | Observed | Result |
|---|---|---|---|
| Checks total / passed / failed | 18 / 18 / 0 | 18 / 18 / 0 | PASS |
| Distinct check ids | 18 | 18 (DQ-01…DQ-18) | PASS |
| Family weights | 20 / 40 / 30 / 10 (Σ 100) | Σ 100 | PASS |
| Coverage (perf/shape/stab/vol) | 156 / 168 / 168 / 144 | 156 / 168 / 168 / 144 | PASS |
| Inventory (signals/family/events/runs/checks) | 168 / 672 / 71 / 1 / 18 | 168 / 672 / 71 / 1 / 18 | PASS |

## Score classification bands (governed)
| Band | Range | Rule |
|---|---|---|
| Healthy | [0, 20) | lower inclusive, upper exclusive |
| Watch | [20, 40) | lower inclusive, upper exclusive |
| Warning | [40, 70) | lower inclusive, upper exclusive |
| Critical | [70, 100] | lower inclusive, **upper inclusive** |

**Overall data regression: PASS — every dashboard reconciles to the governed CSVs.**
