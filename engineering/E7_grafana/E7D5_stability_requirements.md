# E7D.5 — Stability MVP · Requirements

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-stability` · 2026-07-19
Reference: Power BI V1 *Stability* page, adapted to Grafana + the governed read-only **V2** CSV snapshot.
Structural pattern mirrors the accepted E7D.4 *Shape* dashboard (same 10-panel layout).

## Questions the dashboard must answer
1. What is the **average Stability Drift Score**?
2. How many signals have **computable Stability**?
3. What is the **Stability coverage**?
4. How does **Stability drift evolve over time**?
5. Which **Forecast Keys / versions** show the largest stability change?
6. Which signals reach **Warning / Critical**?
7. What was the **latest governed run**?
8. What is the **Data Quality** status?

## Governing principle
The dashboard does **not** cook data. All stability math (cumulative-revision / structural-break behavior →
`stability_drift_score`, 0–100 normalization, status banding, governance) is produced by the V1 Python engine
and frozen in the V2 snapshot. Grafana only **reads**, **filters** (shared filter contract) and **aggregates**.
**No value is hardcoded** — every KPI reduces the datasource at render time.

## Baselines (Power BI V1, validated against CSV)
| Metric | CSV (validated) |
|--------|----------------:|
| Average Stability Drift Score | **38.93** ✅ |
| Stability Signals Computable | **168** ✅ |
| Stability Coverage | **100.0 %** ✅ |
| Maximum Stability Drift Score | **100.00** |

## Scope decisions
- **Stability is fully computable** (168/168; 0 non-computable; family scores 168 COMPUTED / 0 NOT_COMPUTABLE).
  Therefore the **Non-computable Summary panel is intentionally omitted** (no empty panel); the Signal Details
  table is widened to full width — identical treatment to the accepted Shape dashboard.
- `forecast_drift_signals.csv` exposes a **single** governed stability metric (`stability_drift_score`). The
  richer stability auxiliaries in `forecast_drift_family_scores.csv` (`structural_break_flag` 168/168,
  `cumulative_revision_pct` 52/168, `version_count` 168/168) are **populated but NOT integrated into this MVP**:
  the MVP keeps a single-source (signals.csv) design mirroring Shape. They are recorded as a **future
  enhancement** option, not built now. The other stability aux columns (`rolling_stddev`, `cov`, `mad`,
  `oscillation`, `sign_change_freq`) are **empty (0/168)** — those belong to the Volatility family (E7D.6).
- The details table therefore carries **no** Current/Previous auxiliary columns and there is **no** MAPE-equivalent
  KPI. The 4th KPI slot is filled by **Maximum Stability Drift Score** (clearly computable, adds analytical value).
- Stability family governed weight = **30 %** (documented in the header).

## Components (10 panels)
2 text (nav + header) · **A** Average Stability Drift Score · **B** Stability Signals Computable · **C** Stability
Coverage · **D** Maximum Stability Drift Score · **E** Stability Drift Score Over Time · **F** Stability Signal
Details · **H** Latest Governed Run · **I** Data Quality — Checks Passed.

## Out of scope
Volatility, Events, Historical Timeline, Top Forecast Keys, Top Scenarios, Settings & Data Quality (later E7D
stages). No changes to Overview / Forecast / Performance / **Shape**, CSV, Python, Power BI, datasource, nginx,
Docker, token, DPAPI, MCP, weights, thresholds. No plugins, no alerts, no deletes, no manual commit.
