# E3 — Open Decisions

**Feature 6986096 — AEGIS Forecast Drift Framework.**

## 1. Decisions closed in E3 (MVP recommendations)
- **Performance MVP formula:** MAPE relative-change with near-zero gate; **shallow** mode (`*_metrics`).
- **Shape MVP formula:** level-normalized weighted curve RMSE (uniform weights).
- **Stability MVP formula:** latest consecutive revision % + structural-break flag; per-key aggregate = max.
- **Volatility MVP formula:** coefficient of variation over **N = 6**, with MAD/median companion.
- **Normalization:** threshold-anchored piecewise-linear map to 0–100.
- **Composite:** weight-renormalization over available families (20/40/30/10 initial).
- **Missing-family policy:** renormalize + coverage% + confidence + missing flag.
- **Event logic:** create when FDS ≥ 40 or any family ≥ 70; persistence + cooldown rules.
- **Min versions:** Performance 2, Shape 2 (≥4 points), Stability 2 (≥3 cumulative), Volatility 4.
- **Metric roles:** MAPE primary; Accuracy/Bias_Pct/SMAPE secondary; MAE/RMSE/Bias diagnostic; TTL excluded v0.

## 2. Assumptions (to validate in E5)
- Anchors/gates/weights are placeholders; band populations not yet calibrated on real distributions.
- Uniform horizon weighting is adequate for MVP Shape (horizon decay available as config).
- `max` aggregation for Stability per key×version is the right sensitivity (vs 90th pct).

## 3. Deferred to E4 (physical schema)
- Physical types/nullability for every math field in section 12 of the model doc.
- Materialization of `cfg` tables (thresholds/weights/anchors) as governed config.
- Output columns of `aegis_forecast_drift_signals` including all derived fields.

## 4. Deferred to E5 (implementation + calibration)
- Encode formulas as SQL views/CTEs; validate against `E3_fixture_catalog.csv` within tolerances.
- Calibrate anchors/weights/thresholds on real drift distributions (open Q A5).
- Decide Performance **deep** recompute (G2) if 3-version shallow proves too shallow.
- Confirm event thresholds/cooldown with stakeholders (A5).

## 5. Still-open gaps (carried)
- G3 Service dimension, G4 region↔forest mapping, G7 TTL source — none block the math; they affect grouping/UX and optional TTL metric only.
