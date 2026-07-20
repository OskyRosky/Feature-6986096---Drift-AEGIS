# E7D.8 — Historical Timeline · Closure Summary

**Status:** IMPLEMENTED — pending Oscar's visual acceptance.
**Token (pre-review):** `E7D8_HISTORICAL_TIMELINE_MVP_IMPLEMENTED_PENDING_VISUAL_ACCEPTANCE`
**Dashboard:** `aegis-forecast-drift-timeline` · folder AEGIS Forecast Drift (`afsjccp27s0e8d`) · published version 3 · 14 panels · 7 variables.

## What was built
An honest, chronological governed timeline of forecast drift. Each timeline record is one governed drift event (`is_event = 1`, 71 events, run 1), positioned by `forecast_version` — the only governed field with real temporal spread. A **functional** Date Range control filters by version window, proven by live counts.

## Central rule upheld — NO FABRICATED HISTORY
- Timeline axis = `forecast_version` only.
- Single detection instant surfaced as a fact (not 71 clumped rows).
- Lifecycle = 71 initial `Open`, 0 transitions → reported as-is; no invented status changes.
- No invented Forecast Generated / Alert Triggered activity.

## Date Range — proven functional (the key acceptance)
Live GATE B (`/api/ds/query`): All=71, YTD=40, Last180d=32, Last90d=5, Last60d=0, Last30d=0, 2024=5, 2025=26, 2026=40. Mechanism: custom variable + `contains('${date_range:raw}', '|' + fv_label + '|')` over pipe-bounded version haystacks (the Infinity backend cannot do numeric/date comparisons or honor the native time range — all reverse-engineered via probes 1–7).

## Validation (all PASS)
- GATE A Timeline(All)=71 with all columns incl. `date_basis`.
- GATE B Date Range windows (above).
- GATE C Details=71, `timeline_type='Drift by Forecast Version'`, `event_status='Open'`.
- GATE D Lifecycle=71. GATE E Runs=1, events_created=71, `dq_label='18 / 18 checks passed'`. GATE F distinct versions=12, keys=12.
- Live model: keepTime=false, includeVars=true, timezone utc, timepicker hidden, date_range custom (9 options, default All available history).

## Documented deviations (honest)
1. Native time picker hidden — Infinity ignores the dashboard time range (proven); the functional control is the discrete `date_range` variable + year buckets.
2. No Timeline Type dropdown — single governed category.
3. Filter set adds region + forecast_version + drift_family (parity with Events).
4. Timeline Records == Drift Events (=71) by construction; stated in both KPI descriptions.

## Artifacts (this closure)
- `E7D8_timeline_requirements.md`
- `E7D8_timeline_temporal_schema.md`
- `E7D8_timeline_date_range_contract.md`
- `E7D8_timeline_query_contract.md`
- `E7D8_timeline_reconciliation.md`
- `E7D8_timeline_visual_validation.md`
- `E7D8_timeline_closure_summary.md` (this file)
- Shell archived: `V2/grafana/dashboards/archive/aegis-forecast-drift-timeline-shell.json`
- Publish script: `V2/scripts/push-e7d8-timeline.ps1`

## Boundaries respected
Only the Historical Timeline was built. Top Forecast Keys, Top Scenarios, and Settings & Data Quality were NOT started. No CSV / Python / Power BI / datasource / nginx / Docker / token / DPAPI / MCP / weights / thresholds were modified. No plugins added. No synthetic data. No manual git commit.

## Next
Await Oscar's visual acceptance (see `E7D8_timeline_visual_validation.md`). On acceptance → token `E7D8_HISTORICAL_TIMELINE_MVP_COMPLETED_VISUALLY_ACCEPTED`. **Stop before E7D.9.**
