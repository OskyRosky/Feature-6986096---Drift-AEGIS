# E7B.3 — Permission Validation (authenticated, read-only)

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: E7B.3 — Grafana Service Account & Secure Token
Date: 2026-07-18

> Microsoft internal / confidential. Validation was performed with the token
> decrypted **in memory only**. **No token value or Authorization header was printed,
> logged, or recorded.** Only read-only Grafana REST endpoints were called; **no write
> operations** and **no MCP server** were started.

## Method

The DPAPI ciphertext was decrypted in memory, used solely to set a `Bearer`
`Authorization` header for `Invoke-RestMethod`, then zeroed. Endpoints queried:
`/api/health`, `/api/user`, `/api/access-control/user/permissions`,
`/api/datasources`, `/api/folders`, `/api/search?type=dash-db`.

## Results

| Validation | Expected | Actual | Status |
| --- | --- | --- | --- |
| Grafana health | ok | `database = ok` | ✅ |
| Authentication | HTTP 200 | 200 | ✅ |
| Identity (login) | service account | `sa-1-aegis-mcp` | ✅ |
| Identity (name) | `aegis-mcp` | `aegis-mcp` | ✅ |
| Organization | orgId 1 | `orgId = 1` | ✅ |
| Server admin | false | `isGrafanaAdmin = false` | ✅ |
| Effective role | Editor | consistent with Editor (see below) | ✅ |
| Datasource visible | `aegis-forecast-drift-csv` | present | ✅ |
| Datasource count | ≥1 | 1 | ✅ |
| Folders readable | yes | 1 folder | ✅ |
| Dashboards searchable | yes | 1 dashboard | ✅ |

## Effective permissions (Editor, not Admin)

| Permission | Present |
| --- | --- |
| `datasources:read` | ✅ |
| `dashboards:read` | ✅ |
| `dashboards:create` | ✅ |
| `dashboards:write` | ✅ |
| `folders:read` | ✅ |
| `folders:create` | ✅ |
| `users:read` | ❌ (not Admin) |
| `server.admin` | ❌ (not Admin) |

The presence of `dashboards:create/write` and `folders:create` with the **absence**
of `users:read` and `server.admin` confirms the account has the **Editor** role and
is **not** an administrator — exactly as designed.

## Constraints honored

- No write/create/update/delete operations were performed.
- No MCP persistent server was started; no `claude mcp add` was run.
- The token was never printed; the `Authorization` header was never displayed.
