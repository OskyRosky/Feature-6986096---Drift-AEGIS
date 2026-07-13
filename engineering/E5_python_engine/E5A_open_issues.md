# E5A — Open Issues

**Feature 6986096 — AEGIS Forecast Drift Framework.**

## 1. Non-blocking issues found (engine works)
| # | Issue | Impact | Fix (E5B) |
| --- | --- | --- | --- |
| I1 | **Key case variants** in the fact table (`CAN-GO LOCAL` vs `CAN-Go Local`) create duplicate logical keys | inflates distinct keys; splits a key's history | case-fold keys during normalization |
| I2 | **Console logging UnicodeEncodeError** on the U+2011 hyphen in the project path (cp1252 console) | cosmetic only — outputs written fine, run completes | log to UTF-8 file / avoid printing full path |
| I3 | **Performance NOT_COMPUTABLE** at most fact-version rows (official metric versions don't align to fact versions) | Performance sparse in the sample (6/18) | E5B: deep-recompute MAPE from forecasts+actuals (G2) to align to fact-version grain |
| I4 | **Volatility NOT_COMPUTABLE** where <4 versions per (key,target) | expected for shallow windows | more versions per key improves coverage |

## 2. E3 reconciliation
- Confidence band: E3 config CSV had `confidence_high_coverage=100`, but E3 fixture FX-COMP-02 (90%) expected HIGH. Engine uses **HIGH ≥ 90** so fixture and engine agree. Recommend correcting the E3 config value to 90 (or the fixture) in a future pass.

## 3. Environment
- **pyarrow not installed** → Parquet not produced; CSV is the working contract. Install pyarrow in E5B to emit Parquet.
- **pytest not installed** → fixtures run via the standalone runner.

## 4. Carried gaps (E1/E2)
- G3 Service dimension (nullable), G4 region↔forest mapping, G7 TTL — not required for the engine; affect grouping/UX only.

## 5. Deferred (need authorization)
- Full-history run; anchor/weight/threshold calibration on real distributions; Performance deep mode; writing to SQL tables/views (E5B / later).
