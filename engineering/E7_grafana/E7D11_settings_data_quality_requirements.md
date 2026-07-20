# E7D.11 — Settings & Data Quality · Requirements

**Stage:** E7D.11 — Settings & Data Quality analytical content
**Date:** 2026-07-20
**Dashboard:** `AEGIS Forecast Drift — Settings & Data Quality` · UID `aegis-forecast-drift-settings` (preserved) · folder `afsjccp27s0e8d`
**Status token (this stage):** `E7D11_SETTINGS_DATA_QUALITY_IMPLEMENTED_PENDING_VISUAL_ACCEPTANCE`

## Objective
Convert the E7D.0 structural shell into a governed, read-only Settings & Data-Quality view that makes the **18 governed data-quality checks** transparent and reconcilable, alongside the governed run, model parameters, computability, dataset inventory, lineage and limitations. All logic remains in the **V1** Python engine — *el dashboard no cocina datos*.

## Gate A (mandatory precondition) — the 18 checks are not invented
The 18 checks are sourced authoritatively from:
- `V2/data/processed/validation/_data_quality_checks.csv` (engine output, 18 rows, all PASS, manifest SHA-256 `6C082BE…B45C7F`), and
- `V1/python/drift_engine/checks.py` (`run_checks()`, verifiable rule per check).

No check is invented, split, merged or renamed. `canonical_check_name` is verbatim; the derived catalog generator is **driven by the source CSV** and **aborts if the source ≠ 18 checks** or if a source check lacks documented metadata. **Gate A: PASSED.**

## Functional requirements
1. **Data Quality — Checks Passed** headline `18 / 18`, large, green background (run-scoped).
2. **Checks Passed** = 18; **Checks Failed** = 0 (green at 0, red if > 0); **Checks Total** = 18; **Run Status**.
3. **Latest Validation Run** table (run id, status, finished-at, checks passed/total, signals written, events created).
4. **18-check catalog** table read **live via Infinity URL** `http://aegis-csv/forecast_drift_data_quality_checks.csv` (not hardcoded), PASS in green, filterable columns, wrapped Rule/Evidence.
5. **Checks by Category** (derived grouping) — only traceable categories, 1:1 justified by `checks.py`.
6. **Governed Weights** (Performance 20 / Shape 40 / Stability 30 / Volatility 10 = 100), read-only.
7. **Status Thresholds & boundary behavior** (Healthy [0,20) / Watch [20,40) / Warning [40,70) / Critical [70,100]).
8. **Computability Coverage** by family (live from `forecast_drift_family_scores.csv`).
9. **Non-Computable Reasons** by family (live).
10. **Dataset Inventory** (signals 168 / family 672 / events 71 / runs 1 / catalog 18) with manifest SHA-256 prefixes.
11. **Data Lineage** source → V1 engine → validation → served catalog → nginx → Grafana Infinity → dashboard; no secrets.
12. **Governance Rules** — read-only, single source of truth, no fabrication, traceability.
13. **Known Limitations** — single run, lifecycle initial Open only, no Scenario/Service dimension, partial computability, not live.

## Serving decision (Option B, Oscar-authorized 2026-07-20)
The nginx `aegis-csv` read-only allowlist was extended by **exactly one** exact-match rule
`location = /forecast_drift_data_quality_checks.csv { try_files $uri =404; }` (no wildcard, no directory listing, `location / { return 404; }` preserved). The governed catalog is written by `build-e7d11-check-catalog.ps1` as a **byte-identical served copy** in `current/` (same SHA-256 as the `validation/` artifact). The catalog table reads it via Infinity URL — **not** inline, **not** hardcoded.

## Out of scope / limits respected
Only the Settings dashboard, its artifacts, the check catalog and the single nginx allowlist line are touched. No change to any other dashboard, to the Python/validation logic, weights, thresholds, datasource, Docker, token/DPAPI, MCP, or R1. No plugins, no alerts, no synthetic checks, no manual commit. **E7D.12 not started.**
