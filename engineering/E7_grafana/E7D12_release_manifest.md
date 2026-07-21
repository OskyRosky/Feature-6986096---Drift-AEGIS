# E7D.12 — Release Manifest (`e7-final`)

Backup / rollback package location: `V2/release/e7-final/`.
Integrity file: `V2/release/e7-final/SHA256SUMS.txt` (28 files — every package file except
`SHA256SUMS.txt` itself; deterministic order by path, uppercase SHA-256).

## Package contents
| Path | Count | Notes |
|---|---|---|
| `dashboards/*.json` | 10 | active navigation dashboards |
| `dashboards/retired/aegis-forecast-drift-top-scenarios.json` | 1 | rollback-only, not in nav |
| `datasource/aegis-infinity.yaml` | 1 | Infinity provisioning, **no secrets** |
| `nginx/default.conf` | 1 | hardened read-only server config |
| `compose/docker-compose.yml`, `compose/.env.example` | 2 | `restart: unless-stopped`, no host ports |
| `scripts/*.ps1` | 8 | start/stop, sync, catalog builder, 4 validators |
| `data/data_manifest.json`, `data/forecast_drift_data_quality_checks.csv` | 2 | manifest + served catalog snapshot |
| `VERSION_INFO.md`, `UID_INVENTORY.md`, `ROLLBACK.md`, `SHA256SUMS.txt` | 4 | metadata |

## Key hashes (SHA256)
| File | SHA256 |
|---|---|
| `data/forecast_drift_data_quality_checks.csv` | `9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1` |
| `datasource/aegis-infinity.yaml` | `3A1C71BC88516CA5FE72E308EDE85BD58BBB1B9466C06C195FD87F06CCCFA26F` |
| `nginx/default.conf` | `1762268E5DD26FA926820929CAB38DCF34483D88592039999823511712D21CA6` |
| `compose/docker-compose.yml` | `3E84300D9D091A8DF407223C155384984074BD86DC8F9E3715DCA16A53F69541` |
| `dashboards/aegis-forecast-drift-foundation.json` | `4A1DF596BB7EDAD0962EF2BEDDADBD8DC91C5B460031F91EEA740231E6308C22` |
| `dashboards/aegis-forecast-drift-top-keys.json` | `6A6211D0CC3E085FAC80B6092257F56A730F2564E5A32307B057A2AEEE92B38B` |
| `dashboards/retired/aegis-forecast-drift-top-scenarios.json` | `EB4DB573C272BFC04F0155F8B956A2A6C21969BFF7022A8244756113B5B2D065` |

(Full list of all 28 hashes in `SHA256SUMS.txt`.)

## Verify integrity
```powershell
cd V2/release/e7-final
Get-Content SHA256SUMS.txt | ForEach-Object {
  $h,$p = $_ -split '\s+',2
  '{0}  {1}' -f $(if ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -eq $h) {'OK  '} else {'DIFF'}), $p
}
```

## UID inventory (fixed)
Datasource `aegis-forecast-drift-csv`; dashboards `aegis-forecast-drift-{foundation,
forecast, performance, shape, stability, volatility, events, timeline, top-keys,
settings}` (active) + `aegis-forecast-drift-top-scenarios` (retired). See
`UID_INVENTORY.md`.

**Result: release package complete, hashed, and self-verifiable — PASS.**
