# E7A — Datasource Architecture

**Feature 6986096.** Date: 2026-07-16. Stage E7A — Grafana Readiness & Data Source.

## Goal
Let the existing Grafana (13.0.1) consume the four governed CSVs from
`V1/data/processed/current/` via the **Infinity** datasource, **without**
recreating the Grafana container and **without** publishing the CSVs to the host.

## Chosen design (least disruptive)

```
                          user-defined bridge network: aegis-net
   ┌─────────────────────────────────────────────────────────────────────┐
   │                                                                       │
   │   grafana (13.0.1)  ────HTTP GET──►  aegis-csv (nginx:1.27-alpine)    │
   │   Infinity 3.10.1                    http://aegis-csv/<file>.csv      │
   │   uid: aegis-forecast-drift-csv       (port 80, NOT published)        │
   │                                        mounts, READ-ONLY:             │
   │                                        V1/data/processed/current ─────┼──► host CSVs
   └───────────────────────────────────────────────────────────────────────┘
   grafana also stays attached to the default `bridge` and keeps :3000 published.
```

### Components
| Component | Value |
| --- | --- |
| CSV server image | `nginx:1.27-alpine` (pinned) |
| CSV server container | `aegis-csv` (managed by `V2/docker-compose.yml`) |
| CSV mount | `../V1/data/processed/current` → `/usr/share/nginx/html` **:ro** |
| Exposure | internal only — **no `ports:`**; reachable only on `aegis-net` |
| Network | `aegis-net` (user-defined bridge; provides DNS) |
| Grafana attachment | `docker network connect aegis-net grafana` (reversible; keeps `bridge`) |
| Plugin | `yesoreyeram-infinity-datasource@3.10.1` (signed by Grafana Labs; requires Grafana ≥11.6) |
| Datasource | name **`AEGIS Forecast Drift CSV`**, uid `aegis-forecast-drift-csv`, `url: http://aegis-csv`, `allowedHosts: [http://aegis-csv]`, `editable: false` |

### Served endpoints (internal)
- `http://aegis-csv/forecast_drift_signals.csv`
- `http://aegis-csv/forecast_drift_family_scores.csv`
- `http://aegis-csv/forecast_drift_event_history.csv`
- `http://aegis-csv/forecast_drift_runs.csv`
- `http://aegis-csv/healthz` (liveness only)

nginx is hardened: `server_tokens off`, `autoindex off`, only `GET`/`HEAD`
allowed, and an explicit allow-list of the four CSV paths (everything else → 404).
`default_type text/csv` so Infinity receives `Content-Type: text/csv`.

## Why not the alternatives
| Alternative | Why rejected for E7A |
| --- | --- |
| Infinity reads a **loose local file path** | Not reliable/permitted per requirement; Infinity is HTTP-first. A URL server is the supported pattern. |
| Publish CSVs on a host port (`127.0.0.1:PORT`) + `host.docker.internal` | A loopback-bound host port is not reachable via `host.docker.internal`; binding `0.0.0.0` would over-expose the CSVs. Internal Docker DNS avoids any host exposure. |
| Recreate Grafana with a compose stack now | Violates "do not replace the current instance"; deferred to E8. |
| SQLite/Postgres layer | Heavier; not needed for the MVP. Reconsider when cross-table joins get heavy. |

## Governance
- No drift logic, thresholds, weights, or classifications exist in this layer.
- The CSV server only **serves bytes**; Grafana only **reads** them.
- Datasets are mounted **read-only**; the Python Drift Engine and CSVs are untouched.

## Files (all under `V2/`)
- `V2/docker-compose.yml` — the `aegis-csv` service + `aegis-net` network.
- `V2/nginx/default.conf` — hardened static config.
- `V2/grafana/provisioning/datasources/aegis-infinity.yaml` — datasource (no secrets).
- `V2/.env.example` — optional `AEGIS_CSV_DIR` override (no secrets).
- `V2/.gitignore` — ignores `.env`, `.backups/`, `*.tar.gz`.
