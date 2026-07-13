# E3 — Forecast Drift Mathematical Model

**Feature 6986096 — AEGIS Forecast Drift Framework**
**Stage:** E3 — Mathematical Drift Model (mathematics + fixtures only)
**Date:** 2026-07-12
**Basis:** E1A/E1B evidence + E2 information model + Blueprint V2 + Prototype. **No** productive SQL, Power BI, Grafana; **no** E4; **no** data mutation; **no** commit. Only synthetic examples — no confidential data.

---

## 1. Context

E2 fixed the structure (entities, grain, lineage). E3 turns that structure into **explainable, reproducible, SQL-implementable formulas** for the four families and the composite score. Every formula is scale-invariant (works across keys of very different magnitude), bounded to `[0,100]`, and driven by **configurable** parameters (no magic constants baked into logic).

## 2. Notation

- $k$ = key, $s$ = scenario, $t$ = target date, $v$ = forecast version (ordered by `version_rank`; $v_n$ current, $v_{n-1}$ previous).
- $F_v(t)$ = forecast value for target $t$ produced by version $v$. $A(t)$ = actual value.
- $h = t - v$ = horizon (days). **Forward** iff $h \ge 0$.
- $\varepsilon$ = small epsilon (default $10^{-6}$) to guard division.
- $m_v$ = an accuracy metric (MAPE, Accuracy, …) at version $v$.

**Global rules (from E2):** dedupe ForecastVersion `2025-06-01`; forward-only ($t \ge v$); consecutive pairing by `version_rank`; MVP scope = Enterprise / region grain / HDD.

## 3. Common normalization to 0–100 (chosen method)

**Decision:** **threshold-anchored piecewise-linear mapping**. A family produces a scale-invariant raw magnitude $r \ge 0$; it is mapped to `[0,100]` through four configurable anchors $(a_{20}, a_{40}, a_{70}, a_{100})$ aligned to the severity bands:

$$
\text{score}(r) = \operatorname{clamp}_{[0,100]}\!\begin{cases}
20\cdot \dfrac{r}{a_{20}} & 0 \le r < a_{20}\\[6pt]
20 + 20\cdot \dfrac{r-a_{20}}{a_{40}-a_{20}} & a_{20} \le r < a_{40}\\[6pt]
40 + 30\cdot \dfrac{r-a_{40}}{a_{70}-a_{40}} & a_{40} \le r < a_{70}\\[6pt]
70 + 30\cdot \dfrac{r-a_{70}}{a_{100}-a_{70}} & a_{70} \le r \le a_{100}\\[6pt]
100 & r > a_{100}
\end{cases}
$$

**Why this over alternatives:** min-max / z-score / percentile / robust-scaling all need a **population distribution** → not reproducible per-row, inconsistent between Power BI and Grafana, and outlier-sensitive. Logistic is smooth but needs parameter fitting and is harder to explain/calibrate. Piecewise-linear is **explainable** (a broken line), **configurable** (4 anchors in `cfg`), **reproducible** (row-local), **outlier-resistant** (clamped at 100), **SQL-trivial** (`CASE` + linear interpolation), and **identical** across tools. Anchors are initial and pending calibration (open Q A5).

---

## 4. Performance Drift

**Question:** is forecast quality deteriorating across versions?

**Metric classification (not all enter the score):**
- **Primary (drives score):** `MAPE` (lower-better, scale-invariant).
- **Secondary (explanatory):** `Accuracy` (higher-better), `Bias_Pct` (direction), `SMAPE`.
- **Diagnostic (context only):** `MAE`, `RMSE`, raw `Bias`, `Mean_Actual`, `Mean_Forecast`, `Count`.
- **TTL:** excluded from Drift Score v0 (source not validated — E1B G7); revisit if A6 confirms.

**Definitions** (consecutive metric versions $m_{n-1}\to m_n$):

$$\Delta = m_n - m_{n-1}, \qquad \Delta\% = \frac{m_n - m_{n-1}}{\max(|m_{n-1}|,\varepsilon)}$$

Direction (unfavorable = deterioration): lower-better metric → unfavorable if $\Delta>0$; higher-better (`Accuracy`) → unfavorable if $\Delta<0$. Drift scores **only unfavorable** movement (improvement ⇒ 0).

**Near-zero gate:** require $|\Delta| \ge \delta_{\min}$ (config `perf_min_abs_delta`, default 0.02 for MAPE) else raw = 0.

