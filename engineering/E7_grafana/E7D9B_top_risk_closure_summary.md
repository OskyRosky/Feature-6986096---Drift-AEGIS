# E7D.9B — Top Risk · Closure Summary

**Status token:** `E7D9B_TOP_RISK_DASHBOARD_COMPLETED_VISUALLY_ACCEPTED`
**Dashboard:** AEGIS Forecast Drift — Top Risk · UID `aegis-forecast-drift-top-keys` (preserved) · folder `afsjccp27s0e8d` · published version 5 (post-repair, visually accepted by Oscar 2026-07-20).

## What was built
The E7D.9A navigation shell was converted into a governed executive / operational Top Risk view. The 5 empty collapsed rows and the E7D.9B provisional note were removed and replaced with 15 analytical panels (16 incl. header) driven exclusively by the governed `forecast_drift_score` and `forecast_drift_family_scores`.

Panels: shared nav (1), executive header (2), KPI row — Forecast Keys Monitored / Average Drift Score / Critical Signals / Drift Events (10–13), Highest-Risk Forecast Key (14), Top Forecast Keys bar (20), Forecast Key Risk Summary table with drill-through (21), Top Regions bar (30), Top Forecast Versions bar (40), Top Drift Families bar (50), Drift Family Computability table (51), Risk Concentration Matrix (60), Consolidated Risk Details (70), Latest Governed Run (80), Data Quality stat (90).

## Estado por fase
| Fase | Estado |
|------|--------|
| 1 Precheck (git/docker/token/nginx) | ✅ |
| 2 Schema (served CSVs) | ✅ |
| 3 Ground truth | ✅ (matches baselines) |
| 4 Ranking contract | ✅ |
| 5 Filters (fv_label) | ✅ |
| 6 Layout | ✅ |
| 7 Components A–N | ✅ |
| 8 Drill-through | ✅ (3 links on Forecast Key) |
| 9 Gates A–K | ✅ (Gate A cardinality PASS) |
| 10 Reconciliation | ✅ (all diffs 0) |
| 11 Filter tests | ✅ (baselines; live clicks by Oscar) |
| 12 Visual | ✅ Oscar (2026-07-20) |
| 13 Publish | ✅ (version 5, post-repair) |
| 14 Artifacts | ✅ (8 docs) |

## Cardinalidad
signals 168 (168 distinct id); family_scores 672 (168 distinct id, 4/id); Risk Details 168. No signals×family_scores join. **Gate A PASS.**

## KPIs / Rankings / Reconciliación
Forecast Keys 12 · Avg 28.83 · Critical 14 · Events 71 · DQ 18/18. Highest-risk NAM-SDF 42.74. All rankings (key/region/version/family) and the Risk Matrix reconcile to CSV with zero diffs — see `E7D9B_top_risk_reconciliation.md`.

## Post-audit repair (published version 5, 2026-07-20)
A read-only audit (verdict `E7D9B_TOP_RISK_AUDIT_PARTIAL`) found that **id51 (Drift Family Computability)** and **id60 (Risk Concentration Matrix)** averaged family scores over **all** rows, letting non-computable (empty) scores enter the mean as **zero** — violating the governed rule *"empty family scores are excluded, never treated as zero"* (id51 Volatility rendered 48.03 instead of 56.04, Performance 7.16 instead of 7.71; matrix NAM-SDF Volatility 70.47 instead of 82.21). Root cause: a single `convertFieldType('' → number)` counted empties as 0 in `groupBy mean`; only id50 was correct because it pre-filtered `family_score != ''`.

Repair (Oscar-authorized), republished as **version 5**:
- **id51** — two queries joined by `drift_family` (`joinByField`, outer): query **A** filters `family_score != ''` → mean + max (computable only); query **B** uses all rows → `Σ is_comp` / `Σ is_noncomp`. Non-computables are counted, never averaged.
- **id60** — four independent queries (one per family), each carrying the five shared filters **plus** its own `<metric>_drift_score != ''` filter, converting only its own column, `groupBy forecast_key → mean`, then `joinByField forecast_key` (outer). Keys with no computable value show `null`, never 0; governed real zeros (CAN-GO LOCAL / JPN-GO LOCAL Performance) stay 0.00.

Live-verified (meta.version 5): id51 A/B universes 636/672; id60 metric universes performance 156 / shape 168 / stability 168 / volatility 144. Rendered values confirmed by Oscar: id51 Volatility 56.04 / Stability 38.93 / Shape 26.03 / Performance 7.71; matrix NAM-SDF 8.80/82.21, NAM-MULTITENANT Volatility 71.04.

## Files
- `V2/grafana/dashboards/aegis-forecast-drift-top-keys.json` — rebuilt analytical dashboard.
- `V2/grafana/dashboards/archive/aegis-forecast-drift-top-risk-shell-e7d9a.json` — archived E7D.9A shell (rollback).
- `V2/scripts/push-e7d9b-top-risk.ps1` — publish-only script (DPAPI in-memory, overwrite, UID preserved).
- `engineering/E7_grafana/E7D9B_top_risk_{requirements,schema_contract,ranking_contract,query_contract,reconciliation,filter_validation,visual_validation,closure_summary}.md`.

## Desviaciones (documentadas)
1. Per-key Dominant Drift Family omitted from the summary (14 versions/key; no groupBy mode) — shown per-signal + in the matrix.
2. Family panels honor Forecast Key + Forecast Version only (family_scores lacks region/status/run) — Region narrows via 1:1 key mapping.
3. Family bar colored by severity thresholds (AEGIS convention); brand colors in the computability table / matrix / details.

## Límites respetados
Only Top Risk + its artifacts touched. No change to any other dashboard, CSV, Python, PowerBI, datasource, nginx, Docker, token/DPAPI, MCP, weights or thresholds. No new dashboard, no UID change, no new risk score, no invented columns, no plugins/alerts/synthetic data, no manual commit.

## Riesgos / Próximo paso
Visual rendering confirmed by Oscar (2026-07-20); the id51/id60 null-handling repair is accepted. **Próximo paso: E7D.11 — Settings & Data Quality (requiere autorización de Oscar — aún no iniciar).** Detenerse antes de E7D.11.

## Autorización requerida
Concedida — Oscar aceptó visualmente el 2026-07-20; token promovido a `E7D9B_TOP_RISK_DASHBOARD_COMPLETED_VISUALLY_ACCEPTED`.
