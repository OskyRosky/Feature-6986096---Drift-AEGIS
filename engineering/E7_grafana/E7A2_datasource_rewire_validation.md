# E7A.2 — Datasource Rewire Validation

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7A.2.** Date: 2026-07-17.

All checks executed after rewiring `aegis-csv` from the V1 folder to the V2
governed snapshot and restarting only the `aegis-csv` container.

## Mount rewire

| Check | Result |
| --- | --- |
| `aegis-csv` mount source (live `docker inspect`) | `V2/data/processed/current` ✅ |
| Mount mode | `RW=false` (read-only) ✅ |
| nginx config mount | `V2/nginx/default.conf` read-only ✅ |
| Previous source (`V1/data/processed/current`) | no longer mounted ✅ |

## Content served (from V2 snapshot)

| Check | Result |
| --- | --- |
| Files served (`ls` in container) | 4 governed CSVs ✅ |
| `http://127.0.0.1/healthz` (in container) | responds ✅ |
| `forecast_drift_signals.csv` served line count | 169 (168 rows + header) ✅ |
| Read-only enforced (`touch` in mount) | `Read-only file system` → `READONLY_ENFORCED` ✅ |

## Byte-equivalence (V1 == V2)

| Dataset | V1 SHA256 == V2 SHA256 |
| --- | --- |
| forecast_drift_signals.csv | TRUE ✅ |
| forecast_drift_family_scores.csv | TRUE ✅ |
| forecast_drift_event_history.csv | TRUE ✅ |
| forecast_drift_runs.csv | TRUE ✅ |

## Grafana (preserved, untouched)

| Check | Result |
| --- | --- |
| `grafana` container status | running ✅ |
| `GET /api/health` | `database: ok`, version 13.0.1 ✅ |
| Grafana → `http://aegis-csv/forecast_drift_runs.csv` | returns governed row (calc E5A-v1) ✅ |
| Infinity plugin present | `yesoreyeram-infinity-datasource` ✅ |
| Datasource provisioned | `aegis-infinity.yaml` present; UID `aegis-forecast-drift-csv` ✅ |

## Non-mutation & security

| Check | Result |
| --- | --- |
| `git status -- V1/data` | clean (no changes) ✅ |
| V1 governed CSV hashes vs preflight baseline | unchanged ✅ |
| Secret-like patterns in new/modified files | none (only "no secrets" comments) ✅ |
| Host ports published for CSVs | none (internal `aegis-net` only) ✅ |

**Result:** rewire verified end-to-end. Grafana consumes the self-contained V2
snapshot with byte-equivalent governed data; V1 remains the untouched authority.
