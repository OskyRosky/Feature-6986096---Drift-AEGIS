# E7B.1 — Implementation Plan (E7B.2 → E7B.5)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.1.** Date: 2026-07-17.

Detailed, staged plan derived from this preflight. **Each stage requires explicit
user authorization before starting.** Architecture = **A** (host binary, stdio,
`localhost:3000`, local scope, token via file).

## E7B.2 — Install pinned MCP server

| # | Step | Detail |
| --- | --- | --- |
| 1 | Fetch pinned binary | `mcp-grafana` **v0.17.2** windows/amd64 from official GitHub Releases (verify checksum). Alt: `go install .../cmd/mcp-grafana@v0.17.2` or pinned `uvx`. |
| 2 | Place binary | Known host path (e.g. `C:\Users\oscarau\.mcp\mcp-grafana.exe`), outside the repo. |
| 3 | Verify | `mcp-grafana --version` → confirm v0.17.2. |
| 4 | Prep secrets dir | Create `V2/.secrets/`; **verify `git check-ignore`** covers the token file path. |
| **Secrets** | **None** | No token yet. |
| **Rollback** | Delete binary + `.secrets/` dir | No Grafana/Claude changes made. |
| **Validation** | version prints; nothing registered in Claude Code; Grafana/aegis-csv healthy; git clean | |

## E7B.3 — Service account & token (manual)

| # | Step | Detail |
| --- | --- | --- |
| 1 | Create service account | **User**, in Grafana UI: `aegis-mcp`, role per `E7B1_permissions_and_secret_design.md` (read-only start, or Editor/custom scoped for smoke). |
| 2 | Generate token | Short TTL (1–7 d). **User pastes it directly** into `V2/.secrets/grafana-mcp.token`. |
| 3 | Confirm ignore | `git check-ignore -v V2/.secrets/grafana-mcp.token` **must** return a match before the file holds a real value. |
| 4 | Validate token | Manual `curl -H "Authorization: Bearer <token>" http://localhost:3000/api/datasources` returns 200 + the Infinity datasource. |
| **Secrets** | token file (git-ignored) | Never printed, never committed. |
| **Rollback** | Revoke token in Grafana + delete file | Service account can be deleted too. |
| **Validation** | 200 from API; token file ignored; no secret in git status | |

## E7B.4 — Register MCP in Claude Code & connect

| # | Step | Detail |
| --- | --- | --- |
| 1 | Register (read-only) | `claude mcp add grafana -s local -- <binary> --transport stdio --enabled-tools "search,datasource,dashboard" --disable-write` with env `GRAFANA_URL=http://localhost:3000`, `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE=<path>`. |
| 2 | Connect & smoke (read) | `list_datasources` → `AEGIS Forecast Drift CSV` visible; `search_dashboards` → current folders/dashboards. |
| 3 | Enable write (scoped) | Re-register **without** `--disable-write` to allow folder/dashboard create. |
| 4 | Create folder | `create_folder` → `AEGIS Forecast Drift` (if absent). |
| 5 | Create smoke dashboard | `update_dashboard` → `AEGIS Forecast Drift — MCP Smoke Test`. |
| 6 | Read back | `get_dashboard_by_uid`/`_summary` → confirm. |
| 7 | Modify | small edit via `update_dashboard`. |
| 8 | Delete | remove ONLY the smoke dashboard. |
| 9 | Confirm health | Grafana + aegis-csv still healthy; V1/V2 counts unchanged. |
| **Secrets** | token via file only | Never inline. |
| **Rollback** | `claude mcp remove grafana`; delete smoke dashboard/folder | |
| **Validation** | datasource listed; smoke dashboard lifecycle OK; no other object touched; Grafana healthy | |

## E7B.5 — Closure

| # | Step | Detail |
| --- | --- | --- |
| 1 | Revoke token | Delete token in Grafana; remove token file. |
| 2 | Decide steady state | Keep MCP read-only (`--disable-write` + Viewer) for E7C, or remove entirely until needed. |
| 3 | Security validation | Secret scan; `git status`; confirm no secret tracked/pushed. |
| 4 | Integrity | V1 unchanged; V2 counts 168/672/71/1; Grafana/aegis-csv healthy. |
| 5 | Closure tables | Present + update `PROJECT_STATUS.md`, `ROADMAP.md`. Leave **E7C READY**. |
| **Outcome** | `E7B_MCP_CONNECTION_COMPLETED` (target) | |

## Cross-cutting

- **R1 auto-commit/push:** watch every stage; verify no secret gets staged. Do not
  modify the external process.
- **No V1 mutation** at any point.
- **`run_panel_query`** stays disabled unless/until querying CSV data via an Infinity
  panel is explicitly required (E7C+), and only with `datasources:query` added.
