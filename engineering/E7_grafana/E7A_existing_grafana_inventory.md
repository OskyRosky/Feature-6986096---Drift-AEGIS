# E7A — Existing Grafana Inventory (as-found, before changes)

**Feature 6986096.** Date: 2026-07-16. Captured read-only via `docker inspect` / `docker exec`.

## Container
| Property | Value |
| --- | --- |
| Name | `grafana` |
| Image | `grafana/grafana-enterprise` (ImageID `sha256:f7e79dc47a09…`) |
| Version | Grafana **13.0.1** (commit a100054f21, branch HEAD, compiled 2026-04-17) |
| Created by | `docker run` — **no** `com.docker.compose.*` labels |
| Restart policy | `no` |
| Published ports | `0.0.0.0:3000->3000/tcp`, `[::]:3000->3000/tcp` |
| App mode | production |

## Persistence
| Type | Name / Source | Destination | Mode |
| --- | --- | --- | --- |
| volume | `grafana-storage` (`/var/lib/docker/volumes/grafana-storage/_data`) | `/var/lib/grafana` | RW |

> All Grafana state (SQLite DB with dashboards, users, org settings, API keys, and the plugins dir `/var/lib/grafana/plugins`) lives in this single named volume.

## Paths (env)
```
GF_PATHS_CONFIG=/etc/grafana/grafana.ini
GF_PATHS_DATA=/var/lib/grafana
GF_PATHS_HOME=/usr/share/grafana
GF_PATHS_LOGS=/var/log/grafana
GF_PATHS_PLUGINS=/var/lib/grafana/plugins
GF_PATHS_PROVISIONING=/etc/grafana/provisioning
```
Note: `/etc/grafana/provisioning` is **inside the container image layer** (not a host mount), because the container was started with only the `grafana-storage` volume. Provisioning files must therefore be injected (`docker cp`) until a future compose-managed rebuild (E8) mounts them from `V2/`.

## Networks (as-found)
| Network | IP |
| --- | --- |
| `bridge` (default) | 172.17.0.2 |

## Plugins (as-found)
```
grafana-exploretraces-app     @ 2.1.0
grafana-lokiexplore-app       @ 2.3.0
grafana-metricsdrilldown-app  @ 2.2.0
grafana-pyroscope-app         @ 2.1.1
```
Infinity: **not present** before E7A.

## Health (as-found)
`GET /api/health` → `{"database":"ok","version":"13.0.1","commit":"a100054f21"}`

## What E7A changed on this container (minimal, reversible)
1. Installed plugin `yesoreyeram-infinity-datasource@3.10.1` into the persistent `grafana-storage` volume.
2. Attached the container to a new user-defined network `aegis-net` (via `docker network connect`; the `bridge` attachment is retained).
3. Copied one provisioning file `aegis-infinity.yaml` into `/etc/grafana/provisioning/datasources/`.
4. Restarted the container once (data preserved in the volume).

The container was **not** removed, recreated, or replaced. Image, name, ports, and the `grafana-storage` volume are unchanged.
