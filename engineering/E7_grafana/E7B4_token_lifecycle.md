# E7B.4 — Token Lifecycle & Revocation

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: E7B.4 — Register MCP in Claude Code + Connectivity Smoke Test
Date: 2026-07-18

> Microsoft internal / confidential. No token value, prefix, suffix, or hash is
> recorded here — only lifecycle metadata.

## Token identity (no secret)

| Property | Value |
| --- | --- |
| Service account | `aegis-mcp` (`sa-1-aegis-mcp`) |
| Organization role | Editor (temporary) |
| Storage | DPAPI-encrypted, `%LOCALAPPDATA%\AEGIS\secrets\grafana\aegis-mcp.token.dpapi` (outside repo) |

## Expiration

- **The token expires on 1 September 2026 (2026-09-01).**
- It must be **revoked at the close of E7D** (whichever comes first: E7D completion
  or the 2026-09-01 expiration).

## Revocation procedure

1. **Remote (authoritative):** Grafana UI →
   *Administration → Users and access → Service accounts → `aegis-mcp` → Tokens* →
   delete the token.
2. **Local (encrypted copy):** run
   `V2\scripts\remove-grafana-mcp-token.ps1` to delete the DPAPI ciphertext.
3. **Claude Code registration:** run
   `claude mcp remove "grafana" -s local` to unregister the MCP server.
4. Optionally reduce the `aegis-mcp` service account role to Viewer/None.

## Rotation note

Because the launch wrapper reads the DPAPI ciphertext at each start, rotating the
token only requires re-running `store-grafana-mcp-token.ps1` with a new token; no
change to the Claude Code registration is needed.

## Reminder

This lifecycle is tracked in `PROJECT_STATUS.md` and `engineering/ROADMAP.md`. Do not
let the token outlive E7D. The token is intentionally **not** revoked at the close of
E7B.4 because E7C/E7D still require it.
