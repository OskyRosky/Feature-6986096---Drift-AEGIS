# E3 — Mathematical Spec (engineer-facing)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Condensed, implementation-ready formulas. All parameters resolve from `E3_threshold_and_normalization_config.csv`. Reference math + worked examples: `E3_forecast_drift_mathematical_model.md`.

## Common
```
eps = 1e-6
piecewise(r, a20, a40, a70, a100):
    if r <= 0: return 0
    if r <  a20:  return clamp(20 * r/a20)
    if r <  a40:  return clamp(20 + 20*(r-a20)/(a40-a20))
    if r <  a70:  return clamp(40 + 30*(r-a40)/(a70-a40))
    if r <= a100: return clamp(70 + 30*(r-a70)/(a100-a70))
    return 100
```
Global preconditions (from E2): dedupe FV 2025-06-01; forward-only t>=v; pair versions by version_rank; MVP scope Enterprise / region / HDD.

## Performance (primary metric = MAPE, lower-better; mode = shallow)
```
delta      = m_n - m_prev
delta_pct  = (m_n - m_prev)/max(abs(m_prev), eps)
if abs(delta) < perf_min_abs_delta: r_perf = 0
else: r_perf = max(0, dir_unfav*delta_pct)      # dir_unfav=+1 lower-better, -1 higher-better(Accuracy)
performance_score = piecewise(r_perf, aP=0.10,0.25,0.50,1.00)
eligible: >=2 metric versions
```

## Shape (primary = level-normalized weighted curve RMSE)
```
T = forward target dates present in BOTH versions;  require |T| >= shape_min_points(4)
L = max(mean_{t in T} abs(F_prev(t)), eps)
r_shape = sqrt( sum_t w_t*(F_n(t)-F_prev(t))^2 / sum_t w_t ) / L      # w_t=1 (MVP)
shape_score = piecewise(r_shape, aS=0.05,0.10,0.20,0.40)
secondary: shape_max_delta, shape_delta_pct, divergence_start_date (first |rel diff|>0.05)
```

## Stability (primary = latest revision %)
```
value_delta      = F_vn(t) - F_v(n-1)(t)
value_delta_pct  = value_delta / max(abs(F_v(n-1)(t)), eps)          # base>=stab_min_abs else NOT_COMPUTABLE
stability_score  = piecewise(abs(value_delta_pct), aSt=0.03,0.07,0.15,0.40)
structural_break = abs(value_delta_pct) >= stab_jump_pct(0.15)
cumulative_revision_pct = (F_vn - F_v1)/max(abs(F_v1), eps)          # needs >=3 versions
aggregate per key x version: stability_score_key = max_t stability_score(t)
eligible: >=2 forward versions for the target
```

## Volatility (primary = CoV over last N versions)
```
x = last vol_window_N(6) forward values for (key, target)
cov = stdev_sample(x)/max(abs(mean(x)), eps)
volatility_score = piecewise(cov, aV=0.03,0.07,0.15,0.30)
companions: mad_over_median, mean_abs_revision, sign_change_freq
class: stable(cov<a20) / variable(a20..a70) / erratic(>=a70); +single_spike if mad_over_median low
eligible: >=4 forward versions; mean>=eps
```

## Composite + event
```
A = available families
FDS = sum_{f in A} w_f*score_f / sum_{f in A} w_f      # w = 0.20/0.40/0.30/0.10
score_coverage_pct = 100 * sum(w in A)/sum(w all)
confidence = HIGH(cov=100)/MEDIUM(>=60)/LOW(<60)
dominant_drift_family = argmax_{f in A}(w_f*score_f)   # -> drift_type
drift_status: Healthy[0,20) Watch[20,40) Warning[40,70) Critical[70,100]
create_event = FDS >= event_threshold(40) OR any score_f >= family_event_threshold(70)
persistence = consecutive versions with status>=Warning; single_spike if 1, sustained if >=2
suppress duplicate (key,scenario,drift_type) within cooldown_versions(1) unless severity increases
```

## Eligibility / NOT_COMPUTABLE (all families)
```
dedupe first; drop NULLs; div-by-zero -> eps guard or NOT_COMPUTABLE;
constant series -> score 0 (Healthy); below min versions/points -> NOT_COMPUTABLE with reason.
```
