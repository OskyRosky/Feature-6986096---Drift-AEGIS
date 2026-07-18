# E7B.1 — Closure Summary

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.1 — Grafana MCP
Connection Preflight.** Date: 2026-07-17. **Outcome: `E7B1_MCP_PREFLIGHT_COMPLETED`.**

## What this stage did
Read-only audit + design to determine the safe, compatible, reproducible way to
connect Claude Code to Grafana via the official Grafana MCP server (`mcp-grafana`).
**Nothing installed, pulled, or configured.**

## Deliverables
| File | Purpose |
| --- | --- |
| `E7B1_mcp_preflight_report.md` | Baseline + Claude Code readiness + compatibility |
| `E7B1_mcp_architecture_decision.md` | A/B/C comparison → **Alternative A** selected |
| `E7B1_permissions_and_secret_design.md` | `aegis-mcp` service account + secret handling |
| `E7B1_tool_allowlist.md` | Allowed/prohibited tools + enforcement |
| `E7B1_implementation_plan.md` | Detailed E7B.2–E7B.5 plan |
| `E7B1_closure_summary.md` | This summary |

## Key decisions
- **Architecture A:** `mcp-grafana` **v0.17.2** native binary on the Windows host,
  **stdio**, `GRAFANA_URL=http://localhost:3000`, Claude Code **local scope**, token
  via `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` (git-ignored). Zero impact on `aegis-net`
  or existing containers; trivial rollback.
- **Permissions:** service account `aegis-mcp`, least-privilege (read-only for
  listing; scoped write only for the smoke dashboard), short-lived token, revoke at
  closure.
- **Allow-list:** only `datasource` + `search`/`dashboard` categories; `--disable-write`
  for reads; write scoped to a single temp dashboard `AEGIS Forecast Drift — MCP
  Smoke Test`.
- **Known limitation:** no native Infinity/CSV query tool in `mcp-grafana`; CSV data
  can only be read via an Infinity panel + `run_panel_query` (disabled by default).

## Integrity (unchanged this stage)
- Grafana 13.0.1 healthy; aegis-csv healthy.
- V2 counts 168 / 672 / 71 / 1. V1 == V2. V1 intact.
- No install, no service account, no token, no folder, no dashboard, no MCP config.

## Risks
- **R1 — external auto-commit/push** to `origin/main` (commits `add`): active,
  non-blocking; must be watched in E7B.2–E7B.5 so no secret is ever staged.
- Host-vs-Docker connectivity → resolved by choosing host stdio + `localhost:3000`.
- `.gitignore:64` (`.env.*`) also ignores `.env.example` → templates untracked
  (noted; not modified).

## Blockers for E7B.2
**None.** E7B.2 is READY pending explicit user authorization.

## Next step
Await explicit authorization to start **E7B.2 — Install pinned MCP server**.
Do NOT start it automatically.
