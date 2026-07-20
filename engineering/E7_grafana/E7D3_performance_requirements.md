# E7D.3 — Performance MVP · Requirements

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: **E7D.3 — Performance MVP (analytical panels)** · Date: 2026-07-19
Dashboard: **AEGIS Forecast Drift — Performance** · uid `aegis-forecast-drift-performance` (retained) · folder
`AEGIS Forecast Drift` (uid `afsjccp27s0e8d`).
URL: `http://localhost:3000/d/aegis-forecast-drift-performance`

## Goal
Transform the E7D.0 structural **shell** (3 text panels) of the Performance section into a complete, governed
analytical dashboard for the **performance drift family** (governed family weight **20%**): accuracy /
error-based drift between forecast versions, quantified by `performance_drift_score`. Adapt the Power BI V1
Performance page to Grafana + the read-only governed **V2** CSV snapshot. **No data is cooked in Grafana** —
all logic stays in the V1 engine; Grafana only reads, filters (shared filter contract) and aggregates via
transformations.

## Questions the dashboard must answer
1. What is the **average performance drift score** across the filtered, computable signals?
2. **How many signals are computable** for performance (i.e. have a realized overlap → a non-empty score)?
3. What is the **average MAPE change** between the current and previous forecast version?
4. What is the **performance coverage** (computable share of the filtered universe)?
5. How does the average performance drift score **evolve over the forecast versions** (trend / peaks)?
6. **Which forecast keys / versions** carry the highest performance drift?
7. **Why are some signals non-computable** (governed reason)?

## Definition of terms (governed)
- **Computable signal** — a signal row with a **non-empty `performance_drift_score`** (a realized overlap
  existed between the current and previous forecast to compute performance drift). Non-computable rows have an
  empty `performance_drift_score`.
- **Performance coverage** — `computable signals ÷ all filtered signals`. The denominator is every filtered
  signal, so the coverage KPI does **not** apply the computable filter.
- **MAPE change** — `metric_delta_pct` for signals whose comparison metric is **`MAPE_deep`** (the accuracy
  signals that expose a realized MAPE delta between versions). Positive = MAPE worsened.

## Baselines to validate (must NOT be hardcoded — computed live from the datasource)
| KPI | Baseline (filters = All) | Source |
|-----|--------------------------|--------|
| Average Performance Drift Score | ≈ **7.71** | mean `performance_drift_score` over computable rows |
| Performance Signals Computable | **156** | count of non-empty `performance_drift_score` |
| Average MAPE Change | ≈ **0.81 %** | mean `metric_delta_pct` over `MAPE_deep` rows |
| Performance Coverage | ≈ **92.9 %** | 156 ÷ 168 filtered signals |

## Components required (9 analytical + 2 text)
| # | Component | Panel type | Answers |
|---|-----------|-----------|---------|
| A | Average Performance Drift Score | stat | Q1 |
| B | Performance Signals Computable | stat | Q2 |
| C | Average MAPE Change | stat | Q3 |
| D | Performance Coverage | stat | Q4 |
| E | Performance Drift Score Over Time | timeseries | Q5 |
| F | Performance Signal Details | table | Q6 |
| G | Non-computable Performance Summary | table | Q7 |
| H | Latest Governed Run | table | governance |
| I | Data Quality — Checks Passed | stat | governance |

## Shared filter contract
Five variables, All by default: **Forecast Key · Forecast Version · Region · Drift Status · Run ID**,
identical wrapper/mechanics to E7D.1/E7D.2 (`queryType:"infinity"` variables, `v`-prefixed `fv_label`, quoted
`run_id`, no aliasing of filtered columns).

### Documented filter exceptions
- **E — Performance Drift Score Over Time** intentionally **ignores the Forecast Version** filter to preserve
  the full historical series (same rule as the E7D.1/E7D.2 trends); it still honors Region, Forecast Key,
  Drift Status and Run ID.
- **G — Non-computable Performance Summary** is sourced from `forecast_drift_family_scores.csv`, which does
  **not** carry `region`, `drift_status` or `calculation_run_id`. It therefore honors **only** the Forecast
  Key and Forecast Version filters.

## Known data limitation (by design)
Only a subset of computable signals expose an explicit **`MAPE_deep`** metric, so the details table's
**Current MAPE / Previous MAPE / MAPE Change** columns are populated for those rows and left blank for the
rest. This mirrors the governed source and is documented in-panel.

## Out of scope (binding)
Do **not** build or modify the Overview, Forecast, or the other 8 section shells; the datasource; nginx;
Docker; CSVs; Python; Power BI V1; weights; thresholds; alerts; plugins; the token; DPAPI; or MCP. No
dashboard deleted. No manual commit (R1 auto-commit untouched).
