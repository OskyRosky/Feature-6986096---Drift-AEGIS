# E7D.0 — Visual Design System

**Stage:** E7D.0 — Dashboard Information Architecture & Shared Navigation
**Date:** 2026-07-19

A consistent visual contract shared by all AEGIS Forecast Drift dashboards.

## 1. Titles

- Dashboard title: **`AEGIS Forecast Drift — [Section]`** (em-dash separator).
- Header panel repeats the section title as an H1; short one-line subtitle underneath.

## 2. General panel order (top → bottom)

1. **Navigation** (shared markdown nav bar).
2. **Filters** (shared template variables — Grafana top variable bar).
3. **Header** (section title + subtitle).
4. **KPIs** (stat panels).
5. **Main visuals** (charts / distributions / heatmaps).
6. **Detail tables**.
7. **Freshness & data-quality** info (where applicable).

> In E7D.0 only items 1–3 (+ a purpose/roadmap text panel) exist on the shells; Overview also keeps
> its E7C KPIs/visuals/table.

## 3. Severity model (governed — DO NOT CHANGE)

| Status | Score band | Color |
|--------|-----------|-------|
| Healthy | 0–20 | green |
| Watch | 20–40 | yellow |
| Warning | 40–70 | orange |
| Critical | 70+ | red |

- Palette is **reserved exclusively** for status/severity. Value-mappings pin
  Healthy→green, Watch→yellow, Warning→orange, Critical→red.
- Thresholds are **governed** and are **not** modified here; weights
  (Performance 20% / Shape 40% / Stability 30% / Volatility 10%) are also unchanged.
- **Never** use grey to represent a severity value.

## 4. Formatting rules

| Aspect | Rule |
|--------|------|
| Counts | 0 decimals |
| Drift scores | 1 decimal |
| Percentages | 1 decimal, `%` unit |
| Dates / timestamps | ISO-like, readable (`YYYY-MM-DD` / `YYYY-MM-DD HH:mm` UTC); no raw epoch |
| Tables | left-aligned text, right-aligned numbers; compact cell height; header shown |
| Legends | table legend with value + percent for distributions |
| Sorting | descending by drift score / severity for "top" tables |
| No-data | render a governed **empty-state** message (never a raw "No data" panel); shells use a purpose text panel instead of empty analytic panels |

## 5. Naming hygiene (product-facing)

Avoid, in the final product: internal/dev names, `stage07`, `blog`, `mock`, the word `preview`,
unnecessary decimals, unreadable timestamps, and grey used for severity.

> Note: the internal tag `e7d0` / `shell` on shells is a **build marker** (not shown on panels);
> product-facing titles and text contain no internal names.

## 6. Text & descriptions

- Every analytic panel (E7D.1+) will carry a short, plain-language description.
- Units declared explicitly (count, %, score).
- Section header subtitle: `Governed forecast drift monitoring — V2 snapshot (read-only).`
