# E7B.1 — MCP Tool Allow-List

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.1.** Date: 2026-07-17.

Defines which `mcp-grafana` tools are **allowed** vs **prohibited** for the E7B.4
connectivity smoke test, and how the restriction is technically enforced.

## Allowed (E7B.4 smoke test)

| Tool | Category | Purpose | RBAC |
| --- | --- | --- | --- |
| `list_datasources` | datasource | Connectivity smoke; confirm `AEGIS Forecast Drift CSV` visible | `datasources:read` |
| `get_datasource` | datasource | Inspect the Infinity datasource by uid/name | `datasources:read` |
| `search_dashboards` | search/dashboard | List existing dashboards/folders | `dashboards:read` |
| `get_dashboard_by_uid` / `_summary` / `_property` | dashboard | Read back the smoke dashboard | `dashboards:read` |
| `create_folder` | dashboard/folder | Create `AEGIS Forecast Drift` folder **if absent** | `folders:create/write` |
| `update_dashboard` | dashboard | Create/modify/**delete** ONLY `AEGIS Forecast Drift — MCP Smoke Test` | `dashboards:create/write` |

Scope of writes: **only** the single temporary dashboard named
`AEGIS Forecast Drift — MCP Smoke Test`, inside the `AEGIS Forecast Drift` folder.

## Prohibited (E7B.4)

| Prohibited action | Why |
| --- | --- |
| Delete/modify **other** dashboards or folders | Out of scope; could damage existing work |
| Delete/modify **datasources** (incl. the Infinity one) | Governed by provisioning; not MCP's job |
| Change users, teams, orgs, auth, RBAC | Admin surface; forbidden |
| Change plugins, alerts, provisioning, snapshots, annotations | Not part of connectivity smoke |
| Global Grafana settings / rendering / navigation | Out of scope |
| Access secrets / tokens via tools | Security |
| Create **final** MVP dashboards during E7B.4 | Belongs to E7C/E7D |
| Query external datasources (Prometheus/Loki/etc.) | Not our stack |
| Touch V1 or governed data (`V2/data/processed/current`) | "El dashboard no cocina datos" |

## Technical enforcement

Two-phase, defense-in-depth:

| Layer | Mechanism |
| --- | --- |
| **Category enable-list** | Start with `--enabled-tools "search,datasource,dashboard"` → only those categories are exposed; incident/prometheus/loki/influxdb/alerting/oncall/sift/pyroscope/navigation/annotations/snapshot/rendering/provisioning/asserts **off**. |
| **Global read-only** | For the **read** portion, add `--disable-write` (blocks `update_dashboard`, `create_folder`, etc.). Remove it **only** for the create/delete steps of the single smoke dashboard, then restore. |
| **Never-enabled categories** | admin, athena, clickhouse, cloudwatch, elasticsearch, examples, graphite, quickwit, **runpanelquery**, snowflake stay disabled (default). |
| **RBAC scopes** | Service account `aegis-mcp` limited to `datasources:read` + dashboards read/create/write + `folders:create/write`, ideally scoped to the AEGIS folder (least privilege). |
| **Operational governance** | Agent instructed to touch only `AEGIS Forecast Drift — MCP Smoke Test`; any other write requires explicit user authorization. |

### Honest limitation
`mcp-grafana` gating is **category-level** (`--enabled-tools`/`--disable-<category>`)
plus the global `--disable-write`, **not** per-individual-tool. Once the `dashboard`
category + write are enabled to create the smoke dashboard, the server technically
also exposes `update_dashboard` against **any** dashboard the token can reach.
Therefore per-object restriction ("only the smoke dashboard") is enforced by a
**combination** of:
1. RBAC scope on the `aegis-mcp` service account (limit writable folder), and
2. operational governance (agent acts only on the named temp dashboard),
not by a single per-tool flag. This is documented so the boundary is explicit.
