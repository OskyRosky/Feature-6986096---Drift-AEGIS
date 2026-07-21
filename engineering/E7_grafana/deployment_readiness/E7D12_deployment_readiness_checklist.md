# E7D.12 — Deployment Readiness Checklist (corporate portal)

> **Status: READY (pending visual acceptance). NOT deployed.**
> This document describes what a future corporate Grafana portal deployment would
> require. E7D.12 performs **no** deployment, creates **no** Azure resources, and
> connects to **no** corporate infrastructure. The next stage is a separate,
> explicitly-authorized "Corporate Grafana Portal Deployment".

## Readiness checklist (14 items)
| # | Item | Local state | Portal action required |
|---|---|---|---|
| 1 | Dashboard definitions (10 active) | JSON in `V2/release/e7-final/dashboards/` | Import into portal folder "AEGIS Forecast Drift" |
| 2 | Retired dashboard (Top Scenarios) | rollback-only, not in nav | Do not import unless rollback needed |
| 3 | Datasource provisioning | Infinity `aegis-forecast-drift-csv` → `http://aegis-csv` | **Re-point URL** — `http://aegis-csv` is a local Docker alias and will **not** resolve in the portal |
| 4 | Governed data hosting | local nginx `aegis-csv`, internal only | Decide portal-side hosting for the 5 CSVs (governed storage endpoint) |
| 5 | Datasource UID | `aegis-forecast-drift-csv` (must stay fixed) | Preserve UID so dashboard links keep working |
| 6 | Dashboard UIDs | fixed (see UID_INVENTORY) | Preserve UIDs on import |
| 7 | Navigation (tag `aegis-nav`, native dropdown) | verified | Confirm tag-based nav works in portal org |
| 8 | Shared filters (5) | verified | Confirm template variables resolve against portal datasource |
| 9 | Data-quality catalog (18 checks) | 18/18, SHA verified | Ensure refresh job publishes catalog portal-side |
| 10 | Refresh pipeline | `sync-governed-data.ps1` (local) | Define portal-side governed refresh cadence/owner |
| 11 | Authentication / access | none locally (localhost) | Portal SSO / folder permissions to be set by portal owners |
| 12 | Secrets | none in repo; DPAPI token local & out-of-band | Portal service account / datasource auth to be provisioned by team |
| 13 | Network egress | internal Docker only | Firewall / private endpoint decisions owned by infra team |
| 14 | Rollback | `V2/release/e7-final/ROLLBACK.md` | Adapt rollback for portal import/removal |

## Known blocker for portal (must be resolved by the team, not by E7D.12)
`http://aegis-csv` is a Docker-network alias resolvable only on the local
`aegis-net`. In the corporate portal the Infinity datasource URL and the CSV hosting
location must be replaced with a governed, portal-reachable endpoint. **This is a
deliberate, documented gap — not a defect.**

## Information required from the team (Chinmay / portal & infra owners)
See `INFORMATION_REQUEST.md` in this folder. Summary:
1. Target corporate Grafana portal URL + organization/folder.
2. Approved hosting location/endpoint for the five governed CSVs (or approved
   Infinity target) reachable from the portal.
3. Authentication model for the datasource (anonymous internal vs. token/SSO).
4. Service account / permissions to import dashboards and provision the datasource.
5. Network/firewall/private-endpoint constraints for portal → CSV host.
6. Refresh ownership & cadence for the governed snapshot in the portal environment.
7. Change-management / approval process for publishing dashboards.

**Result: deployment readiness documented; portal deployment NOT started — PASS
(ready, awaiting separate authorization).**
