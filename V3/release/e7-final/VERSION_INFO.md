# AEGIS Forecast Drift — V2 Grafana Release `e7-final`

| Field | Value |
|---|---|
| Release id | `e7-final` |
| Stage | E7D.12 — Final Integration, Regression Validation & Deployment Readiness |
| Scope | Local Grafana product (Grafana Enterprise 13.0.1) + read-only CSV server |
| Prepared | 2026-07-20 |
| Status | Technical validation PASS — **pending visual acceptance** |
| Validation token | `E7_FINAL_VALIDATION_PASS` (orchestrator, exit 0) |
| Deployment status | **NOT deployed.** Local `localhost` only. No corporate portal, no Azure, no corporate infra. |
| Data snapshot | signals 168 / family_scores 672 / event_history 71 / runs 1 / data-quality checks 18 (18 PASS / 0 FAIL) |
| Catalog SHA256 | `9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1` (validation == served) |
| Datasource | Infinity `AEGIS Forecast Drift CSV` uid `aegis-forecast-drift-csv` → `http://aegis-csv` (internal only) |

## Contents
| Folder | Purpose |
|---|---|
| `dashboards/` | 10 active dashboard JSON definitions (navigation set) |
| `dashboards/retired/` | `Top Scenarios` — retired from navigation, preserved for rollback only |
| `datasource/` | Infinity datasource provisioning YAML (contains **no** secrets) |
| `nginx/` | Hardened read-only nginx config (allowlist of 5 CSVs + healthz) |
| `compose/` | `docker-compose.yml` + `.env.example` (aegis-csv, `restart: unless-stopped`, no host ports) |
| `scripts/` | Startup, transactional refresh, catalog builder, and 4 read-only validators |
| `data/` | `data_manifest.json` + served data-quality catalog snapshot |
| `SHA256SUMS.txt` | SHA256 of every file in this package |
| `UID_INVENTORY.md` | Dashboard + datasource UID inventory |
| `ROLLBACK.md` | Step-by-step rollback procedure |

## Governance
- The dashboards never compute drift. All drift logic, weights, thresholds and
  classifications live in the V1 Python engine. V2 reads governed CSVs only.
- This package is a **backup / rollback** artifact. It performs no deployment.

## Reproduce validation
```powershell
pwsh -File scripts/validate-e7-final.ps1   # expect: E7_FINAL_VALIDATION_PASS (exit 0)
```
