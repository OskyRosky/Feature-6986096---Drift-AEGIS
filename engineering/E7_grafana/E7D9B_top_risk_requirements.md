# E7D.9B — Top Risk Dashboard · Requirements

**Status token:** `E7D9B_TOP_RISK_DASHBOARD_COMPLETED_VISUALLY_ACCEPTED` (published version 5, visually accepted by Oscar 2026-07-20)
**Dashboard:** AEGIS Forecast Drift — Top Risk · UID `aegis-forecast-drift-top-keys` (preserved) · `/d/aegis-forecast-drift-top-keys`
**Scope:** analytical content only. Navigation shell from E7D.9A retained; no changes to any other dashboard, CSV, datasource, nginx, Docker, weights or thresholds.

## Objective
Convert the E7D.9A navigation shell into a governed executive / operational view that answers:

| # | Question | Panel(s) |
|---|----------|----------|
| 1 | Which Forecast Keys concentrate the most risk? | Top Forecast Keys (id20), Forecast Key Risk Summary (id21) |
| 2 | Which Regions concentrate risk? | Top Regions (id30) |
| 3 | Which Forecast Versions concentrate risk? | Top Forecast Versions (id40) |
| 4 | Which Drift Families dominate? | Top Drift Families (id50), Drift Family Computability (id51) |
| 5 | Where do Critical + Warning concentrate? | Forecast Key Risk Summary (id21), KPI Critical Signals (id12) |
| 6 | Worst Key + Region + Version combination? | Highest-Risk Forecast Key (id14), Risk Details (id70) |
| 7 | Dominant family per signal? | Consolidated Risk Details (id70), Risk Matrix (id60) |
| 8 | Governed explanation for the highest-risk signals? | Consolidated Risk Details — Explanation column (id70) |
| 9 | Which filters change the ranking? | Shared template variables (all panels react) |
| 10 | Navigation to Forecast / Events / Historical Timeline? | Data links on Forecast Key (id21) + shared nav (id1) |

## Data principles (mandatory)
- Primary ranking metric = existing governed `forecast_drift_score`. **No new risk score.** No recompute of the 20/40/30/10 family weights.
- Family rankings use the governed `forecast_drift_family_scores` **standalone** (aggregated independently), never joined-then-counted against signals.
- CSV is the sole source of truth (served `V2/data/processed/current/*.csv`).
- Nulls are **excluded**, never coerced to zero.
- Every aggregated metric documents numerator / denominator / aggregation / filtered universe (see ranking + query contracts).
- No invented Scenario / Service / Owner / Business Impact / Mitigation columns.

## Cardinality gate (hard stop)
`signals` = 168 rows (168 distinct `drift_event_id`). `family_scores` = 672 rows (168 × exactly 4 families). Any panel combining with `family_scores` must keep exactly one row per signal. If a signals-based panel exceeds 168 the ranking is contaminated — **stop before publishing.** Gate result: **PASS** (see reconciliation).

## Deviations (documented, accepted)
- **Per-key Dominant Drift Family** omitted from the Forecast Key Risk Summary: a key spans 14 forecast versions with differing dominant families and `groupBy` has no mode aggregation. Dominant family is shown per-signal in Consolidated Risk Details and decomposed in the Risk Matrix.
- **Family panels (id50/id51)** honor the Forecast Key and Forecast Version filters only. `forecast_drift_family_scores.csv` has no `region` / `drift_status` / `calculation_run_id` columns. Region is 1:1 with Forecast Key, so key selection still narrows region.
- **Family bar coloring** uses the AEGIS severity thresholds (20/40/70) consistent with every other score bar; the family brand colors appear in the Computability table, Risk Matrix and Risk Details.
