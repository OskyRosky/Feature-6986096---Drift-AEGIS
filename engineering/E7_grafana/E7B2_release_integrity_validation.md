# E7B.2 — Release Integrity Validation

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.2.** Date: 2026-07-17.

**Source (authorized only):** `https://github.com/grafana/mcp-grafana` (official repo).
No mirrors, forks, blogs, or third-party binaries were used.

## Official release

| Ítem | Valor |
| --- | --- |
| Tag | **v0.17.2** |
| Publicación | ≈2026-07-13 (hace 4 días, consultado 2026-07-17) |
| Publicado por | `github-actions` (CI oficial del repo) |
| Commit | `fac7c8a312c6f6aee8330de72182dcf45bf4ae26` — **Verified commit signature** |
| Licencia | Apache-2.0 |
| Requisito Grafana | ≥ 9.0 |
| Compatibilidad con Grafana 13.0.1 | ✅ Compatible |
| Archivo de checksums oficial | `mcp-grafana_0.17.2_checksums.txt` (disponible) |

## Asset seleccionado (arquitectura detectada: AMD64)

| Ítem | Valor |
| --- | --- |
| Asset | `mcp-grafana_Windows_x86_64.zip` (goreleaser estándar, 15.34 MB) |
| Alternativa descartada | `win32.x64.grafana.zip` (empaquetado de extensión de escritorio/DXT, no binario standalone) |

## Verificación de integridad (SHA256)

| Asset | Expected SHA256 | Actual SHA256 | Status |
| --- | --- | --- | --- |
| `mcp-grafana_Windows_x86_64.zip` (página release) | `939eb0f4ecc6a6e2ded979b658ba18233d6939f5af1a5ed9e17b8a7a5eb62616` | `939eb0f4ecc6a6e2ded979b658ba18233d6939f5af1a5ed9e17b8a7a5eb62616` | ✅ MATCH |
| `mcp-grafana_Windows_x86_64.zip` (checksums.txt oficial) | `939eb0f4…eb62616` | `939eb0f4…eb62616` | ✅ MATCH |
| `mcp-grafana.exe` (extraído) | — | `39710095e02ecb91630bce04cbee0983d3e5dae25d4ee492c5e57b5b3b26a2d8` | ℹ️ registrado |

**Doble verificación:** el hash local coincide **tanto** con el valor publicado en la
página de la release **como** con el archivo oficial de checksums. Integridad
confirmada. No hay condiciones de BLOCKED (asset oficial existe, checksum verificable,
arquitectura coincide, release oficial firmada).