**Raw magnitude & score:**
$$ r_{\text{perf}} = \begin{cases} \max(0,\ \operatorname{sign\_unfav}\cdot \Delta\%) & |\Delta|\ge\delta_{\min}\\ 0 & \text{otherwise}\end{cases}, \qquad P = \text{score}(r_{\text{perf}};\,a^{P})$$

Anchors $a^{P} = (0.10,\ 0.25,\ 0.50,\ 1.00)$.

**Modes:** *shallow* (use `*_metrics`, 2–3 versions — **MVP recommended**, governed & simple) vs *deep* (recompute MAPE/Bias/Accuracy from `fact_forecast_values`+`fact_actual_values` for full 48-version depth — deferred enhancement). **Min versions = 2.**

**Worked example (fixture MAPE 0.44 → 0.45 → 0.70):**
- Step 1 (0.44→0.45): $\Delta=0.01 < \delta_{\min}=0.02$ ⇒ $r=0$ ⇒ **P = 0 (Healthy)**.
- Step 2 (0.45→0.70): $\Delta=0.25\ge0.02$, $\Delta\%=0.25/0.45=0.5556$; $r=0.5556\in[a_{70},a_{100}]$ ⇒ $P=70+30\cdot\frac{0.5556-0.50}{1.00-0.50}=73.3$ ⇒ **Critical**.
- Explanation: *"MAPE rose 0.45 → 0.70 (+55.6%) between versions — forecast accuracy deteriorating. Performance drift 73 (Critical)."*

---

## 5. Shape Drift

**Question:** has the forecast **trajectory** changed between consecutive versions?

Align both versions on the overlap of **forward** target dates $T = \{t : t\ge v_n,\ F_{n-1}(t),F_{n}(t)\ \text{exist}\}$, $|T|\ge P_{\min}$ (config `shape_min_points`, default 4).

**Method chosen (principal):** **level-normalized weighted RMSE of the curve difference** (relative curve RMSE):

$$ L = \max\!\Big(\tfrac{1}{|T|}\textstyle\sum_{t\in T}|F_{n-1}(t)|,\ \varepsilon\Big), \qquad
r_{\text{shape}} = \frac{\sqrt{\dfrac{\sum_{t\in T} w_t\,(F_n(t)-F_{n-1}(t))^2}{\sum_{t\in T} w_t}}}{L} $$

with weights $w_t=1$ (uniform, MVP) or optional horizon decay $w_t=1/(1+h_t/H_0)$ (config `shape_horizon_weighting`, default off). $S=\text{score}(r_{\text{shape}};a^{S})$, anchors $a^{S}=(0.05,0.10,0.20,0.40)$.

**Why relative RMSE:** scale-invariant (divided by curve level), symmetric, penalizes divergence anywhere on the curve, robust (clamped), trivially SQL-aggregable. `slope_change`, `endpoint_divergence`, `cosine`, `area-between-curves` kept as **secondary/explanatory** (not the score) — they either duplicate RMSE information or are less stable near zero.

**Secondary/explanatory fields:** `max_curve_delta`, `curve_delta_pct`, `divergence_start_date` (first $t$ with relative point diff $>$ `shape_div_pct`, default 5%), `slope_change`.

**Worked example (A = 100,105,110,115 ; B = 100,108,130,165):**
- diffs $0,3,20,50$; squared $0,9,400,2500$; mean $727.25$; RMSE $=26.97$; $L=107.5$; $r=26.97/107.5=0.2509$.
- $r\in[a_{70},a_{100}]$ ⇒ $S=70+30\cdot\frac{0.2509-0.20}{0.40-0.20}=77.6$ ⇒ **Critical**.
- `max_curve_delta`=50, `curve_delta_pct`=50/115=43.5%, `divergence_start` = 3rd target (first point >5%), slope A→B 5→21.7 (4.3×).
- Explanation: *"Forecast trajectory diverged from the prior version (relative curve RMSE 25%); largest change +50 (+43%) at the far horizon; divergence begins at point 3. Shape drift 78 (Critical)."*

---

## 6. Stability Drift

**Question:** for the same `key + scenario + target_date`, is the value changing across versions?

Forward-only ($t \ge v_n$). Series of forward values $F_{v_1}(t),\dots,F_{v_n}(t)$.

