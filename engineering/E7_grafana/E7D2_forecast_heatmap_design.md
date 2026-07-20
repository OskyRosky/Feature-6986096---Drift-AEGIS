# E7D.2 — Forecast MVP · Heatmap Design

**Feature 6986096 — AEGIS Forecast Drift Framework** · panel id 50 · 2026-07-19

The drift heatmap (**forecast key × forecast version**) was the one genuinely novel component of E7D.2 and is
documented here in full because Grafana has no native categorical pivot.

## Problem
Power BI's Forecast page shows a matrix: rows = forecast keys, columns = forecast versions, each cell = that
key/version's `forecast_drift_score`, colored by severity. Grafana offers:
- a native **Heatmap** panel — designed for numeric/time *buckets*, not a categorical key × version matrix;
- no **pivot / matrix** transformation out of the box.

## Key finding (makes the matrix unambiguous)
The 168 signal rows are **168 distinct `forecast_key | forecast_version` combinations** — **0 cells contain
more than one signal**. Therefore each cell holds **exactly one** governed `forecast_drift_score`; there is
no aggregation ambiguity (mean = max = the single value). The matrix is 12 keys × 14 versions.

## Root-cause discovery (v2 → v3 repair, 2026-07-19)
The first published build (**v2**) used **14 targets** (one Infinity query per forecast version) joined via
`joinByField`. In external `/api/ds/query` batch tests all 14 targets returned data, so the panel was
believed correct. **In the live Grafana panel it rendered empty — only the `Forecast Key` column, no version
columns, no values, no colors.**

**Root cause:** a panel with 14 Infinity targets issues **14 separate HTTP GETs to the identical URL**
(`http://aegis-csv/forecast_drift_signals.csv`). The Infinity datasource **coalesces/caches responses per
URL**, so only the first target (refId A) receives a frame; targets B–N come back empty. After `joinByField`
(outer) only frame A contributes, and `filterFieldsByName` then leaves essentially just `forecast_key`.
The earlier "batch" test hid the defect because `/api/ds/query` with all 14 queries in **one** request is
**not** how the panel executes — the panel runs them as 14 independent queries. **The multi-target pivot is
therefore fundamentally unstable with Infinity + a single shared URL.**

## Chosen approach (v3) — single-query pivot via **`groupingToMatrix`**
Replace the 14 targets with **one** Infinity query returning the full 168-row long table, then pivot it into a
matrix entirely inside a **native** transform. One query = one HTTP GET = no per-URL coalescing → stable.

### Single target (refId A)
```
columns:
  { selector: forecast_key,          text: forecast_key,          type: string }
  { selector: forecast_drift_score,  text: forecast_drift_score,  type: number }
  { selector: forecast_version,      text: forecast_version,      type: string }   # to compute fv_label
  { selector: region,                text: region,                type: string }   # shared filter
  { selector: drift_status,          text: drift_status,          type: string }   # shared filter
  { selector: calculation_run_id,    text: calculation_run_id,    type: string }   # shared filter
computed_columns:
  { selector: "'v' + forecast_version", text: fv_label }
filterExpression:
  region IN (${region:singlequote}) && forecast_key IN (${forecast_key:singlequote})
  && fv_label IN (${forecast_version:singlequote}) && drift_status IN (${drift_status:singlequote})
  && calculation_run_id IN (${run_id:singlequote})
```
The heatmap now **responds to the five shared filters** (E7D.2 visual-review requirement). `fv_label`
(`v`-prefixed) is used for the version filter to avoid the Infinity ISO-date arithmetic bug.

### Transformations (in order)
1. **`sortBy`** — `field: fv_label`, ascending. Because `fv_label` is a fixed-width `vYYYY-MM-DD` string, a
   lexical sort equals chronological order. This guarantees `groupingToMatrix` emits the version **columns in
   chronological order** (it preserves first-appearance order while scanning rows).
2. **`groupingToMatrix`** — `columnField: fv_label`, `rowField: forecast_key`, `valueField:
   forecast_drift_score`, `emptyValue: null`. Pivots the long table into the 12 × 14 matrix in one step.
   Because each `(key, version)` cell holds exactly one signal, no reduction/ambiguity occurs.
3. **`organize`** — renames the matrix corner field to **"Forecast Key"**. Grafana names the corner
   `rowField\columnField`, so `renameByName` carries three fallback keys
   (`forecast_key\fv_label`, `forecast_key`, `fv_label` → "Forecast Key") to be version-robust.

### Cell coloring
`fieldConfig.defaults`: `custom.cellOptions.type = color-background`, `color.mode = thresholds`,
`thresholds` = green (null) / yellow (20) / orange (40) / red (70), `decimals: 1`, centered, `minWidth: 60`.
Override on "Forecast Key": auto cell, fixed text color, left align, width 170 (label column not colored).
The version columns keep numeric type through the pivot, so severity backgrounds apply per real cell value.

## Why not other options
- **14-target join** — unstable (per-URL Infinity coalescing, see root cause above). Rejected.
- **Native heatmap panel** — categorical axes and single-value cells are not its model; color would be a
  continuous gradient, not the governed severity bands.
- **`Rows to fields` / `Group by`** — cannot produce a 2-D key × version matrix from long data.
- **Single 168-row long table (fallback)** — kept in reserve. If `groupingToMatrix` ever fails to render, the
  fallback is a colored long table (`Forecast Key | Forecast Version | Average Drift Score`, sorted, severity
  background). A functional colored long table is preferable to an empty matrix. Not needed for v3.

## Validation
- **Source-data gate (single query, exactly as the panel now runs):** the one target returns **168 rows**,
  **12** distinct `forecast_key`, **14** distinct `fv_label`. Spot-check APC-MULTITENANT `v2024-04-01` = 25.6
  (matches the Power BI reference). The pivot is a deterministic native transform over this verified frame.
- **Stability:** one HTTP GET → no per-URL coalescing → every version column is populated in the live panel.
- **Filters:** the shared-filter `filterExpression` narrows rows before the pivot, so filtering a version or
  key reduces columns/rows accordingly.

