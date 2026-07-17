# E7A — Security & Rollback

**Feature 6986096.** Date: 2026-07-16.

## Security posture
| Aspect | Status |
| --- | --- |
| CSV exposure | **Internal Docker network only** (`aegis-net`). `aegis-csv` publishes **no host port**. |
| Data mount | **Read-only** (`:ro`). Write attempt inside the container returns `Read-only file system`. |
| HTTP surface | nginx allows only `GET`/`HEAD`; only the four CSV paths + `/healthz`; everything else → 404. `server_tokens off`, `autoindex off`. |
| Secrets in repo | **None.** Datasource provisioning uses an internal URL only; `.env.example` holds a path override only; `.gitignore` excludes `.env`, `.backups/`, `*.tar.gz`. |
| Tesseract / SQL | Not touched. No SQL executed. No writes to any source system. |
| Python engine / CSVs | Not modified. Confirmed via git (no changes under `V1/data/processed/current`). |
| Credentials | None created or printed. No service account (deferred to E7B by instruction). |

## Backup taken (Phase 2)
| Item | Value |
| --- | --- |
| What | Full tar.gz of the Grafana persistent volume `grafana-storage` |
| Method | `docker run --rm -v grafana-storage:/data:ro -v <backupdir>:/backup alpine:3.20 tar czf ...` (volume mounted **read-only**) |
| Location | **Outside the repo:** `C:\Users\oscarau\grafana-backups\grafana-storage-20260716_171834.tar.gz` (~20 MB) |
| Why outside repo | The volume contains the Grafana DB (users, hashed admin password, API keys) — must never be committed |

## Exact rollback (verified, reversible)
Run in order to return to the pre-E7A state:

```powershell
# 1. Remove the provisioned datasource file, then reload provisioning
docker exec grafana rm -f /etc/grafana/provisioning/datasources/aegis-infinity.yaml

# 2. Remove the Infinity plugin from the persistent volume
docker exec grafana grafana cli --pluginsDir /var/lib/grafana/plugins plugins remove yesoreyeram-infinity-datasource

# 3. Detach Grafana from the user-defined network (keeps default bridge)
docker network disconnect aegis-net grafana

# 4. Restart Grafana to unload plugin + drop the provisioned datasource
docker restart grafana

# 5. Stop and remove the CSV server + network (from V2/)
docker compose -f "<project>\V2\docker-compose.yml" down

# 6. (Only if ever needed) restore the Grafana volume from backup:
#    docker run --rm -v grafana-storage:/data -v C:\Users\oscarau\grafana-backups:/backup `
#      alpine:3.20 sh -c "cd /data && tar xzf /backup/grafana-storage-20260716_171834.tar.gz"
```

### Rollback guarantees
- Steps 1–5 touch only artifacts created by E7A; the `grafana-storage` volume (dashboards/users) is preserved throughout.
- Step 6 is a safety net only; not needed for a normal rollback.
- The existing `grafana` container is never removed or recreated in either apply or rollback.

## Residual risk
- Low. The only mutation to the existing instance is a plugin add + one provisioning file + a network attach + one restart — all individually reversible. No dashboards, users, or existing datasources were modified.
