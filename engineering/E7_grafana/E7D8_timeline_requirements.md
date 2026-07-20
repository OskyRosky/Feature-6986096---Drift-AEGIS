# E7D.8 — Historical Timeline · Requirements

**Dashboard:** AEGIS Forecast Drift — Historical Timeline
**UID:** `aegis-forecast-drift-timeline`
**Folder:** AEGIS Forecast Drift (`afsjccp27s0e8d`)
**Scope:** V2 governed snapshot, read-only. Built strictly on governed CSVs served by the `aegis-csv` container through the Infinity datasource `aegis-forecast-drift-csv`.

## Objective
Provide an honest, chronological governed view of forecast drift where each timeline record maps 1:1 to a governed drift event (`is_event = 1`), positioned in time by its `forecast_version`. The **Date Range** control must be *functionally* filtering (proven by counts), never decorative.

## Central rule — NO FABRICATED HISTORY
- Only governed fields are used to place events in time.
- `forecast_version` is the only governed field with real temporal spread (14 versions, 2024-04 → 2026-05) and is therefore the timeline axis.
- `detected_on = created_at = changed_at` collapse to a single detection instant (2026-07-13 22:38 UTC) → surfaced as a fact, never expanded into 71 clumped "detected" rows.
- The governed lifecycle table holds 71 initial `Open` records with **zero** true status transitions → no invented Acknowledged / Investigating / Resolved sequence.
- No `Forecast Generated` / `Alert Triggered` activity exists in the snapshot → none is shown.

## In scope (this MVP)
- ONLY the Historical Timeline dashboard. Explicitly NOT Top Forecast Keys, Top Scenarios, or Settings & Data Quality.

## Panels (14)
| id | Panel | Type | Source |
|----|-------|------|--------|
| 1 | Section nav | text | — |
| 2 | Header | text | — |
| 3 | Temporal model & Date Range | text | — |
| 10 | Timeline Records | stat | signals |
| 11 | Drift Events | stat | signals |
| 12 | Forecast Versions | stat | signals (groupBy) |
| 13 | Affected Forecast Keys | stat | signals (groupBy) |
| 14 | Lifecycle Records | stat | event_history |
| 20 | Historical Timeline — Drift by Forecast Version | table | signals |
| 30 | Drift Events by Forecast Version | barchart | signals (groupBy) |
| 32 | Timeline Records by Forecast Key | barchart | signals (groupBy) |
| 40 | Historical Details | table | signals |
| 50 | Latest Governed Run | table | runs |
| 51 | Data Quality | stat | runs |

## Filters (7 variables)
`forecast_key`, `forecast_version` (v-prefixed `fv_label`), `region`, `drift_status`, `run_id` (`calculation_run_id`), `drift_family` (`dominant_drift_family`), and the custom `date_range`.

## Documented deviations (honest)
- **Native time picker hidden.** The Infinity backend ignores the dashboard time range (proven), so a native picker would be a non-functional control. The functional temporal control is the discrete `date_range` variable (windows + year buckets). Arbitrary free-form date ranges via the native picker are intentionally not wired to Infinity.
- **No Timeline Type dropdown.** The governed snapshot yields a single timeline type (Drift by Forecast Version); a single-value dropdown would be decorative.
- **Filter set** adds `region`, `forecast_version`, and `drift_family` beyond the E7D.0 timeline matrix (parity with the Events dashboard).
- **Timeline Records == Drift Events (= 71).** Every timeline record is a governed drift event, so the two KPIs coincide by construction; both descriptions state this explicitly.

## Acceptance
- All panel queries return live data (no false "No data").
- Date Range demonstrably changes counts (see date_range_contract + reconciliation).
- `keepTime=false`, `includeVars=true`, timezone UTC.
- Oscar visually accepts in his authenticated Grafana session.
