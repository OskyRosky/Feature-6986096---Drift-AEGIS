# E7B.4 — Connectivity Smoke Test

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: E7B.4 — Register MCP in Claude Code + Connectivity Smoke Test
Date: 2026-07-18

> Microsoft internal / confidential. No token value or Authorization header was
> printed, logged, or recorded. No dashboards or folders were created.

## Test A — Standalone MCP stdio handshake (through the wrapper, without Claude)

A raw MCP JSON-RPC session was piped into `start-mcp-grafana.ps1` to validate
stdout cleanliness, token auth, and Grafana connectivity end-to-end:

1. `initialize` (protocolVersion `2024-11-05`)
2. `notifications/initialized`
3. `tools/call` → `list_datasources`

| Check | Expected | Actual | Status |
| --- | --- | --- | --- |
| stdout lines | valid JSON only | 2 JSON lines (`id=1`, `id=2`), no stray text | ✅ |
| initialize result | mcp-grafana serverInfo | present (`mcp-grafana`) | ✅ |
| `list_datasources` result | includes `aegis-forecast-drift-csv` | present | ✅ |
| Non-JSON on stdout | none | none | ✅ |
| Diagnostics location | stderr only | wrapper + mcp-grafana logs on stderr | ✅ |
| Secret leak on stderr | none | `STDERR_SECRET_SCAN=CLEAN` | ✅ |
| Residual token env var | unset | `False` | ✅ |

mcp-grafana stderr confirmed `api_key_set=true` (token used, not shown),
`Fetched public URL from Grafana`, and `Starting Grafana MCP server ... version=0.17.2`.

## Test B — Claude Code health check

| Command | Result |
| --- | --- |
| `claude mcp list` | `grafana: ... - ✓ Connected` |
| `claude mcp get grafana` | `Scope: Local`, `Status: ✓ Connected`, `Type: stdio`, `Environment: (empty)` |

## Integrity after the test

| Check | Value |
| --- | --- |
| Residual `mcp-grafana` process | none |
| Grafana health | ok |
| Dashboards/folders created | none |
| `.claude.json` / `.mcp.json` in repo | none |

**Conclusion:** The coding agent can reach Grafana through the official MCP server
with the securely stored token. Read path validated via `list_datasources`; no write
operations were performed.
