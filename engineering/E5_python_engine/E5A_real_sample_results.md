# E5A — Real Sample Execution Results

**Feature 6986096 — AEGIS Forecast Drift Framework.** Controlled, read-only sample through the full engine. Synthetic/aggregate evidence only (no confidential row-level data reproduced beyond drift scores).

## Run parameters
- Scenario = Enterprise, Resource = HDD, ValueType = Forecast-Mean (SELECT only).
- 3 requested keys → **GBR-Go Local, LAM-Multitenant, CAN-Go Local**; 8 forecast versions (2025-07 → 2026-05).
- Runtime **41.5 s**; peak memory **48.7 MB**; parquet_available = false (CSV outputs).

## Ingestion & normalization
| Stat | Value |
| --- | --- |
| forecast rows extracted | 63,144 |
| actual rows | 27,924 |
| metric rows | 267 |
| rows after null drop | 63,144 |
| rows after dedupe (G1) | 63,144 (no 2025-06-01 in window) |
| rows forward-only (G6) | 35,145 |
| distinct keys after normalize | **6** (see finding below) |
| distinct versions | 8 |

**Finding (data quality):** the 3 requested keys resolved to **6 distinct `Key` strings** because the fact table stores **case variants** of the same key (e.g. `CAN-GO LOCAL` in older versions vs `CAN-Go Local` in newer ones; SQL's case-insensitive filter matched both). The engine treats them as separate keys. → E5B should **case-fold** keys during normalization.

## Signals produced
18 signals, 72 family-score rows (4 per signal), **8 events**. Status distribution: Healthy 9, Watch 4, Warning 2, Critical 3.

| forecast_key | version | perf | shape | stab | vol | FDS | cov% | conf | status | drift_type | event |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CAN-GO LOCAL | 2025-12-01 | – | 61.8 | 82.6 | – | 70.7 | 70 | MEDIUM | Critical | stability | ✔ |
| GBR-Go Local | 2026-04-06 | – | 77.6 | 98.4 | – | 86.5 | 70 | MEDIUM | Critical | shape | ✔ |
| LAM-MULTITENANT | 2026-01-01 | – | 75.3 | 92.7 | – | 82.7 | 70 | MEDIUM | Critical | shape | ✔ |
| GBR-GO LOCAL | 2026-01-01 | – | 39.5 | 66.7 | – | 51.1 | 70 | MEDIUM | Warning | stability | ✔ |
| LAM-MULTITENANT | 2026-02-01 | – | 37.4 | 59.0 | 69.5 | 49.5 | 80 | MEDIUM | Warning | stability | ✔ |
| CAN-Go Local | 2026-05-01 | 100.0 | 0.9 | 1.8 | 6.3 | 21.6 | 100 | HIGH | Watch | performance | ✔ |
| GBR-Go Local | 2026-05-01 | 80.7 | 10.5 | 18.3 | 71.8 | 33.0 | 100 | HIGH | Watch | performance | ✔ |
| LAM-Multitenant | 2026-05-01 | 100.0 | 1.5 | 3.6 | 3.0 | 22.0 | 100 | HIGH | Watch | performance | ✔ |

## Family computability (all four exercised on real data)
| Family | COMPUTED | NOT_COMPUTABLE | reason |
| --- | --- | --- | --- |
| Shape | 18 | 0 | ≥4 forward points always met |
| Stability | 18 | 0 | ≥2 versions met |
| Volatility | 6 | 12 | needs ≥4 versions per (key,target) |
| Performance | 6 | 12 | only where a metric version matches a fact version with a prior (e.g. 2026-04-16, 2026-05-01) |

**Coverage / confidence behaves correctly:** 70% (Shape+Stability) → MEDIUM; 80% (+Volatility) → MEDIUM; 90% (+Performance) → HIGH; 100% (all four) → HIGH. Missing-family renormalization verified on real rows.

## Quality & reproducibility
- Data-quality checks: **12/12 PASS** (`_data_quality_checks.csv`).
- Idempotency: recompute produced **identical record hashes** (idempotent = true).
- Outputs written: `forecast_drift_signals.csv`, `forecast_drift_family_scores.csv`, `forecast_drift_runs.csv`, `forecast_drift_event_history.csv`, `run_metadata.json`.

## Observations
- Performance = 100 at 2026-05-01 for CAN/LAM = MAPE relative jump exceeding the a100 anchor (clamped) — realistic deterioration signal.
- All events currently `event_status = Open` with history seeded.
- Runtime dominated by the SQL scan (~24 s of the 41 s); compute + validation + idempotency ~17 s.

## Not done (by design / awaiting authorization)
- Full-history run (only the small sample was processed).
- Anchor/weight/threshold calibration on the full distribution.
- Performance deep-recompute to align with fact-version grain (G2).
