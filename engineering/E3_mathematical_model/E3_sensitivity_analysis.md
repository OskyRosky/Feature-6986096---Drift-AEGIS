# E3 — Sensitivity Analysis

**Feature 6986096 — AEGIS Forecast Drift Framework.** Behavior of the MVP formulas under stress. Synthetic inputs only.

## 1. Response curve (all families use the same anchored piecewise map)
| Regime | Raw magnitude r | Score behavior | Status |
| --- | --- | --- | --- |
| Small change | r < a20 | linear from 0, near-Healthy | Healthy |
| Moderate | a20 ≤ r < a70 | rises to ~70 | Watch/Warning |
| Large | a70 ≤ r ≤ a100 | 70 → 100 | Critical |
| Extreme | r > a100 | **clamped at 100** (no blow-up) | Critical |

Monotonic, bounded, continuous — desirable. No overflow because of the clamp.

## 2. Edge cases

| Case | Family effect | Handling | Residual risk |
| --- | --- | --- | --- |
| Zero / near-zero base | Stability/Performance % explodes | eps guard + min-abs gate → raw 0 or NOT_COMPUTABLE | true 0→positive change yields no percent; fallback to absolute or flag |
| Very high scale keys | none (all metrics relative) | pct / level normalization is scale-invariant | none |
| Few versions | family drops out | eligibility → NOT_COMPUTABLE; composite renormalizes | lower coverage/confidence |
| Missing versions (gaps) | pairing shifts | pairing by version_rank, not calendar | "consecutive" spans a time gap — documented |
| Single outlier | Volatility CoV inflates (intended) | MAD companion + single_spike flag distinguishes | CoV alone could over-alert → mitigated by companion |
| Persistent drift | sustained escalation | persistence counter ≥ persistence_min | none |
| Constant series | zero variation | score 0 (Healthy), not NULL | none |
| Duplicate rows (2025-06-01) | double counting | dedupe in normalization layer | none if dedupe enforced |

## 3. Fixture stress confirmation
- Performance 0.44→0.45 (small) ⇒ **0 Healthy**; 0.45→0.70 (large) ⇒ **73 Critical**. Gate correctly suppresses the trivial step.
- Shape A vs B (big trajectory change) ⇒ **78 Critical**; a hypothetical A vs A (identical) ⇒ r=0 ⇒ **0 Healthy**.
- Stability 120,122,121 (quiet) ⇒ latest revisions <1% ⇒ Healthy; +156 jump ⇒ **87 Critical** + structural_break.
- Volatility 100,102,101,99,101 (quiet) ⇒ CoV≈1.2% ⇒ Healthy; +160 ⇒ **84 Critical** but MAD flags single_spike.

## 4. Undesired behaviors found (and mitigations)
1. **MAPE relative change near zero** (0.01→0.02 = +100%): mitigated by `perf_min_abs_delta` gate.
2. **CoV over-sensitivity to one spike**: mitigated by `mad_over_median` companion + `single_spike` qualifier (informs, does not silently down-weight).
3. **Stability % on tiny base**: mitigated by `stab_min_abs`.
4. **Anchor cliff near a100**: values just above a100 all map to 100 (loss of resolution at the extreme) — acceptable for MVP (all "very bad"), revisit if fine-grained Critical ranking is needed.

## 5. Calibration note
All anchors/gates/weights are **initial**. Recommended E3→E5 calibration: compute the empirical distribution of each raw magnitude across real versions and set a20/a40/a70/a100 to sensible percentiles so band populations are meaningful (open Q A5). No calibration was performed on real data in E3 (design stage).