**Definitions:**
$$\text{value\_delta} = F_{v_n}(t)-F_{v_{n-1}}(t),\quad \text{value\_delta\_pct}=\frac{F_{v_n}(t)-F_{v_{n-1}}(t)}{\max(|F_{v_{n-1}}(t)|,\varepsilon)}$$
$$\text{cumulative\_revision\_pct}=\frac{F_{v_n}(t)-F_{v_1}(t)}{\max(|F_{v_1}(t)|,\varepsilon)}$$

**Principal (score):** latest consecutive revision magnitude $r_{\text{stab}}=|\text{value\_delta\_pct}|$ (most actionable). **Secondary:** cumulative revision. **Structural break** flag if $r_{\text{stab}} \ge$ `stab_jump_pct` (default 0.15). Near-zero base guarded by $\varepsilon$ + `stab_min_abs`.

$S_{t}=\text{score}(r_{\text{stab}};a^{St})$, anchors $a^{St}=(0.03,0.07,0.15,0.40)$. Aggregate per key×version = max (or 90th pct) over targets (config `stab_agg`, default max). **Min versions = 2** (latest revision); ≥3 for cumulative.

**Worked example (fixture 120, 122, 121, 156):**
- revisions: 120→122 (+1.7%), 122→121 (−0.8%), **121→156 (+35, +28.9%)**.
- $r_{\text{stab}}=0.2893\in[a_{70},a_{100}]$ ⇒ $S=70+30\cdot\frac{0.2893-0.15}{0.40-0.15}=86.7$ ⇒ **Critical**; structural break = TRUE; cumulative +30%.
- Explanation: *"Target revised 121 → 156 (+28.9%) in the latest version; cumulative +30% vs first version; structural break. Stability drift 87 (Critical)."*

---

## 7. Volatility Drift

**Question:** is the forecast becoming unstable/noisy across versions for the same `key + target_date`?

Forward-only rolling window of last $N$ versions (config `vol_window_N`, **default 6**). Values $x_1,\dots,x_N$.

**Method chosen (principal):** **coefficient of variation** $\text{CoV}=\dfrac{\operatorname{std}_{\text{sample}}(x)}{\max(|\bar x|,\varepsilon)}$ — scale-invariant, standard, `STDEV/AVG` in SQL, catches spikes (intended). **Companions:** `mad_over_median` (robust, reveals single-outlier vs sustained), `mean_abs_revision`, `sign_change_freq`. $V=\text{score}(\text{CoV};a^{V})$, anchors $a^{V}=(0.03,0.07,0.15,0.30)$. **Min versions = 4.** Near-zero mean guarded; optional winsorize (config `vol_winsorize`, default off).

**Classification:** `stable` (CoV < a20), `variable` (a20 ≤ CoV < a70), `erratic` (CoV ≥ a70). Add `single_spike` qualifier when CoV high but `mad_over_median` low.

**Worked example (fixture 100,102,101,99,101,160):**
- $\bar x=110.5$; sample std $=24.27$; **CoV $=0.2197$** (22%). $V=70+30\cdot\frac{0.2197-0.15}{0.30-0.15}=83.9$ ⇒ **Critical (erratic)**.
- Companions: `mean_abs_revision`=13.2 (11.9% of level), `sign_change_freq`=0.5, `mad_over_median`=1/101=1.0% ⇒ **single_spike** (driven by the 160 jump, not sustained noise).
- Explanation: *"Forecast oscillated across the last 6 versions (CoV 22%), driven by a spike to 160; robust MAD 1% ⇒ single-spike volatility. Volatility drift 84 (Critical, single-spike)."*

---

## 8. Composite Forecast Drift Score

$$\text{FDS} = \frac{\sum_{f\in\mathcal{A}} w_f \cdot \text{score}_f}{\sum_{f\in\mathcal{A}} w_f}, \qquad \mathcal{A} = \text{available families}$$

Initial weights (config): Performance 0.20, Shape 0.40, Stability 0.30, Volatility 0.10.

**Missing-family policy:** renormalize over available weights (formula above). Derived:
- `score_coverage_pct` $= 100\cdot \sum_{\mathcal A} w_f / \sum_{\text{all}} w_f$.
- `confidence` = HIGH (coverage 100%), MEDIUM (≥60%), LOW (<60%) — config `conf_bands`.
- `dominant_drift_family` $=\arg\max_{f\in\mathcal A} (w_f\cdot\text{score}_f)$ → becomes `drift_type`.
- `contributing_family` = families with weighted contribution ≥ `contrib_min` (default 15% of FDS).
- `missing_family_flag` = list of families in `NOT_COMPUTABLE`.

