# E7C — Variable Contract

**Stage:** E7C — Grafana Dashboard Foundation Preview
**Date:** 2026-07-18
**Dashboard:** `aegis-forecast-drift-foundation`

All variables are **Infinity query variables** (derived from the governed CSV data — no
hardcoded values), each with an **All** option, `multi: true`, stable technical names and
clear labels, reusable by future panels (E7D/E7E).

## Data-driven cardinality (from `forecast_drift_signals.csv`, 168 rows)

| Column | Distinct | Sample | Decision |
|--------|----------|--------|----------|
| `forecast_key` | 12 | APC-MULTITENANT, EUR-MSIT, GBR-GO LOCAL … | ✅ variable (real service/segment dimension) |
| `region` | 9 | APC, AUS, CAN, EUR, GBR, IND … | ✅ variable |
| `drift_status` | 4 | Healthy, Watch, Warning, Critical | ✅ variable (Status) |
| `calculation_run_id` (runs.csv) | 1 | 1 | ✅ variable (Run ID) |
| `scenario` | 1 | Enterprise (single value) | ⚠️ not added as its own filter (single value) |
| `service` | 1 | *(empty in governed snapshot)* | ❌ not usable — column blank |
| `severity` | mixed | 107 blank + Warning/Critical/Watch | ❌ not used — `drift_status` is cleaner |

## Variable definitions

| # | Name (technical) | Label | Source column | Source CSV | Values | All | Multi |
|---|------------------|-------|---------------|------------|--------|-----|-------|
| 1 | `forecast_key` | Service / Forecast Key | `forecast_key` | signals | 12 | ✅ | ✅ |
| 2 | `region` | Region | `region` | signals | 9 | ✅ | ✅ |
| 3 | `drift_status` | Drift Status | `drift_status` | signals | 4 | ✅ | ✅ |
| 4 | `run_id` | Run ID | `calculation_run_id` | runs | 1 | ✅ | ✅ |

### Naming rationale

The requested **"Service"** variable maps to **`forecast_key`** because the literal `service`
column is **empty** in the V2 governed snapshot; `forecast_key` (12 values) is the meaningful
service/segment identifier. **Scenario** was intentionally not created as a separate filter
because it is a single value (`Enterprise`). This honors "create only variables that can be
correctly obtained from the CSVs" and "no hardcoded values".

## Foundation-preview binding note

Preview panels A–D are **not** bound to these variables (they always render the full governed
snapshot), guaranteeing no variable-induced "No data". Variables are provided as **reusable
foundation** for the E7D/E7E panels that will apply filtering.
