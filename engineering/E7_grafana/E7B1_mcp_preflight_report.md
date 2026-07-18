# E7B.1 — Grafana MCP Connection Preflight Report

**Feature 6986096 — AEGIS Forecast Drift Framework.**
Stage: **E7B.1 — Grafana MCP Connection Preflight (documentation-only; no runtime mutation).**
Date: **2026-07-17.**

> **Documentation-only / no runtime mutation.** This stage produced documentation
> (six deliverables + status-file updates) but mutated no runtime: nothing was
> installed, pulled, or downloaded, and no service account, token, folder, dashboard,
> or MCP configuration was created or changed. Its purpose is to define the safe,
> compatible, reproducible way to connect the coding agent (Claude Code) to Grafana
> via the official Grafana MCP server — **before** any installation in E7B.2.

## 1. Baseline (read-only)

| Check | Expected | Actual | Status |
| --- | --- | --- | --- |
| Grafana healthy | database ok | `database: ok`, v13.0.1 | ✅ |
| Grafana version | 13.0.1 | 13.0.1 | ✅ |
| Grafana container/port | `grafana` :3000 | `grafana`, 3000→0.0.0.0 & [::] | ✅ |
| Grafana networks | aegis-net reachable | `aegis-net` + `bridge` | ✅ |
| Grafana volume | grafana-storage | `grafana-storage`→/var/lib/grafana | ✅ |
| aegis-csv healthy | healthy | healthy (aegis-net) | ✅ |
| Infinity datasource | provisioned | `aegis-infinity.yaml`, uid `aegis-forecast-drift-csv` | ✅ |
| V2 counts | 168/672/71/1 | 168/672/71/1 | ✅ |
| V1 unchanged | hashes = baseline | 4/4 SHA256 match; V1==V2 | ✅ |
| Docker | present | Engine 29.6.1 | ✅ |
| Docker Compose | present | v5.3.0 | ✅ |
| Claude Code | present | CLI 2.1.116 | ✅ |
| OS / arch | Windows x64 | Windows 10.0.26200, AMD64 | ✅ |
| Git status | clean/known | clean; HEAD==origin/main | ⚠️ auto-commit externo |
| Auto-commit/push | detected | active (commits `add`; committed E7B.0) | ⚠️ R1 |

## 2. Claude Code MCP readiness

| Área | Estado actual | Recomendación |
| --- | --- | --- |
| Soporte MCP | Claude Code CLI 2.1.116 (soporta servidores MCP) | Usar `claude mcp add` en E7B.4 |
| Config MCP (user) | `~/.claude.json` (26.7 KB); `mcpServers` vacío | Mantener limpio; registrar en **local scope** |
| Config MCP (project) | sin `.mcp.json`, sin `.vscode/mcp.json` | No crear archivos con secretos versionados |
| Servidores registrados | **ninguno** (user y project) | Estado MCP limpio — registrar solo `grafana` |
| Alcance apropiado | n/a | **local** (`-s local`): por-proyecto, NO commiteado |
| Tokens en JSON/Git | riesgo con project scope + auto-commit | Nunca inline; usar `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` |
| Variables de entorno | soportadas | Token vía archivo git-ignored; sólo referencia en config |
| Reproducibilidad sin secretos | posible | Documentar comando `claude mcp add` + `.env.example` (sin valores) |

## 3. mcp-grafana compatibility (fuentes oficiales)

**Fuente:** `https://github.com/grafana/mcp-grafana` (consultada 2026-07-17).

| Ítem | Hallazgo |
| --- | --- |
| Nombre oficial | Grafana MCP server (`mcp-grafana`) |
| Repositorio | github.com/grafana/mcp-grafana (Apache-2.0) |
| Última versión estable | **v0.17.2** (~4 días antes de la consulta) |
| Imagen Docker oficial | `grafana/mcp-grafana` (Docker Hub) — entrypoint **SSE por defecto**; requiere `-t stdio -i` |
| Binario oficial | GitHub Releases (windows/amd64); o `go install .../cmd/mcp-grafana@v0.17.2`; o `uvx mcp-grafana` |
| Requisito Grafana | **≥ 9.0** (tenemos 13.0.1 ✅) |
| Arquitecturas | linux/darwin/windows amd64+arm64 |
| Transportes | `stdio` (default), `sse`, `streamable-http` |
| Auth | `GRAFANA_SERVICE_ACCOUNT_TOKEN` (preferido), `..._TOKEN_FILE` (lee fresco cada request), `GRAFANA_API_KEY` (deprecado), user/password básico |
| Read-only global | flag `--disable-write` |
| Limitar tools | `--enabled-tools "cat,.."` y `--disable-<category>` |
| Datasources | `list_datasources`, `get_datasource` |
| Folders | `create_folder` (write); listado vía tools de dashboards/search |
| Dashboards | `search_dashboards`, `get_dashboard_by_uid`/`_summary`/`_property`, `update_dashboard` (crea/actualiza) |
| **Consultar datos CSV/Infinity** | ⚠️ **No hay tool nativo de query Infinity/CSV.** Query tools sólo para Prometheus/Loki/InfluxDB/ClickHouse/etc. Para leer datos del CSV vía MCP hay que construir un panel Infinity y usar `run_panel_query` (deshabilitado por defecto; `runpanelquery`). |
| Riesgos/limitaciones | imagen Docker por defecto SSE (fácil de mal configurar); `latest` no aceptable → fijar v0.17.2; sin health tool en stdio (usar `list_datasources` como smoke). |

## 4. Outcome

**`E7B1_MCP_PREFLIGHT_COMPLETED`** — arquitectura, permisos, manejo de secretos,
allow-list y plan E7B.2–E7B.5 definidos. Sin blockers reales para E7B.2.
Ver documentos hermanos: `E7B1_mcp_architecture_decision.md`,
`E7B1_permissions_and_secret_design.md`, `E7B1_tool_allowlist.md`,
`E7B1_implementation_plan.md`, `E7B1_closure_summary.md`.