**Worked composite (all four fixtures present, P=73.3, S=77.6, St=86.7, V=83.9):**
$\text{FDS}=0.2(73.3)+0.4(77.6)+0.3(86.7)+0.1(83.9)=80.1$ ⇒ **Critical**; dominant = **Shape** (contribution 31.0); coverage 100%; confidence HIGH.

---

## 9. Thresholds & event logic

**Bands (inclusive-lower, exclusive-upper; top inclusive):** Healthy $[0,20)$, Watch $[20,40)$, Warning $[40,70)$, Critical $[70,100]$.

- **Drift Status** = band of `forecast_drift_score` (informational, stored for every key×version).
- **Severity** = escalation attached to an **event**, materialized only when an event is created.
- **Event creation:** create a Forecast Drift Event when `forecast_drift_score` ≥ `event_threshold` (default 40 = Warning+) **or** any family score ≥ `family_event_threshold` (default 70). Healthy/Watch ⇒ status stored, **no event row**.
- **Persistence:** `persistence` = consecutive versions with status ≥ Warning; `single_spike` if 1, `sustained` if ≥ `persistence_min` (default 2) → escalate severity.
- **Cooldown/suppression:** suppress a duplicate event for the same `(key,scenario,drift_type)` within `cooldown_versions` (default 1) unless severity increases.

All thresholds/weights are governed & configurable (`cfg_drift_thresholds`, `cfg_drift_weights`, and `E3_threshold_and_normalization_config.csv`).

## 10. Eligibility rules (per family) — see also `E3_formula_catalog.csv`

| Family | Min versions | Other eligibility | NOT_COMPUTABLE when |
| --- | --- | --- | --- |
| Performance | 2 metric versions | metric not null; near-zero gate | <2 versions, all null |
| Shape | 2 | ≥4 overlapping forward points; $L\ge\varepsilon$ | <2 versions or <4 points |
| Stability | 2 (≥3 for cumulative) | forward-only; base ≥ `stab_min_abs` | past target only, <2 versions |
| Volatility | 4 | forward-only; mean ≥ $\varepsilon$ | <4 versions, mean≈0 |
| Composite | ≥1 family computable | — | all families NOT_COMPUTABLE |

Common: dedupe applied first; NULLs excluded; div-by-zero → $\varepsilon$ guard or NOT_COMPUTABLE; constant series → score 0 (Healthy), not NULL.

## 11. Selected MVP decisions
- Performance MVP = **MAPE relative-change**, shallow mode.
- Shape MVP = **level-normalized weighted RMSE** (uniform weights).
- Stability MVP = **latest revision %** (structural-break flag).
- Volatility MVP = **CoV** over **N=6** (+ MAD companion).
- Normalization = **piecewise-linear anchored to bands**.
- Composite = **weight-renormalized** over available families (20/40/30/10).
- Event when FDS ≥ 40 or any family ≥ 70; suppression + persistence rules as above.

## 12. Mathematical fields handed to E4
`metric_name, metric_value, previous_metric_value, metric_delta, metric_delta_pct` (Perf); `shape_raw_distance, shape_max_delta, shape_delta_pct, divergence_start_date` (Shape); `value_delta, value_delta_pct, cumulative_revision_pct, structural_break_flag` (Stability); `cov, mad_over_median, mean_abs_revision, sign_change_freq, volatility_class` (Volatility); `performance_score, shape_score, stability_score, volatility_score, forecast_drift_score, drift_status, severity, dominant_drift_family, contributing_family, score_coverage_pct, confidence, missing_family_flag, persistence, single_spike_flag, explanation`. All bounded/typed; anchors/weights/thresholds come from cfg.

## 13. Limitations & assumptions
- Anchors/weights/thresholds are **initial**, pending calibration on real drift distributions (A5).
- Performance shallow mode limited to ~3 metric versions (deep recompute deferred).
- CoV is intentionally outlier-sensitive; MAD companion mitigates interpretation.
- Near-zero bases handled by $\varepsilon$ + min-abs gates; a true 0→positive change yields NOT_COMPUTABLE percent (fallback to absolute or flagged).
- Version "consecutive" = by `version_rank`, not calendar (gaps allowed).
- No real confidential data used; all examples synthetic.
