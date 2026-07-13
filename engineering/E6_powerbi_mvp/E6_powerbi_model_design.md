# E6 — Power BI MVP: Semantic Model Design

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

> **Power BI does not cook data.** All drift logic (Performance/Shape/Stability/
> Volatility, composite, severity, thresholds, events, explanations,
> canonicalization, lineage, hashes, NOT_COMPUTABLE) lives in the Python Drift
> Engine (E5B). Power BI only **consumes, relates, filters, aggregates and
> visualizes** the governed CSVs in `V1/data/processed/current/`.

## Source
Model was authored via the Power BI MCP (offline TOM model
`AEGIS_Forecast_Drift_MVP`, compatibility 1567) and exported to importable TMDL
at `V1/powerbi/tmdl/` (9 files). No `.pbix` visuals yet — see
`E6_page_specifications.md` for the manual report layer.

## Tables (star schema)
| Table | Role | Grain | Source file |
| --- | --- | --- | --- |
| `forecast_drift_signals` | **Fact** (primary) | calc_version × scenario × forecast_key × forecast_version | forecast_drift_signals.csv |
| `forecast_drift_family_scores` | Detail (1:* of signals) | drift_event_id × drift_family (4/signal) | forecast_drift_family_scores.csv |
| `forecast_drift_event_history` | Detail (1:* of signals) | event_history_id | forecast_drift_event_history.csv |
| `forecast_drift_runs` | Dimension (lineage) | calculation_run_id | forecast_drift_runs.csv |
| `Calendar` | Date dimension (DAX calculated) | Date | derived from signals[forecast_version] |

## Shared Power Query parameter
`DriftDataFolder` (M, text) = absolute path to `V1/data/processed/current/`.
**Single value to change per machine.** Every table reads
`DriftDataFolder & "<file>.csv"` — no path hard-coded per table.

## Keys & join columns
- `drift_event_id` — surrogate key of a signal; join for family_scores and
  event_history (many) → signals (one).
- `calculation_run_id` — signals (many) → runs (one).
- `forecast_version` — signals (many) → Calendar[Date] (one) [manual, see below].

## Relationships (cardinality / direction)
| From (many) | To (one) | Column | Cardinality | Cross-filter | Active |
| --- | --- | --- | --- | --- | --- |
| forecast_drift_family_scores | forecast_drift_signals | drift_event_id | many→one | single | Yes |
| forecast_drift_event_history | forecast_drift_signals | drift_event_id | many→one | single | Yes |
| forecast_drift_signals | forecast_drift_runs | calculation_run_id | many→one | single | Yes |
| forecast_drift_signals | Calendar | forecast_version → Date | many→one | single | **Manual** (calculated table materializes only in Desktop) |

No many-to-many. No ambiguous paths. Single-direction filters (dimension →
fact). The Calendar relationship is created after first load in Power BI Desktop
(the DAX calculated table cannot be evaluated in the offline TOM model).

## Latest-snapshot logic
`forecast_drift_signals[is_current] = 1` marks the current governed snapshot.
MVP consumes a single current refresh, so all rows are `is_current = 1`; visuals
may still apply an `is_current = 1` filter to be future-proof when history
accumulates. Point-in-time history lives in `history/` snapshots (not loaded).

## Refresh behavior
Import mode. Power BI refresh re-reads the four CSVs from `DriftDataFolder`.
Correct order: (1) run the Python refresh, (2) validate outputs, (3) refresh
Power BI. See `E6_refresh_runbook.md`.

## Governance guardrails (enforced by design)
- No DAX recomputes E3 formulas, version pairing, thresholds, severity, status,
  dominant family or event generation — those columns are read as-is.
- Measures are pure aggregations / lookups over already-computed columns.
- `service` and `forest` are nullable (G3/G4 open); Top Services is PARTIAL.
