# E7D.0 — Dashboard Information Architecture

**Stage:** E7D.0 — Dashboard Information Architecture & Shared Navigation
**Date:** 2026-07-19
**Outcome token:** `E7D0_INFORMATION_ARCHITECTURE_COMPLETED`
**Scope:** Shared product backbone only. **No** analytical panels (those are E7D.1–E7D.11).

## Purpose

Define and materialize the common structure of the Grafana **AEGIS Forecast Drift** product:
the set of dashboards, their order, UIDs, shared navigation, shared filters and a common
visual system — so Oscar can walk the whole product before the analytical panels are built.
The structure conserves the Power BI **V1** logic and extends it with the operational sections
foreseen in the original mockup.

## Product = 11 dashboards (single folder `AEGIS Forecast Drift`, uid `afsjccp27s0e8d`)

| # | Section | Role | Future stage |
|---|---------|------|--------------|
| 1 | **Overview** | Product entry point; keeps the E7C functional preview panels | E7D.1 |
| 2 | **Forecast** | Forecast-level drift entry (forecast_key / forecast_version / overall score) | E7D.2 |
| 3 | **Performance** | Performance drift family (weight 20%) | E7D.3 |
| 4 | **Shape** | Shape drift family (weight 40%) | E7D.4 |
| 5 | **Stability** | Stability drift family (weight 30%) | E7D.5 |
| 6 | **Volatility** | Volatility drift family (weight 10%) | E7D.6 |
| 7 | **Events** | Drift events + lifecycle | E7D.7 |
| 8 | **Historical Timeline** | Status transitions over time | E7D.8 |
| 9 | **Top Forecast Keys** | Ranking of forecast keys by drift | E7D.9 |
| 10 | **Top Scenarios** | Ranking of scenarios by drift | E7D.10 |
| 11 | **Settings & Data Quality** | Governance, 18 DQ checks, weights, thresholds, lineage (read-only) | E7D.11 |

## Mandatory architecture decisions

- **No "Top Services".** The governed `service` column is **empty (0 distinct)**. It is replaced by
  **Top Forecast Keys** using `forecast_key` (12 real values).
- **Top Scenarios stays** in the architecture but currently has a **single scenario `Enterprise`**;
  documented as a known data limitation. No global `scenario` filter while one value exists.
- **Settings & Data Quality** will host the **18 data-quality checks** individually (E7D.11) and is
  presented as **governed & read-only** — not editable configuration (rules live in the V1 engine).

## Relationship to Power BI V1 (logic conserved)

The drift math, families, weights and thresholds are unchanged and remain in the **V1 Python engine**.
The Grafana product only reads the governed V2 snapshot — *"el dashboard no cocina datos."* The four
drift families (Performance / Shape / Stability / Volatility), the severity model
(Healthy / Watch / Warning / Critical) and the weighting (20/40/30/10) mirror the PBI V1 model; the
Grafana product adds the operational sections (Events, Historical Timeline, rankings, Settings/DQ).

## Boundary — E7D.0 vs E7D.1

- **E7D.0 (this stage):** structure only — Overview (retained functional panels) + 10 **shells**
  (navigation + shared filters + a purpose/roadmap text panel). No new KPIs, charts, heatmaps or
  analytical tables. No alerts. No threshold/weight/data changes.
- **E7D.1:** begins building the **Overview** analytical MVP. Not started here.

See companion contracts: `E7D0_dashboard_registry.md`, `E7D0_navigation_contract.md`,
`E7D0_shared_filter_contract.md`, `E7D0_visual_design_system.md`,
`E7D0_settings_data_quality_contract.md`, `E7D0_validation.md`, `E7D0_closure_summary.md`.
