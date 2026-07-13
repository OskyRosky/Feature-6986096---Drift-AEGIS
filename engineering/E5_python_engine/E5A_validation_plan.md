# E5A — Validation Plan

**Feature 6986096 — AEGIS Forecast Drift Framework.** How correctness and governance are verified.

## 1. Fixture validation (E3 known answers)
Runnable via `python -m drift_engine.tests.test_fixtures` (standalone; pytest optional). Each fixture checks raw metric, normalized score (tolerance ±1.0) and status against E3. Results in `E5A_fixture_results.csv`.

| Fixture | Expected score | Status |
| --- | --- | --- |
| Performance 0.44→0.45 | 0.0 | Healthy |
| Performance 0.45→0.70 | 73.3 | Critical |
| Shape A vs B | 77.6 | Critical |
| Stability 120,122,121,156 | 86.7 | Critical |
| Volatility 100,102,101,99,101,160 | 83.9 | Critical |
| Composite (4) | 80.1 | Critical (dominant shape) |
| Composite (missing volatility) | 79.7 | Critical (coverage 90%, HIGH) |

**Result: 7/7 PASS** (engine 73.33/77.63/86.71/83.93/80.10/79.68 within tolerance).

## 2. Data-quality checks (`checks.run_checks`) on every real run
signals_not_empty · required_columns_present · grain_unique · record_hash_unique · scores_in_0_100 · composite_not_null · weights_sum_100 · no_inf_values · no_empty_keys · four_families_per_signal · confidence_valid · status_valid. Output: `data/processed/_data_quality_checks.csv`.

## 3. Idempotency
The sample run recomputes signals and asserts `record_hash` equality across the two passes (same input + config + formula version ⇒ identical hashes).

## 4. Real-sample validation
Controlled read-only sample (Enterprise / HDD / 5 keys / 12 versions). Confirms the four families run on real data where eligible, events generate, and outputs are non-empty and contract-conformant. See `E5A_real_sample_results.md`.

## 5. Governance checks
SELECT-only queries (no DML/DDL); host from env (no secrets in repo); outputs only under `V1/data/processed`; no Power BI/Grafana logic; no commit.

## 6. Deferred to E5B / later
Calibrate anchors/weights/thresholds on the full distribution; Performance deep-recompute; full-history run (requires explicit authorization).
