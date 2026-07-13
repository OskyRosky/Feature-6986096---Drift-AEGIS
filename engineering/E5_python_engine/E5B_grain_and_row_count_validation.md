# E5B — Grain & Row-Count Validation

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

## Two distinct grains (do not confuse them)
| Layer | Grain | Meaning |
| --- | --- | --- |
| **Source fact** (`forecast_substrateBE_hdd_region`) | `Key × DateTime × ForecastVersion × Scenario × Resource` | one forecast value per canonical key, target month, version |
| **Signal output** (`forecast_drift_signals`) | `calculation_version × scenario × forecast_key(canonical) × forecast_version` | one drift signal per key×version (aggregates the family evaluations) |

The signal grain is an **aggregation** of the fact grain: for each
`(key, version)` pair the engine builds Shape/Stability/Volatility/Performance
across its forward target series and emits **one** signal row. So signal rows ≪
fact rows by design.

## Was the E5A "63,144 rows" inflated?
`63,144` was the raw **forecast** row count of the E5A sample (3 keys × 8
versions) *before* forward-only filtering (E5A reported 35,145 forward rows).
Two questions matter:

1. **Case-variant inflation (I1).** In E5A the key case-folding was destructive
   (`.str.upper()`), so counts were already de-cased but *not audited*. E5B now
   emits `distinct_keys_raw`, `distinct_keys_canonical`, `keys_merged` on every
   run, so any inflation from case variants is now **measured, not assumed**. On
   the synthetic fixture this surfaced 9→7 (2 merged); the live expanded sample
   will print the real fact-table figure.
2. **Duplicate load G1 (FV 2025-06-01).** Dedupe on the natural grain
   `[Key, target_date, forecast_version, model_version, Scenario, Resource]`
   removes exact duplicate rows; `run_refresh` reports `rows_after_dedupe`.

## Step-by-step counters emitted every run (`normalization_stats`)
| Counter | Source |
| --- | --- |
| `rows_in` | raw forecast rows extracted |
| `distinct_keys_raw` / `distinct_keys_canonical` / `keys_merged` | canonicalization audit (I1) |
| `rows_after_nulls` | after dropping null target/version/value |
| `rows_after_dedupe` | after G1 dedupe on the natural grain |
| `duplicate_version_present` | whether FV 2025-06-01 is present |
| `rows_forward_only` | after forward-only (`target_date ≥ forecast_version`, G6) |
| `distinct_keys` / `distinct_versions` | post-normalization grain size |

## Grain uniqueness enforced by checks
`checks.run_checks` verifies:
- `grain_unique` — no duplicate `(calc_version, scenario, forecast_key, forecast_version, drift_type)`;
- `record_hash_unique` — every signal hash distinct;
- `four_families_per_signal` — exactly 4 family rows per signal;
- `forecast_key_is_canonical` — active key equals its canonical form.

## Synthetic fixture check (expanded, seed 42)
- forward rows: **2,208**; signals: **85**; family rows: **340** (85 × 4);
- grain_unique PASS; record_hash_unique PASS; four_families_per_signal PASS.

## Conclusion
The signal count is **not** inflated: it is the intended per-`(key, version)`
aggregation, now backed by explicit, auditable counters at each transformation
step and by canonicalization that collapses case/whitespace variants.

### Live confirmation (2026-07-13)
Real Enterprise/HDD sample (12 keys, 15 versions), reproduced on both runs:
- rows_in 575,484 → after_dedupe 531,696 (43,788 duplicate rows removed, G1) →
  forward-only 265,824.
- distinct_keys_raw 21 → canonical 12 (9 merged).
- signals 168, family 672 (168×4), events 71; grain_unique + record_hash_unique
  + four_families_per_signal all PASS on real data.
