# E6 — Known Limitations

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

| # | Limitation | Impact | Status / Plan |
| --- | --- | --- | --- |
| L1 | **`.pbix` visual layer not authored** | pages/visuals/sidebar must be built manually in Power BI Desktop | model + relationships + measures + full page specs delivered; follow `E6_page_specifications.md` + `E6_sidebar_navigation_spec.md` |
| L2 | **G3 Service dimension unsourced** | Top Services is PARTIAL; `service` is null | show forecast_key proxy + data-gap note; do not fabricate Service |
| L3 | **G4 forest mapping absent** | region↔forest grouping unavailable; `forest` null | add mapping when sourced |
| L4 | **Calendar relationship manual** | DAX calculated table can't materialize in the offline TOM model | create `signals[forecast_version] → Calendar[Date]` after first load in Desktop |
| L5 | **Single scenario in MVP data** | Enterprise only (E5B scope) | Top Scenarios visual generalizes when more scenarios load |
| L6 | **Single current run** | history/trend is thin (1 refresh) | trend visuals fill as more governed runs accumulate; `history/` snapshots exist but are not loaded |
| L7 | **`DriftDataFolder` is machine-specific** | path must be set per machine | single parameter to edit; documented in the runbook |
| L8 | **Model built offline (no data preview here)** | row counts validated against CSVs directly, not through a live model | Power BI Desktop refresh loads real data on open |
| L9 | **pyarrow absent upstream** | CSV (not Parquet) is the source | non-blocking; Power BI reads CSV fine |

## Explicitly NOT done (by governance)
- No DAX recomputation of E3 drift formulas, thresholds, version pairing,
  severity, status, dominant family, or event generation.
- No changes to the Python Drift Engine.
- No SQL writes, no Grafana, no cloud deployment, no commit.
