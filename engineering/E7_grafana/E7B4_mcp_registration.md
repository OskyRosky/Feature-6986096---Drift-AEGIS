# E7B.4 — MCP Registration in Claude Code

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: E7B.4 — Register MCP in Claude Code + Connectivity Smoke Test
Date: 2026-07-18
Token: `E7B4_MCP_REGISTRATION_SMOKE_COMPLETED`

> Microsoft internal / confidential. No token value, prefix, suffix, hash, or
> Authorization header appears in this document.

## What was registered

The official `mcp-grafana` v0.17.2 server was registered in **Claude Code** as an
**stdio** MCP server named **`grafana`**, using the secure launch wrapper (not the
binary directly) so the token is never stored in Claude configuration.

| Property | Value |
| --- | --- |
| Server name | `grafana` |
| Scope | **Local** (`~/.claude.json`, private to this project, **not committed**) |
| Transport | stdio |
| Command | `pwsh` |
| Args | `-NoProfile -File <repo>\V2\scripts\start-mcp-grafana.ps1` |
| Environment in Claude config | **empty** (no token; wrapper sources it from DPAPI) |
| Tool allow-list | `search, datasource, dashboard, folder` (enforced by wrapper) |

## Registration command

```
claude mcp add grafana --scope local -- pwsh -NoProfile -File <repo>\V2\scripts\start-mcp-grafana.ps1
```

## Why the wrapper (not the exe) is the command

`start-mcp-grafana.ps1` decrypts the DPAPI-encrypted token **in memory**, injects
`GRAFANA_SERVICE_ACCOUNT_TOKEN` for the child process only, launches
`mcp-grafana -t stdio --enabled-tools search,datasource,dashboard,folder`, and clears
the secret on exit. As a result:

- The token is **never** written into `~/.claude.json` (`Environment: empty`).
- stdout carries **only** the MCP JSON-RPC stream; all wrapper diagnostics and
  mcp-grafana logs go to **stderr** (verified — see E7B4_connectivity_smoke_test.md).

## Location of Claude config

`~/.claude.json` (user profile, **outside the repository**). Confirmed: no
`.claude.json` or `.mcp.json` exists inside the repo.

## Health check

`claude mcp list` and `claude mcp get grafana` both report **`Status: ✓ Connected`**.

## Rollback

```
claude mcp remove "grafana" -s local
```
