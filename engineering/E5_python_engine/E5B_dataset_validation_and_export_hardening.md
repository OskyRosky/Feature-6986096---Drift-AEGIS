# E5B — Production Dataset Validation & Export Hardening

**Feature 6986096 — AEGIS Forecast Drift Framework**
**Stage:** E5B — Production Dataset Validation & Export Hardening
**Date:** 2026-07-13

> Local-first hardening of the Python Drift Engine so its governed datasets are
> reliable, reproducible, stable and ready for **Power BI Desktop** (then Grafana)
> as pure consumers. **No SQL DDL, no SQL tables/views, no writes to Tesseract,
> no Power BI yet, no Grafana yet.** Architecture: `Tesseract read-only →
> Python Drift Engine local → governed CSV/Parquet → BI consumers`.
> Principle enforced: **the dashboard does not cook data** — all business logic
> lives in Python.

## Scope executed
1. **Key canonicalization & case-folding (I1)** — new `canonicalize.py`
   (non-destructive `forecast_key_raw` + `forecast_key_canonical`, trim + space
   collapse + upper, collision report, semantic-merge guard). See
   `E5B_key_canonicalization_report.md`.
2. **Unicode logging (I2)** — `logger.ensure_utf8_stdout()`; scripts/tests print
   relative names, never the full U+2011 path. Reproduced the crash on the real
   project path, then fixed it. Fixtures now exit 0.
3. **Grain & row-count validation** — see `E5B_grain_and_row_count_validation.md`.
4. **Expanded controlled sample** — `SampleConfig.expanded()` = 12 keys / 15
   versions, Enterprise/HDD, SELECT-only; run via `run_refresh --profile expanded`.
5. **Runtime & memory** — measured per phase; see `E5B_runtime_and_memory_results.md`.
6. **Performance deep recompute (I3)** — new `performance_deep.py`; explicit
   `perf_mode=shallow|deep`; deep coverage 78/85 vs shallow 13/85 on the
   deterministic fixture. See `E5B_deep_performance_comparison.md`.
7. **Parquet + CSV fallback** — export prefers Parquet when pyarrow present,
   always writes CSV. pyarrow currently absent (documented, not force-installed).
8. **Final dataset contract** — `E5B_output_contract_final.md` (5 datasets).
9. **Stable naming & folder layout + atomic writes** — `current/`, `metadata/`,
   `validation/`, `history/`; every file written `.tmp`→`os.replace`.
10. **Reproducible local refresh** — `scripts/run_refresh.py` (dry-run / sample /
    expanded / shallow|deep / snapshot / exit codes; valid outputs not
    overwritten on failure).
11. **Data quality** — `checks.py` extended to 18 checks; results in
    `E5B_data_quality_results.csv`.
12. **Extended idempotency** — 3 identical runs, identical record hashes; see
    `E5B_idempotency_results.csv`.
13. **Python ↔ Power BI boundary** — `E5B_powerbi_handoff_matrix.csv`.
14. **E6 readiness** — checklist in `E5B_closure_summary.md`.

## Validation status (offline, deterministic synthetic fixture + E5A real outputs)
- Fixtures E3: **7/7 PASS** (I2 crash resolved).
- Canonicalization: raw 9 → canonical 7, merged 2, collision groups 1, suspicious 0.
- Data quality: **18/18 PASS**.
- Idempotency: 3 runs identical.
- Deep vs shallow Performance coverage: 78/85 vs 13/85.
- Runtime (expanded synthetic): ~3.1 s total, peak ~3.2 MB.

## Live expanded sample (Tesseract read-only)
The engine is ready. The live expanded real sample (12 keys / 15 versions,
Enterprise/HDD) is executed by:
```
$env:AEGIS_DRIFT_SQL_SERVER="<host>"; $env:AEGIS_DRIFT_SQL_DATABASE="<db>"
python -m drift_engine.scripts.run_refresh --source live --profile expanded --perf-mode deep
```
This requires VPN + Entra Interactive (MFA) and is the one step that needs the
operator's DB session. Outputs land atomically in `V1/data/processed/current/`.

## Governance
Read-only against source; SELECT-only; no DDL/tables/views/writes; no secrets or
connection strings logged; real data outputs stay out of Git; V1 folder only.
