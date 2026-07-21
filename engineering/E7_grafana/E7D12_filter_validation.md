# E7D.12 — Filter (Shared Variable) Validation

Five shared filters are the drill contract across the analytical dashboards:
`Forecast Key`, `Forecast Version`, `Region`, `Drift Status`, `Run ID`.

A filter is only "PASS" if it actually constrains the panels. Where the source
dataset backing a dashboard has no such dimension, the filter is marked **N/A**
(by design) — an ignored filter is never counted as PASS.

## Matrix (● = active shared filter, N/A = dimension not applicable)
| Dashboard | Forecast Key | Forecast Version | Region | Drift Status | Run ID |
|---|---|---|---|---|---|
| Overview | ● | ● | ● | ● | ● |
| Forecast | ● | ● | ● | ● | ● |
| Performance | ● | ● | ● | ● | ● |
| Shape | ● | ● | ● | ● | ● |
| Stability | ● | ● | ● | ● | ● |
| Volatility | ● | ● | ● | ● | ● |
| Events | ● | ● | ● | ● | ● |
| Historical Timeline | ● | ● | ● | ● | ● |
| Top Risk | ● | ● | ● | ● | ● |
| Settings & Data Quality | N/A | N/A | N/A | N/A | ● (run scope) |

## Notes
- Dashboards 1–9 apply the five shared filters against `forecast_drift_signals`
  and its family/event joins (dimensions present: `forecast_key` (12 distinct),
  `forecast_version`, `region`, `drift_status`, `calculation_run_id`).
- Events and Historical Timeline additionally expose local dimensions (severity /
  temporal range) beyond the shared five; those are validated within their own
  dashboards and do not weaken the shared contract.
- Settings & Data Quality is a governance/quality view over the run and the
  18-check catalog; the five drill filters are N/A there, run scope applies.

**Result: shared-filter contract consistent across the nav set — PASS.**
