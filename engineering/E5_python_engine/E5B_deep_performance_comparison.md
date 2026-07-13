# E5B — Shallow vs Deep Performance Comparison (resolves I3 at design + prototype)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

## The two modes
| | **Shallow** (E5A) | **Deep** (E5B/I3) |
| --- | --- | --- |
| MAPE source | official `*_metrics` table | recomputed from forecasts + actuals |
| Version alignment | metric versions (≈3 retained) rarely match fact versions | aligned to fact-version grain |
| Coverage | sparse | deep (any version with realized actuals overlap) |
| Cost | ~0 (read a column) | one inner-join + mean per (key, version) |
| Comparison | E3 `performance_drift(MAPE_n, MAPE_prev)` | **same** E3 function — only the MAPE source changes |

Both modes feed the identical E3 relative-MAPE + gate comparison, so scores stay
methodologically consistent; deep only deepens *coverage*.

## Interface
`compute_signals(..., perf_mode="shallow"|"deep", actuals=<df>)`. The mode is
explicit and recorded per signal in `performance_mode` (lineage). The productive
mode is never changed silently. `run_refresh --perf-mode {shallow,deep}`.

## Deep recompute definition
For a `(canonical key, forecast_version)`: inner-join forward forecast rows to
realized actuals on target date; `MAPE = mean(|actual − forecast| / |actual|)`
over actuals with `|actual| ≥ EPS`. Performance drift = compare this version's
MAPE to the previous version's MAPE.

## Prototype result (deterministic synthetic fixture, seed 42, 12 keys / 15 versions)
| Family | Shallow computed | Deep computed |
| --- | --- | --- |
| performance | **13 / 85** | **78 / 85** |
| shape | 85 / 85 | 85 / 85 |
| stability | 85 / 85 | 85 / 85 |
| volatility | 72 / 85 | 72 / 85 |

Status distribution shift (expected — deeper Performance changes the composite):
- shallow: Healthy 58 · Watch 19 · Warning 4 · Critical 4
- deep: Healthy 64 · Watch 14 · Warning 4 · Critical 3

## Discrepancies / caveats
- Deep MAPE only exists where actuals have been **realized** for a version's
  forward targets; the most recent versions (few realized months) stay
  NOT_COMPUTABLE (`NO_REALIZED_OVERLAP`) — expected and correct.
- Deep is heavier (join per key×version). At sample scale negligible (+0.5 s);
  at full history this must be profiled and possibly vectorized/chunked.
- Deep and shallow can disagree because the official metric table uses its own
  (unknown) accuracy definition; deep uses an explicit, auditable MAPE. This is
  a **documented** difference, surfaced via `performance_mode`, not a silent swap.

## Live confirmation (2026-07-13)
On the real Enterprise/HDD sample (12 keys, 15 versions), deep mode produced
**Performance coverage 156/168** signals (shape 168/168, stability 168/168,
volatility 144/168) — confirming that deep recompute lifts Performance coverage
substantially on real data, aligned to fact versions. Both live runs produced
identical record hashes (idempotent). `performance_mode=deep` recorded on every
signal.
