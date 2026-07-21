# ROLLBACK — AEGIS Forecast Drift V2 Grafana (`e7-final`)

This procedure restores the local Grafana product to the exact state captured in
this package. It is **local only** — it does not touch any corporate portal,
Azure, or corporate infrastructure. Nothing here deploys anything.

> Prerequisite: Docker Desktop running. The pre-existing `grafana` container
> (Grafana Enterprise 13.0.1) is managed **out-of-band** and is never recreated,
> migrated, or deleted by these steps.

## 0. Verify integrity of this package first
```powershell
# From the release folder:
Get-Content SHA256SUMS.txt | ForEach-Object {
  $h,$p = $_ -split '\s+',2
  $actual = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  '{0}  {1}' -f $(if ($actual -eq $h) {'OK  '} else {'DIFF'}), $p
}
```
All lines must read `OK`. If any read `DIFF`, stop — the package is not intact.

## 1. Restore the governed data snapshot (transactional, idempotent)
The served CSVs are produced by the V1 engine and synced by `sync-governed-data.ps1`.
Re-running it is safe and idempotent; it validates row counts, regenerates the
18-check data-quality catalog, and verifies `validation == served` by SHA256.
```powershell
pwsh -File scripts/sync-governed-data.ps1 -DryRun   # preview (writes nothing)
pwsh -File scripts/sync-governed-data.ps1           # apply
# Expect: CATALOG_REFRESH_INTEGRATED = True
# Expect catalog SHA256 = 9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1
```

## 2. Restore the datasource provisioning (no secrets)
Copy `datasource/aegis-infinity.yaml` into the Grafana provisioning path and
reload provisioning (or restart the Grafana container out-of-band). UID must
remain `aegis-forecast-drift-csv`.

## 3. Restore dashboards
Import the 10 JSON files from `dashboards/` into the folder **AEGIS Forecast Drift**.
UIDs are fixed (see `UID_INVENTORY.md`) so links and provisioning keep working.

### Rollback of the Top Scenarios retirement (only if explicitly required)
`Top Scenarios` was absorbed into `Top Risk` and removed from navigation.
To temporarily restore it for investigation, import
`dashboards/retired/aegis-forecast-drift-top-scenarios.json`. It is intentionally
**not** tagged `aegis-nav`, so it will not reappear in the dropdown unless a tag
is added manually. Do not delete this file.

## 4. Bring up the read-only CSV server
```powershell
pwsh -File scripts/start-aegis-grafana.ps1
```
This runs `docker compose up -d aegis-csv` (from `compose/docker-compose.yml`,
`restart: unless-stopped`, no host ports), ensures the shared `aegis-net` network,
waits for health, and checks the five endpoints plus Grafana on `localhost:3000`.

## 5. Validate
```powershell
pwsh -File scripts/validate-e7-final.ps1
# Expect: E7_FINAL_VALIDATION_PASS (exit 0)
```
Individual validators: `test-aegis-endpoints.ps1`, `test-aegis-navigation.ps1`,
`test-aegis-data-quality.ps1` (all read-only, exit 0 on PASS).

## Expected baselines after rollback
| Metric | Value |
|---|---|
| signals rows | 168 |
| family_scores rows | 672 (= 168 × 4 families) |
| event_history rows | 71 |
| runs rows | 1 |
| data-quality checks | 18 (18 PASS / 0 FAIL) |
| catalog SHA256 (validation == served) | `9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1` |
| active nav dashboards | 10 (Top Scenarios not in nav) |

## Do NOT
- Do **not** run `docker compose down` or `down -v` (would remove containers/volumes).
- Do **not** recreate, migrate, or delete the `grafana` container or its volume.
- Do **not** publish CSV host ports or change the `aegis-net` network.
- Do **not** edit drift formulas, weights, thresholds, source data, UIDs, or the
  datasource UID.
- Do **not** deploy to any corporate portal or Azure from this package.
