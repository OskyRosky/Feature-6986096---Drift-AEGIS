# E7B.2 — Closure Summary

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.2 — Install Pinned
Grafana MCP Server.** Date: 2026-07-17. **Outcome: `E7B2_MCP_INSTALLATION_COMPLETED`.**

## What this stage did
Installed the **official** `mcp-grafana` **v0.17.2** binary (windows/amd64) **outside
the repository**, verified integrity (SHA256 vs release page **and** official
`checksums.txt`), validated it runs locally (`--version` / `--help`), and produced
reproducible, secret-free install/verify scripts + a manifest. **The MCP was NOT
connected to Grafana**; no service account, token, or Claude Code registration.

## Deliverables
| File | Purpose |
| --- | --- |
| `E7B2_installation_preflight.md` | Read-only preflight table |
| `E7B2_release_integrity_validation.md` | Official release + SHA256 verification |
| `E7B2_local_installation_report.md` | Install location, binary validation, scripts |
| `E7B2_security_validation.md` | Secrets/MCP/runtime integrity checks |
| `E7B2_closure_summary.md` | This summary |
| `V2/scripts/install-mcp-grafana.ps1` | Idempotent, pinned, checksum-verified installer |
| `V2/scripts/verify-mcp-grafana.ps1` | Read-only verifier (no token, no Grafana) |
| `V2/scripts/mcp-grafana-install-manifest.json` | Secret-free install manifest |

## Key facts
- **Version:** v0.17.2 (pinned; no `latest`).
- **Asset:** `mcp-grafana_Windows_x86_64.zip`, SHA256 `939eb0f4…eb62616` (verified twice).
- **Binary hash:** `39710095…26a2d8`.
- **Location:** `%LOCALAPPDATA%\AEGIS\mcp-grafana\v0.17.2\mcp-grafana.exe` (outside repo).
- **Transport:** stdio supported; tool-limiting flags present (`--disable-write`, etc.).
- **PATH:** not modified.

## Prep for E7B.3 (documented, NOT implemented)
| Ítem | Valor futuro |
| --- | --- |
| Service account | `aegis-mcp` (a crear en E7B.3) |
| Grafana URL | `http://localhost:3000` |
| Mecanismo de token | **`GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE`** (preferido sobre token inline en JSON/args/env persistente) |
| Almacenamiento del token | archivo **fuera del repo**, git-ignored (a crear en E7B.3) |
| Scope Claude Code | `local` |
| Nombre del servidor MCP | `grafana` |

*No token file created in this stage.*

## Integrity (runtime unchanged)
- Grafana 13.0.1 healthy; aegis-csv healthy. No Docker/dashboard/folder/datasource change.
- V2 counts 168 / 672 / 71 / 1. V1 intact. No secrets.
- **MCP clean state:** no MCP servers registered, no `.mcp.json`, no `.vscode/mcp.json`.

## Risks
- **R1 — external auto-commit/push** to `origin/main` (commits `add`): active,
  non-blocking. Binary lives outside the repo, so it cannot be published; in-repo
  scripts/docs are secret-free. Fired during E7B.2 (commit `b60f2b9`) on the prior
  E7B.1 corrections — observed, not modified.

## Blockers for E7B.3
**None.** E7B.3 is READY pending explicit user authorization.

## Next step
Await explicit authorization to start **E7B.3 — Service account `aegis-mcp` + token**.
Do NOT start it automatically.
