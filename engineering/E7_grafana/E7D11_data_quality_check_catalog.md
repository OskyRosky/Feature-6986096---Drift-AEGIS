# E7D.11 — Data-Quality Check Catalog (18 checks)

**Stage:** E7D.11 · **Date:** 2026-07-20
**Authoritative source:** `V2/data/processed/validation/_data_quality_checks.csv` (engine output, 18 rows, all PASS) + `V1/python/drift_engine/checks.py` (`run_checks()`).
**Derived catalog:** `V2/data/processed/validation/forecast_drift_data_quality_checks.csv` — SHA-256 `9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1`.
**Served copy (byte-identical):** `V2/data/processed/current/forecast_drift_data_quality_checks.csv` — **same SHA-256** — served at `http://aegis-csv/forecast_drift_data_quality_checks.csv`.
**Generator:** `V2/scripts/build-e7d11-check-catalog.ps1` (reproducible; driven by the source CSV; aborts if ≠ 18 or if a check lacks metadata).

## Gate A — no check invented
`canonical_check_name` is copied verbatim from the engine output. `check_id`, `category`, `scope`, `rule_description`, `expected_value`, `display_name` are a **documented presentation layer** justified 1:1 by `checks.py`. No check is invented, split, merged or renamed. **Total = 18 · PASS = 18 · FAIL = 0.**

## The 18 governed checks

| # | Check ID | Canonical Name | Category (derived) | Scope | Rule (from checks.py) | Expected | Observed | Status |
|---:|---|---|---|---|---|---|---|---|
| 1 | DQ-01 | `signals_not_empty` | Completeness & Presence | signals | Governed signals dataset must contain ≥ 1 row. | ≥ 1 signal row | 168 | PASS |
| 2 | DQ-02 | `required_columns_present` | Schema | signals | All required signal columns present. | No required columns missing ([]) | [] (none missing) | PASS |
| 3 | DQ-03 | `grain_unique` | Uniqueness | signals | No duplicates on grain (calculation_version, scenario, forecast_key, forecast_version, drift_type). | 0 duplicates | 0 duplicates | PASS |
| 4 | DQ-04 | `record_hash_unique` | Uniqueness | signals | Every `record_hash` unique. | All record_hash unique | unique (assertion satisfied) | PASS |
| 5 | DQ-05 | `scores_in_0_100` | Value Range | signals | Family/composite scores and `score_coverage_pct` within [0,100]. | 0 scores out of range | 0 out of range | PASS |
| 6 | DQ-06 | `composite_not_null` | Completeness & Presence | signals | Composite `forecast_drift_score` non-null for every signal. | No null composite scores | no nulls (assertion satisfied) | PASS |
| 7 | DQ-07 | `weights_sum_100` | Configuration | governed config | Governed family weights (20+40+30+10) sum to 100. | 100.0 | 100.0 | PASS |
| 8 | DQ-08 | `no_inf_values` | Value Range | family_scores | No infinite values in numeric family metrics. | 0 infinite values | 0 | PASS |
| 9 | DQ-09 | `no_empty_keys` | Completeness & Presence | signals | Every signal has a non-empty `forecast_key`. | No empty forecast_key | no empty keys (assertion satisfied) | PASS |
| 10 | DQ-10 | `four_families_per_signal` | Structural Integrity | family_scores | Each signal has exactly 4 family rows. | 4 families for all signals | {4: 168} | PASS |
| 11 | DQ-11 | `confidence_valid` | Enumeration | signals | `confidence_level` ∈ {HIGH, MEDIUM, LOW}. | All values in {HIGH, MEDIUM, LOW} | all valid (assertion satisfied) | PASS |
| 12 | DQ-12 | `status_valid` | Enumeration | signals | `drift_status` ∈ {Healthy, Watch, Warning, Critical, Unknown}. | All values in set | all valid (assertion satisfied) | PASS |
| 13 | DQ-13 | `forecast_key_raw_present` | Completeness & Presence | signals | `forecast_key_raw` lineage column present (E5B I1). | forecast_key_raw column present | present (assertion satisfied) | PASS |
| 14 | DQ-14 | `forecast_key_is_canonical` | Canonicalization | signals | `forecast_key` = UPPER(TRIM(forecast_key)) for every row. | All forecast_key canonical | all canonical (assertion satisfied) | PASS |
| 15 | DQ-15 | `severity_only_on_events` | Conditional Integrity | signals | `severity` populated only where `is_event = 1`. | severity null unless is_event = 1 | satisfied (assertion satisfied) | PASS |
| 16 | DQ-16 | `performance_mode_valid` | Enumeration | signals | `performance_mode` ∈ {shallow, deep}. | All values in {shallow, deep} | all valid (assertion satisfied) | PASS |
| 17 | DQ-17 | `not_computable_has_null_score` | Conditional Integrity | family_scores | `NOT_COMPUTABLE` family rows have null score (never zero). | All NOT_COMPUTABLE scores null | satisfied (assertion satisfied) | PASS |
| 18 | DQ-18 | `eligibility_status_valid` | Enumeration | family_scores | `eligibility_status` ∈ {COMPUTED, NOT_COMPUTABLE}. | All values in {COMPUTED, NOT_COMPUTABLE} | all valid (assertion satisfied) | PASS |

**Checked at (UTC):** 2026-07-13T22:44:10Z (run 1 `run_finished_at`).

## Category rollup (derived; 9 categories, total 18)
| Category | Checks | Canonical names |
|---|---:|---|
| Completeness & Presence | 4 | signals_not_empty, composite_not_null, no_empty_keys, forecast_key_raw_present |
| Enumeration | 4 | confidence_valid, status_valid, performance_mode_valid, eligibility_status_valid |
| Uniqueness | 2 | grain_unique, record_hash_unique |
| Value Range | 2 | scores_in_0_100, no_inf_values |
| Conditional Integrity | 2 | severity_only_on_events, not_computable_has_null_score |
| Schema | 1 | required_columns_present |
| Configuration | 1 | weights_sum_100 |
| Structural Integrity | 1 | four_families_per_signal |
| Canonicalization | 1 | forecast_key_is_canonical |
| **Total** | **18** | |
