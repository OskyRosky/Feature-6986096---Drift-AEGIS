# E7D.11 — Lineage Contract

**Stage:** E7D.11 · **Date:** 2026-07-20

## Data path (source → dashboard)
1. **Source data** — governed forecast source (`run_metadata.json`: source live, profile expanded, synthetic false).
2. **V1 Python drift engine** (`V1/python/drift_engine`) — computes signals, family scores, events; runs governance checks in `checks.py`; governed config in `config/settings.py`.
3. **Validation output** — `V2/data/processed/validation/_data_quality_checks.csv` (18 checks, engine output).
4. **Derived catalog** — `V2/scripts/build-e7d11-check-catalog.ps1` → `validation/forecast_drift_data_quality_checks.csv` (SHA-256 `9E76361…551EE1`).
5. **Served copy (byte-identical)** — `current/forecast_drift_data_quality_checks.csv` (same SHA-256).
6. **nginx `aegis-csv`** — read-only, exact-match allowlist (5 governed CSVs + `/healthz`); everything else 404.
7. **Grafana Infinity** datasource `aegis-forecast-drift-csv` (backend CSV parser).
8. **Dashboard** `aegis-forecast-drift-settings` — reads governed CSVs via HTTP; renders read-only.

## Dataset inventory (manifest `V2/data/processed/data_manifest.json`, stage E7A.2, v1_modified = false)
| Dataset | Rows | SHA-256 (prefix) |
|---|---:|---|
| forecast_drift_signals.csv | 168 | D975B46… |
| forecast_drift_family_scores.csv | 672 | 61DF281… |
| forecast_drift_event_history.csv | 71 | 1038709… |
| forecast_drift_runs.csv | 1 | 361BB46… |
| _data_quality_checks.csv (source) | 18 | 6C082BE… |
| forecast_drift_data_quality_checks.csv (catalog) | 18 | 9E76361… |

## Governed versions (run 1)
Calculation `E5A-v1` · Formula `f1.0` · Threshold `t1.0` · Weight `w1.0` · run_finished_at `2026-07-13T22:44:10Z`.

## Normalization stats (from `run_metadata.json`)
rows_in 575,484 · distinct_keys_raw 21 → canonical 12 (keys_merged 9) · rows_after_dedupe 531,696 · rows_forward_only 265,824 · distinct_versions 15.

## Security
No secrets traverse the path. The Grafana service-account token is DPAPI-encrypted at rest (`%LOCALAPPDATA%\AEGIS\secrets\grafana\aegis-mcp.token.dpapi`), decrypted in memory only by the publish script, and never printed. The dashboard reads governed CSVs only — *el dashboard no cocina datos*.
