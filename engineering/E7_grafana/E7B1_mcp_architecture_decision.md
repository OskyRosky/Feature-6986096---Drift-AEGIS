# E7B.1 — MCP Execution Architecture Decision

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.1.** Date: 2026-07-17.

Decision on **how and where** to run the official Grafana MCP server (`mcp-grafana`)
so Claude Code can reach Grafana safely and reproducibly.

## Key facts driving the decision

- Grafana publishes port **3000 on the host** (`0.0.0.0:3000` and `[::]:3000`).
- Grafana container is attached to **`aegis-net` + `bridge`**; DNS name `grafana`
  resolves inside `aegis-net`.
- Claude Code (CLI 2.1.116) natively spawns **stdio** MCP servers as child
  processes on the Windows host.
- `localhost` **inside a container does NOT reach the host** — a containerized MCP
  must use `host.docker.internal` (host) or `grafana` (if on `aegis-net`).

## Alternatives

| Alternativa | Pros | Contras | Riesgos | Recomendación |
| --- | --- | --- | --- | --- |
| **A. Binario/uvx en el host (stdio), `GRAFANA_URL=http://localhost:3000`** | Integración nativa stdio de Claude Code; sin red Docker; rollback trivial (quitar registro); no toca `aegis-net` ni contenedores; token vía archivo local | Requiere binario fijado en el host (o uv para uvx) | Mínimos; el proceso corre en el host del usuario | ✅ **RECOMENDADA** |
| B. Contenedor Docker fuera de `aegis-net` (stdio), `GRAFANA_URL=http://host.docker.internal:3000` | Aísla el binario; imagen fijada por digest | `docker run -i` por cada sesión; token vía `-e` (riesgo de exposición en args/ps); depende de `host.docker.internal` | Token visible en línea de comando; complejidad extra | ⚠️ alternativa |
| C. Contenedor unido a `aegis-net` (stdio), `GRAFANA_URL=http://grafana:3000` | DNS interno directo | **Toca la red de producción** `aegis-net`; recrea/una contenedores; token vía `-e` | Riesgo para el stack Grafana existente; mayor superficie | ❌ evitar |

### Evaluación por criterio (resumen)

| Criterio | A (host stdio) | B (docker host.docker.internal) | C (docker aegis-net) |
| --- | --- | --- | --- |
| Conectividad | localhost:3000 directo ✅ | host.docker.internal ✅ | grafana:3000 ✅ |
| Complejidad | Baja | Media | Alta |
| Seguridad | Alta (token en archivo) | Media (token en `-e`) | Media/baja |
| Manejo del token | `..._TOKEN_FILE` git-ignored | `-e` inline (riesgo) | `-e` inline (riesgo) |
| Compat. Claude Code | Nativa (stdio) | stdio vía `docker -i` | stdio vía `docker -i` |
| Persistencia | Ninguna (efímero por sesión) | Efímero (`--rm`) | Efímero |
| Reproducibilidad | Alta (versión fijada + comando `claude mcp add`) | Alta (digest) | Alta (digest) |
| Rollback | Trivial (quitar registro MCP) | Trivial | Requiere limpiar red |
| Riesgo a Grafana existente | Ninguno | Bajo | **Alto** (aegis-net) |

## Decisión

**Alternativa A — `mcp-grafana` como binario nativo fijado (v0.17.2, windows/amd64)
ejecutado en modo `stdio` en el host, registrado en Claude Code en scope `local`,
con `GRAFANA_URL=http://localhost:3000` y token vía
`GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE`.**

### Justificación
1. Grafana ya expone `:3000` en el host → `localhost:3000` funciona sin red Docker.
2. `stdio` es la integración nativa de Claude Code (sin puertos, sin SSE/HTTP,
   sin exposición de red → superficie mínima; la protección anti DNS-rebinding de
   HTTP no es siquiera necesaria).
3. **No toca `aegis-net` ni los contenedores** `grafana`/`aegis-csv` → cero riesgo
   para el stack existente (a diferencia de C).
4. Token en **archivo git-ignored** leído fresco por request → rotación sin
   reinicio y sin exponer el secreto en argumentos/entorno visibles (mejor que B/C).
5. Rollback trivial: `claude mcp remove grafana` (sin residuos de red/contenedor).

### Por qué binario y no `latest`/uvx/Docker
- `latest` no es aceptable (reproducibilidad) → **fijar v0.17.2**.
- Binario windows/amd64 desde GitHub Releases oficiales = self-contained, sin
  dependencia de Python (`uvx`) ni del daemon Docker.
- `uvx mcp-grafana` queda como alternativa válida si se prefiere Python; también
  debe fijarse la versión.

## URL efectiva y transporte
- Transporte: **stdio** (default; sin `-p`, sin `/healthz` HTTP).
- `GRAFANA_URL=http://localhost:3000`.
- Smoke de conectividad (E7B.4): `list_datasources` (no existe health tool en stdio).
