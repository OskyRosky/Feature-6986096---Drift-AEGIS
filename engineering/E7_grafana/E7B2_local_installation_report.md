# E7B.2 — Local Installation Report

**Feature 6986096 — AEGIS Forecast Drift Framework.** Stage: **E7B.2.** Date: 2026-07-17.

## Installation location (outside the repository)

| Elemento | Ruta seleccionada | Justificación |
| --- | --- | --- |
| Raíz de instalación | `%LOCALAPPDATA%\AEGIS\mcp-grafana\v0.17.2\` | Fuera del repo → el auto-commit/push externo (R1) **no** puede publicar el binario |
| Ejecutable | `…\v0.17.2\mcp-grafana.exe` | Binario oficial verificado |
| PATH global | **No modificado** | Se invoca por ruta absoluta; evita efectos colaterales en el sistema |
| Copia dentro de V2 | **No** | El binario nunca se copia al repositorio |

## Final directory contents

| Archivo | Tamaño | Propósito |
| --- | --- | --- |
| `mcp-grafana.exe` | 52,755,456 bytes | Binario oficial v0.17.2 |
| `LICENSE` | 11,342 bytes | Apache-2.0 (del paquete oficial) |
| `checksums.official.txt` | 1,324 bytes | Copia del `mcp-grafana_0.17.2_checksums.txt` oficial |
| `SHA256SUMS.local.txt` | 203 bytes | Registro local: hash del archivo + del exe |

`README.md` y `CHANGELOG.md` del paquete se removieron para dejar la ruta final
únicamente con los elementos requeridos.

## Binary validation (local only, no Grafana, no token)

| Validación | Resultado |
| --- | --- |
| `mcp-grafana.exe --version` | **`0.17.2`** ✅ |
| `mcp-grafana.exe --help` | ejecuta sin dependencias faltantes ✅ |
| Transporte STDIO | soportado (`-t` / `-transport`, default `stdio`) ✅ |
| Flags de limitación de tools | `-enabled-tools`, `-disable-write`, `-disable-datasource`, `-disable-dashboard`, `-disable-folder`, etc. ✅ |
| Default `enabled-tools` | `search,datasource,incident,prometheus,loki,alerting,dashboard,folder,oncall,asserts,sift,pyroscope,navigation,proxied,annotations,rendering,snapshot,plugin,api,config,provisioning` |
| Servidor persistente | **no iniciado** ✅ |
| Conexión a Grafana | **no realizada** ✅ |
| Proceso residual | **ninguno** (`Get-Process mcp-grafana` = 0) ✅ |
| Renombrado por Windows | no — el exe conserva su nombre ✅ |

## Reproducible scripts (in-repo, secret-free)

| Archivo (`V2/scripts/`) | Función |
| --- | --- |
| `install-mcp-grafana.ps1` | Instalador idempotente: versión fijada, detección de arquitectura, descarga oficial, verificación SHA256 (pinned + checksums.txt), instala fuera del repo, no toca PATH, falla de forma segura |
| `verify-mcp-grafana.ps1` | Verificador read-only: localiza binario, valida versión + checksum, corre `--help`, sin token, sin conexión a Grafana |
| `mcp-grafana-install-manifest.json` | Manifiesto sin secretos: versión, repo oficial, asset, SHA256, arquitectura, ruta plantilla, timestamp |

Ambos scripts se ejecutaron con éxito: `verify` valida el binario; `install` es
idempotente (segunda ejecución = *"Already installed and valid … Nothing to do."*).
