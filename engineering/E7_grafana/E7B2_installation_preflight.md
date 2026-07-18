# E7B.2 — Installation Preflight

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.2 — Install Pinned
Grafana MCP Server.** Date: 2026-07-17. Architecture: **A** (local binary on Windows host).

> Read-only preflight executed **before** any download. No connection to Grafana, no
> credentials, no service account, no token.

| Check | Expected | Actual | Status |
| --- | --- | --- | --- |
| Sistema operativo | Windows | Windows 11 Enterprise 10.0.26200 | ✅ |
| Arquitectura | amd64 / x86_64 | AMD64 / X64 | ✅ |
| PowerShell | presente | 7.6.3 (Core) | ✅ |
| Espacio en disco C: | suficiente | 1694.5 GB libres | ✅ |
| Claude Code | presente | 2.1.116 | ✅ |
| MCP servers registrados | ninguno | `No MCP servers configured` | ✅ |
| Binario mcp-grafana previo | ausente | no en PATH | ✅ |
| Directorio de instalación previo | ausente | `%LOCALAPPDATA%\AEGIS\mcp-grafana` inexistente | ✅ |
| `.mcp.json` | ausente | False | ✅ |
| `.vscode/mcp.json` | ausente | False | ✅ |
| Grafana | healthy | `database: ok`, v13.0.1 | ✅ |
| aegis-csv | healthy | Up 9h (healthy) | ✅ |
| Conteos V2 | 168 / 672 / 71 / 1 | 168 / 672 / 71 / 1 | ✅ |
| V1 sin cambios | intacto | sin rutas `V1/` en git | ✅ |
| Git status | conocido | limpio; HEAD == origin `b60f2b9` | ⚠️ R1 |
| Auto-commit/push externo | detectar | **fired** — `b60f2b9 "add"` commiteó+pusheó las correcciones E7B.1; observado, no modificado | ⚠️ R1 |

**Conclusión:** entorno apto para instalar el binario oficial `mcp-grafana` v0.17.2 en
arquitectura windows/amd64. Sin blockers de preflight.
