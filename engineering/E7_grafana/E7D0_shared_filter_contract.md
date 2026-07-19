# E7D.0 — Shared Filter Contract

**Stage:** E7D.0 — Dashboard Information Architecture & Shared Navigation
**Date:** 2026-07-19

All variables are **Infinity query variables** derived from the governed CSVs (no hardcoded values),
each with an **All** option, `multi: true`, stable technical names and clear labels. None are empty.

## Data-driven cardinality (inspected on the governed V2 snapshot, 2026-07-19)

| Variable (technical) | Label | Source column | Source CSV | Distinct (non-empty) | Decision |
|----------------------|-------|---------------|------------|----------------------|----------|
| `region` | Region | `region` | signals | 9 | ✅ shared filter |
| `forecast_key` | **Forecast Key** | `forecast_key` | signals | 12 | ✅ shared filter (NOT "Service") |
| `forecast_version` | Forecast Version | `forecast_version` | signals | 14 | ✅ shared filter |
| `drift_status` | Drift Status | `drift_status` | signals | 4 | ✅ shared filter |
| `run_id` | Run ID | `calculation_run_id` | runs | 1 | ✅ shared filter |
| `scenario` | — | `scenario` | signals | 1 (`Enterprise`) | ⚠️ no global filter (single value) |
| `service` | — | `service` | signals | 0 (empty) | ❌ unusable — column blank |
| `severity` | — | `severity` | signals | 3 (partial) | ❌ not used — `drift_status` is cleaner |

### Naming rule

The mockup's **"Service"** filter maps to **`forecast_key`** (12 values); the literal `service`
column is empty in the governed snapshot. Label is **"Forecast Key"** — never "Service".

## Per-dashboard applicability matrix

| Dashboard | region | forecast_key | forecast_version | drift_status | run_id |
|-----------|:------:|:-----------:|:----------------:|:------------:|:------:|
| Overview | ✅ | ✅ | ✅ | ✅ | ✅ |
| Forecast | ✅ | ✅ | ✅ | ✅ | ✅ |
| Performance | ✅ | ✅ | ✅ | ✅ | ✅ |
| Shape | ✅ | ✅ | ✅ | ✅ | ✅ |
| Stability | ✅ | ✅ | ✅ | ✅ | ✅ |
| Volatility | ✅ | ✅ | ✅ | ✅ | ✅ |
| Top Forecast Keys | ✅ | ✅ | ✅ | ✅ | ✅ |
| Events | ✅ | ✅ | — | ✅ | ✅ |
| Historical Timeline | — | ✅ | — | ✅ | ✅ |
| Top Scenarios | ✅ | — | — | ✅ | ✅ |
| Settings & Data Quality | — | — | — | — | ✅ |

Rationale for reduced sets: **Events / Timeline** operate on event-lifecycle data
(`forecast_drift_event_history.csv`) where `forecast_version` is not a native dimension;
**Top Scenarios** ranks by `scenario` (single value today) and does not filter by `forecast_key`;
**Settings & Data Quality** is governance/run-scoped (only `run_id`).

## Rules honored

- ✅ Values derived from data, not hardcoded.
- ✅ `All` option on every variable; stable technical names; `multi: true`.
- ✅ No empty variables (every column above returns ≥1 real value).
- ✅ No global `Scenario` filter while a single value exists (documented).
- ✅ Not every CSV has the same columns — applicability documented per dashboard.
- ✅ Variables are a reusable foundation; E7D.1+ panels will bind them.
