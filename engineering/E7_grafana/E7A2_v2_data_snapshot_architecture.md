# E7A.2 — V2 Governed Data Snapshot & Datasource Architecture

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7A.2 — V2 Governed Data Snapshot & Datasource Rewire.** Date: 2026-07-17.

## Purpose

Make **V2 a self-contained Grafana product**. Before E7A.2, the `aegis-csv`
server bind-mounted the governed CSVs directly from `V1/data/processed/current`.
That is architecturally valid but couples V2's runtime to V1's folder. E7A.2
introduces a **byte-equivalent governed snapshot** inside V2 and rewires
`aegis-csv` to serve from it.

## Governance model

```
┌──────────────────────────────────────────┐
│ V1  — AUTHORITATIVE PRODUCER (read-only)   │
│   Python Drift Engine (E5A) computes the   │
│   four governed datasets.                  │
│   V1/data/processed/{current,metadata,     │
│                      validation}/          │
└───────────────┬────────────────────────────┘
                │  scripts/sync-governed-data.ps1
                │  (allow-list copy + SHA256 verify + manifest)
                ▼
┌──────────────────────────────────────────┐
│ V2  — CONSUMPTION SNAPSHOT (self-contained)│
│   V2/data/processed/{current,metadata,     │
│                      validation}/          │
│   V2/data/processed/data_manifest.json     │
└───────────────┬────────────────────────────┘
                │  read-only bind mount
                ▼
        aegis-csv (nginx) ──► http://aegis-csv ──► Grafana (Infinity)
```

- **V1 is authoritative and never mutated.** The snapshot is produced *from* V1
  and validated against it by SHA256. No drift logic runs in V2.
- **"El dashboard no cocina datos."** All business/drift math stays in the V1
  Python Drift Engine; V2 and Grafana only consume governed datasets.

## What changed

| Item | Before E7A.2 | After E7A.2 |
| --- | --- | --- |
| `aegis-csv` mount source | `V1/data/processed/current` | `V2/data/processed/current` |
| Mount mode | read-only | read-only (unchanged) |
| Container name | `aegis-csv` | `aegis-csv` (unchanged) |
| Network | `aegis-net` | `aegis-net` (unchanged) |
| Internal URL | `http://aegis-csv` | `http://aegis-csv` (unchanged) |
| Datasource UID | `aegis-forecast-drift-csv` | `aegis-forecast-drift-csv` (unchanged) |
| Grafana container / volume / port | preserved | preserved (untouched) |

## Snapshot contents (allow-list)

Governed CSVs (`current/`): `forecast_drift_signals.csv` (168),
`forecast_drift_family_scores.csv` (672), `forecast_drift_event_history.csv` (71),
`forecast_drift_runs.csv` (1).

Governed extras: `metadata/run_metadata.json`,
`validation/_data_quality_checks.csv`, `validation/_fixture_results.csv`.

**Explicitly excluded:** Power BI (`.pbix`), the Python Drift Engine, logs,
caches, temp files, and any duplicate/non-governed datasets.

## Sync mechanism

`V2/scripts/sync-governed-data.ps1` (idempotent, no secrets):

1. Resolves V1/V2 paths relative to its own location (no hard-coded absolutes).
2. Copies only the explicit governed allow-list; never writes to V1.
3. Validates the four CSV row counts against the baseline (168/672/71/1).
4. Computes SHA256 before/after and **fails hard on any mismatch**.
5. Emits `V2/data/processed/data_manifest.json` (file, origin, dest, SHA256,
   rows, snapshot timestamp, `calculation_version`).

Re-running the script with unchanged V1 data reproduces an identical snapshot
(only the manifest timestamp differs).

## Configuration

`V2/docker-compose.yml` uses `${AEGIS_CSV_DIR:-./data/processed/current}`, so the
default now resolves to the V2 snapshot (relative to the compose file). An
operator can still override `AEGIS_CSV_DIR` via `.env` if needed.
