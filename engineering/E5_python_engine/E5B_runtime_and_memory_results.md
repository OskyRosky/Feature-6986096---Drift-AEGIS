# E5B — Runtime & Memory Results

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

## Method
`run_refresh` wraps the pipeline in `time.time()` + `tracemalloc`. Per-phase
timing captured via the validation harness on the deterministic synthetic
fixture (12 keys / 15 versions, 2,208 forward rows, 85 signals). Real figures
from the E5A controlled sample are included for reference.

## Synthetic expanded (offline, seed 42)
| Phase | Shallow | Deep |
| --- | --- | --- |
| compute (families + composite + events) | 1.19 s | 1.77 s |
| full refresh (extract-synth + normalize + compute + checks + idempotency + export) | ~3.1 s | ~3.6 s |
| peak memory | ~1.3 MB | ~1.4 MB |
| signals | 85 | 85 |

## E5A real controlled sample (reference, 3 keys / 8 versions)
| Metric | Value |
| --- | --- |
| rows extracted → forward | 63,144 → 35,145 |
| signals / family rows / events | 18 / 72 / 8 |
| total runtime | 41.5 s (~24 s SQL scan + ~17 s compute/validate/idempotency) |
| peak memory | 48.7 MB |

## Bottlenecks & concrete actions (not prematurely optimized)
| Area | Observation | Action for full-history scale |
| --- | --- | --- |
| SQL scan | dominant in the real sample (~24 s of 41.5 s) | query pushdown: filter Scenario/Resource/ValueType server-side (already), add ForecastVersion ≥ cutoff; select only needed columns (done) |
| forward filter | cheap | keep vectorized boolean mask (done) |
| per-key Python loop | O(keys × versions × targets) pivot | vectorize pivot per key; consider groupby-apply; chunk keys and stream |
| deep Performance | inner-join per (key, version) | precompute one actuals frame per key; merge_asof / vectorized join; cache realized MAPE |
| dtypes | object dates cause coercion at join | store dates as `datetime64` end-to-end; category dtype for Key/Scenario/Resource |
| export | small | Parquet (columnar, smaller, typed) once pyarrow present; partition history by run date |
| memory | 48.7 MB at sample | monitor at full history; chunk by key ranges if peak grows |

## Output sizes (synthetic expanded, current/)
| File | Bytes |
| --- | --- |
| forecast_drift_signals.csv | 49,937 |
| forecast_drift_family_scores.csv | 37,607 |
| forecast_drift_event_history.csv | 1,603 |
| forecast_drift_runs.csv | 441 |
| metadata/run_metadata.json | 3,583 |

## Note
Full-history runtime/memory are **not** validated here (full history is not
authorized). The expanded live sample will provide the first real deep-mode
runtime/memory figures for capacity planning.
