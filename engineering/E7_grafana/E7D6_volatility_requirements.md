# E7D.6 — Volatility MVP · Requirements

**Feature 6986096 — AEGIS Forecast Drift Framework** · uid `aegis-forecast-drift-volatility` · 2026-07-19
Reference: Power BI V1 *Volatility* page, adapted to Grafana + the governed read-only **V2** CSV snapshot.
Structural lineage is the accepted E7D.5 *Stability* dashboard, but **Volatility is deliberately NOT a
mechanical clone** — it is only partially computable and carries governed auxiliary metrics that Stability did not.

## Questions the dashboard must answer
1. What is the **average Volatility Drift Score** (over computable signals)?
2. How many signals have **computable Volatility**, and what is the **coverage**?
3. Which signals are **not computable**, and **why** (governed reason)?
4. How does **Volatility drift evolve over time**?
5. Which **Forecast Keys** show the largest volatility?
6. What is the **governed volatility profile** per key/version (rolling dispersion / oscillation / class)?
7. Which signals reach **Warning / Critical**?
8. What was the **latest governed run** and the **Data Quality** status?

## Governing principle
The dashboard does **not** cook data. All volatility math (rolling dispersion / oscillation / sign-change →
`volatility_drift_score`, 0–100 normalization, status banding, computability governance) is produced by the V1
Python engine and frozen in the V2 snapshot. Grafana only **reads**, **filters** (shared filter contract) and
**aggregates**. **No value is hardcoded** — every KPI reduces the datasource at render time.

## Baselines (validated against CSV)
| Metric | CSV (validated) |
|--------|----------------:|
| Average Volatility Drift Score | **56.04** ✅ |
| Volatility Signals Computable | **144 / 168** ✅ |
| Volatility Coverage | **85.7 %** ✅ |
| Maximum Volatility Drift Score | **100.00** ✅ |
| Non-computable signals | **24** (reason `INSUFFICIENT_VERSIONS`) ✅ |

## Scope decisions — why Volatility differs from Stability/Shape
- **Partial computability (the key differentiator).** `volatility_drift_score` is present for **144 of 168**
  signals. The **24** non-computable signals are exactly the **first two forecast versions of each of the 12
  keys** (`2024-04-01`, `2024-05-01`), which lack enough history to compute rolling dispersion. The governed
  reason is `not_computable_reason = INSUFFICIENT_VERSIONS` (family-scores, `eligibility_status = NOT_COMPUTABLE`).
  → Therefore a **Non-computable Summary panel IS built** (unlike Stability/Shape, which were 168/168 and omitted it).
- **Coverage is a first-class KPI** (85.7 %, not 100 %). Its denominator is the full filtered universe, so it
  intentionally omits the computability clause; averages/max exclude non-computable signals (never treated as zero).
- **Governed auxiliary metrics are surfaced.** `rolling_stddev`, `rolling_cov`, `rolling_mad`, `oscillation_count`,
  `sign_change_freq`, `volatility_class` are **populated (144/168)** — but live in
  `forecast_drift_family_scores.csv`, **not** in `signals.csv`. They are shown in a dedicated **Volatility Profile**
  table. Because family-scores has no `region` / `drift_status` / `calculation_run_id` columns, that table honors
  **only** the `forecast_key` + `forecast_version` filters (documented exception; a cross-CSV composite-key join over
  the equal 168-row universe would break the shared filtering, so two separate tables are used by design).
- **Ranking is a barchart** (Volatility Drift Score by Forecast Key) — a panel type not used in Stability — because
  key-level dispersion comparison is the primary volatility question.
- **Trend starts 2024-06-01** (first computable bucket); the two non-computable versions are excluded, not zeroed.
- Volatility family governed weight = **10 %** (documented in the header).

## Components (13 panels)
2 text (nav + header) · **A** Average Volatility Drift Score · **B** Volatility Signals Computable · **D**
Volatility Coverage · **E** Maximum Volatility Drift Score · **F** Volatility Drift Score Over Time · **G**
Volatility Drift Score by Forecast Key (barchart) · **H** Volatility Signal Details · **I** Volatility Profile —
Governed Auxiliary Metrics (family-scores) · **J** Non-computable Summary (family-scores) · **K** Latest Governed
Run · **L** Data Quality — Checks Passed.

## Out of scope
Events, Historical Timeline, Top Forecast Keys, Top Scenarios, Settings & Data Quality (later E7D stages). No
changes to Overview / Forecast / Performance / Shape / **Stability**, CSV, Python, Power BI, datasource, nginx,
Docker, token, DPAPI, MCP, weights, thresholds. No plugins, no alerts, no deletes, no manual commit.
