# E7D.4 — Shape MVP · Requirements

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-shape` · 2026-07-19
Reference: Power BI V1 *Shape* page, adapted to Grafana + the governed read-only **V2** CSV snapshot.

## Questions the dashboard must answer
1. What is the **average Shape Drift Score**?
2. How many signals have **computable Shape**?
3. What is the **Shape coverage**?
4. How does **Shape drift evolve over time**?
5. Which **Forecast Keys / versions** show the largest trajectory change?
6. Which signals reach **Warning / Critical**?
7. What was the **latest governed run**?
8. What is the **Data Quality** status?

## Governing principle
The dashboard does **not** cook data. All shape math (curve/profile divergence → `shape_drift_score`,
0–100 normalization, status banding, governance) is produced by the V1 Python engine and frozen in the V2
snapshot. Grafana only **reads**, **filters** (shared filter contract) and **aggregates**. **No value is
hardcoded** — every KPI reduces the datasource at render time.

## Baselines (Power BI V1, validated against CSV)
| Metric | PBI reference | CSV (validated) |
|--------|--------------:|----------------:|
| Average Shape Drift Score | 26.03 | **26.03** ✅ |
| Shape Signals Computable | 168 | **168** ✅ |
| Shape Coverage | 100.0 % | **100.0 %** ✅ |
| Maximum Shape Drift Score | — | **100.00** |

## Scope decisions
- **Shape is fully computable** (168/168; 0 non-computable; family scores 168 COMPUTED / 0 NOT_COMPUTABLE).
  Therefore the **Non-computable Summary panel is intentionally omitted** (no empty panel); the Signal Details
  table is widened to full width to use that space.
- `forecast_drift_signals.csv` exposes a **single** governed shape metric (`shape_drift_score`). There is **no**
  auxiliary shape metric (`shape_distance` / `max_curve_delta` are not present in the governed snapshot), so the
  details table carries no Current/Previous auxiliary columns and there is no MAPE-equivalent KPI. The 4th KPI
  slot is filled by **Maximum Shape Drift Score** (clearly computable, adds analytical value).
- Shape family governed weight = **40 %** (documented in the header).

## Components (10 panels)
2 text (nav + header) · **A** Average Shape Drift Score · **B** Shape Signals Computable · **C** Shape Coverage
· **D** Maximum Shape Drift Score · **E** Shape Drift Score Over Time · **F** Shape Signal Details ·
**H** Latest Governed Run · **I** Data Quality — Checks Passed.

## Out of scope
Stability, Volatility, Events, Historical Timeline, Top Forecast Keys, Top Scenarios, Settings & Data Quality
(later E7D stages). No changes to Overview / Forecast / Performance, CSV, Python, Power BI, datasource, nginx,
Docker, token, DPAPI, MCP, weights, thresholds. No plugins, no alerts, no deletes, no manual commit.
