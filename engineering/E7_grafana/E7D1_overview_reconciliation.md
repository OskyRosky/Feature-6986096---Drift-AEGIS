# E7D.1 — Overview MVP · Analytical Reconciliation

**Dashboard:** AEGIS Forecast Drift — Overview · uid `aegis-forecast-drift-foundation`
**Method:** each panel's query + transformation was replicated against the live datasource (read-only
`/api/ds/query`, backend parser, same CSVs Grafana reads) and compared to the governed ground truth
computed in E7D.1 Phase 2. Filter simulation uses the full value lists (equivalent to every variable = `All`).
Date: 2026-07-19.

## 1. Reconciliation table (All filters = default)
| Metric | CSV expected | Grafana query result | Difference | Status |
|--------|-------------:|---------------------:|-----------:|:------:|
| Total Signals | 168 | 168 | 0 | ✅ |
| Total Events (`is_event == 1`) | 71 | 71 | 0 | ✅ |
| Avg Drift Score | 28.8 | 28.8 | 0.0 | ✅ |
| Status — Critical | 14 | 14 | 0 | ✅ |
| Status — Warning | 34 | 34 | 0 | ✅ |
| Status — Watch | 38 | 38 | 0 | ✅ |
| Status — Healthy | 82 | 82 | 0 | ✅ |
| Family — stability | 88 | 88 | 0 | ✅ |
| Family — volatility | 45 | 45 | 0 | ✅ |
| Family — shape | 27 | 27 | 0 | ✅ |
| Family — performance | 8 | 8 | 0 | ✅ |
| Trend points (distinct forecast_version) | 14 | 14 | 0 | ✅ |
| Distinct forecast keys | 12 | 12 | 0 | ✅ |
| Top key by avg drift | NAM-SDF | NAM-SDF | — | ✅ |
| Top key avg value | 42.74 | 42.74 | 0.00 | ✅ |
| Top key max drift status (band) | Critical | Critical | — | ✅ |
| Latest Run — Run ID | 1 | 1 | — | ✅ |
| Latest Run — Status | Success | Success | — | ✅ |
| Latest Run — Signals Written | 168 | 168 | 0 | ✅ |
| Latest Run — Events Created | 71 | 71 | 0 | ✅ |
| Data Quality — checks passed/total | 18 / 18 | 18 / 18 | 0 | ✅ |

**Result: 21 / 21 metrics matched · 0 mismatches.**

## 2. Cross-checks (internal consistency)
- Severity KPIs sum: 14 + 34 + 38 + 82 = **168** = Total Signals. ✅
- Family counts sum: 88 + 45 + 27 + 8 = **168** = Total Signals. ✅
- Events (71) = signals with `is_event == 1` = event-history rows (71) = `runs.events_created` (71). ✅
- Signals (168) = `runs.signals_written` (168). ✅
- `drift_status` == severity band of `forecast_drift_score` for **all 168** rows (0 mismatches) → the table's
  "Max Drift Status" (band of max score) is a faithful worst-case per key. ✅

## 3. Filter responsiveness (validated via literal-equivalent expressions)
| Simulated selection | Expected | Query result |
|---------------------|---------:|-------------:|
| region = APC | 14 | 14 ✅ |
| drift_status = Critical | 14 | 14 ✅ |
| forecast_version = 2025-12-01 | 12 | 12 ✅ |
| all filters = All | 168 | 168 ✅ |
| all filters = All, `&& is_event == 1` | 71 | 71 ✅ |

## 4. Interpolation note
The frontend **does** interpolate `${var:singlequote}` into `filterExpression` for backend queries (confirmed
in plugin source `src/interpolate.ts`). The earlier v3 failure was **not** an interpolation problem — it was
that the template variables were mis-declared and therefore empty (see §5). With the variables repaired, the
shared filter contract interpolates correctly and the reconciliation above holds.

## 5. Post-repair end-to-end verification (v5) — added after the v3 render failure
The first published build (v3) rendered **"No data" on every panel** in live Grafana. Root cause: the 5
template variables lacked the `queryType:"infinity"` wrapper (plugin `migrateLegacyQuery` returned empty →
empty dropdowns → `region IN ()` → backend error on all panels); plus panels 23/24 aliased a filtered column
(`No parameter 'forecast_key'/'calculation_run_id' found`). Both fixed and republished as **v5**.

To verify the fix without a browser, each **published** panel target was replayed through `/api/ds/query`
with the `${var:singlequote}` tokens replaced by the full `All`-expanded value lists (exactly what the
frontend now produces once the dropdowns populate):

| Panel id | Title | Result |
|---------:|-------|:------:|
| 10 | Total Signals | 168 ✅ |
| 11 | Total Events | 71 ✅ |
| 12 | Avg Drift Score | 168 rows (mean 28.8) ✅ |
| 13 | Critical | 14 ✅ |
| 14 | Warning | 34 ✅ |
| 15 | Watch | 38 ✅ |
| 16 | Healthy | 82 ✅ |
| 20 | Drift Status Distribution | 168 ✅ |
| 21 | Avg Drift Score Over Time | 168 ✅ |
| 22 | Signals by Dominant Family | 168 ✅ |
| 23 | Forecast Keys by Drift Risk | 168 ✅ |
| 24 | Latest Governed Run | 1 ✅ |
| 25 | Data Quality — Checks Passed | 1 (18/18) ✅ |

**Result: 13 / 13 filter panels PASS · 0 FAIL** against the exact published targets. Live visual rendering
remains **pending Oscar's authenticated review** (the agent cannot log into Grafana).
