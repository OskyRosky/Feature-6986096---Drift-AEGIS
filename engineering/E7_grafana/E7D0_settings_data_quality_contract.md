# E7D.0 — Settings & Data Quality Contract

**Stage:** E7D.0 — Dashboard Information Architecture & Shared Navigation
**Date:** 2026-07-19
**Dashboard:** `AEGIS Forecast Drift — Settings & Data Quality` (uid `aegis-forecast-drift-settings`)

This contract defines what the Settings & Data Quality dashboard will contain **in E7D.11**.
**Nothing analytical is built in E7D.0** — the current dashboard is a structural shell.

## Planned content (E7D.11)

1. **Data-quality summary** — headline `18 / 18` checks (from run `checks_passed` / `checks_total`).
2. **Individual 18-check table** — one row per check with:
   - check name / description,
   - result (pass / fail),
   - governed source.
3. **Latest governed run** — `calculation_run_id`, `run_status`, `run_finished_at`, `signals_written`,
   `events_created`, `runtime_seconds`, `perf_mode` (from `forecast_drift_runs.csv`).
4. **Freshness** — snapshot timestamp + latest run finished-at.
5. **Data sources** — the 4 governed CSVs (signals 168 / family 672 / events 71 / runs 1) served
   read-only via `aegis-forecast-drift-csv`.
6. **Model weights (governed, read-only):**
   - Performance **20%**
   - Shape **40%**
   - Stability **30%**
   - Volatility **10%**
7. **Severity thresholds (governed, read-only):** Healthy 0–20 · Watch 20–40 · Warning 40–70 · Critical 70+.
8. **Coverage** — `score_coverage_pct`, `missing_family_flag`, `confidence_level`.
9. **Versioning** — `calculation_version`, `normalization_version`, `formula_version`,
   `threshold_config_id`, `weight_config_id`.
10. **Data lineage** — `source_database`, `source_schema`, `source_object`, `source_forecast_version`,
    plus the V1→V2 SHA256-verified snapshot manifest.
11. **Known limitations** — `service` column empty (use `forecast_key`); single `scenario` (`Enterprise`);
    single calculation run in the current snapshot.
12. **Service & scenario status** — explicit statement of the two data limitations above.
13. **Governance (read-only)** — all thresholds, weights and classifications live in the **V1 Python
    engine**; this dashboard only **reads** governed datasets.

## Presentation rule

Settings is **not** presented as editable configuration. Because the rules are governed and read-only,
the dashboard displays them as **read-only reference**, clearly labelled as governed by V1.

## Not in scope for E7D.0

No check tables, KPIs, lineage panels, weights/threshold visuals, or freshness panels are built now.
They are deferred to **E7D.11**.
