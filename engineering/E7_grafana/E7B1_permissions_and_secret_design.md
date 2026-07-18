# E7B.1 — Permissions & Secret Handling Design

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.1.** Date: 2026-07-17.

> **Design only.** No service account, token, or secret was created. Names below are
> proposals for E7B.3.

## 1. Future service account

| Attribute | Proposal |
| --- | --- |
| Name | **`aegis-mcp`** |
| Org | Grafana default org (`GRAFANA_ORG_ID=1` unless confirmed otherwise) |
| Creation | **manual by the user** in E7B.3 (Administration → Service accounts) |

### Role analysis

The official docs map tools to RBAC actions/scopes. For the E7B.4 smoke test we
need: list datasources, list/search dashboards, list/create a folder, create/read/
update/delete one temporary dashboard.

| Need | Minimum action | Scope |
| --- | --- | --- |
| List datasources | `datasources:read` | `datasources:*` (or `datasources:uid:aegis-forecast-drift-csv`) |
| Search/read dashboards | `dashboards:read` | `dashboards:*` or per-folder |
| Create folder | `folders:create` / `folders:write` | `folders:*` |
| Create/update/delete smoke dashboard | `dashboards:create`, `dashboards:write` | `folders:uid:<AEGIS folder>` |

- **Is Viewer enough?** Viewer suffices for **read-only** (list datasources, search/
  read dashboards). It is **not** enough to create the folder/dashboard.
- **Is Editor needed?** Creating the folder + smoke dashboard requires write.
  Two clean options:
  1. **Editor role** scoped as narrowly as Grafana allows (simplest; broad r/w).
  2. **Custom role** with only `datasources:read`, `dashboards:read/create/write`,
     `folders:create/write` — ideally scoped to the **`AEGIS Forecast Drift` folder**
     (`folders:uid:<uid>`) once it exists (least privilege).
- **Folder-scoped limitation:** the folder must exist to scope by its UID. For the
  very first folder creation, a broader `folders:create` is required; afterwards,
  dashboard writes can be pinned to `folders:uid:<AEGIS>`.

### Datasource permission
- On `AEGIS Forecast Drift CSV` (uid `aegis-forecast-drift-csv`): `datasources:read`
  is enough for MCP to list/inspect it. `datasources:query` is only needed if we
  later enable `run_panel_query` to read CSV data through an Infinity panel.

### Token lifecycle
| Aspect | Proposal |
| --- | --- |
| Duration | **Short-lived** for the smoke test (e.g. **1–7 days**, or the shortest Grafana allows) |
| Rotation | Prefer `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` (read fresh per request → rotate by replacing the file, no restart) |
| Revocation | Delete the token in Grafana (Service accounts → aegis-mcp → tokens) at smoke-test end |
| Cleanup | Remove token file + `claude mcp remove grafana` + delete token in Grafana |
| Extra authorization | Any **write** beyond the single smoke dashboard, any datasource/user/org/plugin/alert change → require explicit user authorization |

### Permission separation (three tiers)
1. **Smoke test (E7B.4):** minimum write, scoped to the temporary dashboard + the
   AEGIS folder. Token short-lived, revoked at closure.
2. **MVP build (E7C/E7D):** write scoped to the `AEGIS Forecast Drift` folder only.
3. **Post-MVP steady state:** **read-only** (`--disable-write` + Viewer/read scopes).

## 2. Secret handling design

| Requirement | Design |
| --- | --- |
| Token never in repo | Store in a **git-ignored** file outside version control |
| Token never in chat | Never printed; user types it directly into the file/terminal |
| Token never in docs | Only placeholders (`<token>`) in documentation |
| Token never in logs | `stdio` transport; avoid `--debug` with token echoes; no `-e TOKEN` inline |
| Token never in versioned MCP config | Config references `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE=<path>`, not the value; use **local scope** (`~/.claude.json`, not committed) |
| Env vars / secret storage | `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` → local file; optionally Windows user-scoped env var |
| `.env` only if git-ignored | Root `.gitignore` already ignores `.env`, `.env.*`, `*.env`, `*.token`, `*.secret`, `*.key`, `credentials.*` ✅ |
| `.env.example` without real values | Provide `V2/.env.mcp.example` with placeholders only |
| Cleanup / revocation command | `claude mcp remove grafana`; delete token file; revoke token in Grafana UI |
| Automated secret scan | Pre-continue scan for `password|secret|token|api[_-]?key|bearer` in staged/new files |

### Recommended storage
- Token file: e.g. `V2/.secrets/grafana-mcp.token` (create `.secrets/` and ensure it
  is git-ignored in E7B.2 — **verify `git check-ignore` before writing the token**).
- MCP env: `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE=<absolute path to that file>`.
- **Do NOT** use inline `GRAFANA_SERVICE_ACCOUNT_TOKEN`.

### ⚠️ Gitignore observations (reviewed, NOT modified)
- Root `.gitignore:63-80` already covers secrets/tokens/env broadly ✅.
- **Caveat:** `.gitignore:64` (`.env.*`) also ignores `.env.example` (no negation),
  so example templates are currently **not tracked**. For a versioned MCP template,
  either use a name that is **not** matched by `.env.*` (e.g. `mcp.env.sample.md`
  documented inline) or add an explicit `!` negation in E7B.2 **only with user
  authorization**. This preflight does not modify `.gitignore`.
- **R1 caveat:** the external auto-commit/push means any accidentally-tracked secret
  would be pushed to `origin/main`. Therefore the token file **must** match an
  ignored pattern and be verified with `git check-ignore` **before** it contains a
  real value.
