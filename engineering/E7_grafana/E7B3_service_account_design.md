# E7B.3 — Service Account Design (`aegis-mcp`)

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: E7B.3 — Grafana Service Account & Secure Token
Date: 2026-07-18
Token: `E7B3_SERVICE_ACCOUNT_TOKEN_COMPLETED`

> Microsoft internal / confidential. This document records **design and identity
> facts only**. It contains **no token value, prefix, suffix, hash, or Authorization
> header** of any kind.

## Purpose

Provide a dedicated, non-personal Grafana identity for the coding agent to reach
Grafana through the official `mcp-grafana` server (installed in E7B.2), with a
short-lived token that never touches the repository.

## Identity

| Property | Value |
| --- | --- |
| Service account name | `aegis-mcp` |
| Resolved login | `sa-1-aegis-mcp` |
| Display name | `aegis-mcp` |
| Organization | `orgId = 1` |
| Organization role | **Editor** (temporary) |
| Grafana server admin | **No** (`isGrafanaAdmin = false`) |

## Role rationale — why Editor (temporary)

- E7B.4 (smoke test), E7C and E7D require creating, reading, modifying and deleting
  **dashboards and folders**. `Editor` grants that broad read/write access.
- The official `grafana/mcp-grafana` README (tag `v0.17.2`) explicitly endorses
  assigning the built-in **Editor** role as a simpler alternative to fine-grained
  RBAC scopes.
- The account is deliberately **not Admin**: it has no `users:read` and no
  `server.admin` permission (confirmed in E7B3_permission_validation.md).

## Defense-in-depth beyond the role

Even though the token carries the Editor role, the launch wrapper
(`V2/scripts/start-mcp-grafana.ps1`) restricts the MCP tool surface to only:

```
search, datasource, dashboard, folder
```

All other tool categories (admin, alerting, incidents, oncall, snapshots,
provisioning, prometheus, loki, etc.) are **not enabled**.

## Token inheritance

The service account token inherits the permissions of the `aegis-mcp` service
account. Reducing the account role (or revoking the token) immediately reduces or
removes what the token can do.

## Lifecycle

| Phase | Action |
| --- | --- |
| E7B.3 | Create account (Editor) + short-lived token with explicit expiration |
| E7B.4 / E7C / E7D | Token used for connectivity + dashboard build/validation |
| After E7D (or expiration) | Reduce role to Viewer/None + RBAC, **or revoke** the token |

The token is **not** revoked at the close of E7B.3 — it remains valid until E7C/E7D
complete or the configured expiration is reached.
