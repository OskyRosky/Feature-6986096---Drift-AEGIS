# E7D.12 — Startup & Resilience Validation

## Scripts
- `V2/scripts/start-aegis-grafana.ps1` — local bring-up (idempotent, read-only w.r.t. data).
- `V2/scripts/stop-aegis-grafana.ps1` — stops `aegis-csv` only (Grafana opt-in via
  `-IncludeGrafana`; never runs `docker compose down` / `-v`).

The start script resolves the repository via `$PSScriptRoot` (handling the Unicode
hyphen in the path), runs `docker compose up -d aegis-csv`, starts Grafana **only if
it already exists and is stopped**, ensures both containers share `aegis-net`, waits
for `aegis-csv` health with a timeout, then checks the five CSV endpoints and Grafana
on `localhost:3000`. It never prints or modifies the DPAPI token, never touches MCP,
never recreates Grafana, never deletes volumes, and never changes governed data.

## Docker resilience (Phase 5)
`aegis-csv` already declares `restart: unless-stopped` in
`V2/docker-compose.yml` and on the live container — no change required. No host ports
are published (CSVs are reachable only inside `aegis-net`). Mounts are read-only.

## Clean startup test (Phase 16)
Controlled restart of `aegis-csv` only (Grafana left running, out-of-band):
```
[start-aegis] Starting aegis-csv via Docker Compose (...\V2\docker-compose.yml)...
 ✔ Container aegis-csv Started
[start-aegis] Grafana already running.
[start-aegis] Grafana already attached to aegis-net.
[start-aegis] OK  - aegis-csv healthy.
================ AEGIS Forecast Drift — local status ================
  grafana        : running
  aegis-csv      : running (health: healthy)
  network        : aegis-net
     [OK ] forecast_drift_signals.csv  lines=169 (expected 169)
     [OK ] forecast_drift_family_scores.csv  lines=673 (expected 673)
     [OK ] forecast_drift_event_history.csv  lines=72 (expected 72)
     [OK ] forecast_drift_runs.csv  lines=2 (expected 2)
     [OK ] forecast_drift_data_quality_checks.csv  lines=19 (expected 19)
  Grafana HTTP   : 200 (OK)
====================================================================
[start-aegis] OK  - AEGIS stack up: aegis-csv healthy, 5 endpoints OK, Grafana reachable.
STARTUP_EXITCODE=0 ELAPSED=33.9s
```

| Item | Expected | Observed | Result |
|---|---|---|---|
| aegis-csv reaches healthy | yes | yes | PASS |
| 5 CSV endpoints | 169/673/72/2/19 lines | 169/673/72/2/19 | PASS |
| Grafana HTTP `/api/health` | 200 | 200 | PASS |
| Script exit code | 0 | 0 | PASS |
| Bring-up time | (informational) | ~34 s (health settle) | — |
| Governed data modified | no | no | PASS |
| Grafana recreated / volume deleted | no | no | PASS |

Post-restart full validation (`validate-e7-final.ps1`) → `E7_FINAL_VALIDATION_PASS`.

**Result: startup & resilience — PASS.**
