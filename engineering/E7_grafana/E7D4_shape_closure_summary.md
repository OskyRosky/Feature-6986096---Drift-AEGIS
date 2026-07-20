# E7D.4 — Shape MVP · Closure Summary

**Status token: `E7D4_SHAPE_MVP_COMPLETED_VISUALLY_ACCEPTED`**
Dashboard: **AEGIS Forecast Drift — Shape** · uid `aegis-forecast-drift-shape` · v3 · 10 panels
URL: `http://localhost:3000/d/aegis-forecast-drift-shape` · Folder: *AEGIS Forecast Drift* (`afsjccp27s0e8d`).

> **Visually accepted by Oscar (2026-07-19)** — metrics, details table and governance approved. A minor
> post-acceptance polish was applied to the trend panel only (v3): time range starts at the first real data
> (2024-04-01, removing the empty pre-2024 space) and `lineInterpolation` changed **smooth → linear** with real
> per-version points kept visible. No query / metric / filter / KPI / table / other-dashboard change. KPIs
> re-verified intact: 26.03 / 168 / 100.0 % / 100.00 / DQ 18/18.

## Estado por fase
| # | Fase | Resultado |
|---|------|-----------|
| 1 | Precheck | ✅ git HEAD==origin/main; grafana Up, aegis-csv healthy; CSVs presentes; Overview/Forecast/Performance intactos |
| 2 | Inspección / Ground Truth | ✅ 168 señales; computable 168; coverage 100.0 %; avg 26.03; max 100.00; 3 baselines PBI coinciden |
| 3 | Filtros | ✅ 5 variables (queryType infinity); version → `fv_label`; contrato de filtro compartido |
| 4 | Componentes | ✅ 10 paneles definidos (sin Non-computable Summary por 168/168; sin KPI MAPE por ausencia de métrica auxiliar) |
| 5 | Layout | ✅ nav+header, fila KPI (A/B/C/D), trend full-width, details full-width, run + DQ |
| 6 | Construcción incremental | ✅ JSON reescrito desde shell; shell archivado en `archive/` |
| 7 | Validadores | ✅ 0 fallos (estructura, vars, ds por uid, convertFieldType antes de reducers, sin secretos, sin lenguaje shell) |
| 8 | Reconciliación | ✅ 0 discrepancias vs CSV (KPIs + 14 puntos de trend) |
| 9 | Pruebas de filtros | ✅ denominador dinámico; coverage 100 %; key inexistente → vacío sin error |
| 10 | Publicación | ✅ `push-e7d4-shape.ps1` → v2, inFolder=True, 10 paneles |
| 11 | Artefactos | ✅ 5 docs + PROJECT_STATUS / ROADMAP / README actualizados |

## KPIs
| KPI | Fórmula | CSV esperado | Grafana | Estado |
|-----|---------|-------------:|--------:|:------:|
| Average Shape Drift Score | mean(shape_drift_score) | 26.03 | 26.03 | ✅ |
| Shape Signals Computable | count(shape_drift_score≠'') | 168 | 168 | ✅ |
| Shape Coverage | mean(is_comp→number) | 100.0 % | 100.0 % | ✅ |
| Maximum Shape Drift Score | max(shape_drift_score) | 100.00 | 100.00 | ✅ |

## Paneles
| Panel | Fuente | Filtros | Resultado | Estado |
|-------|--------|---------|-----------|:------:|
| Nav / Header (text) | — | — | Shape marcado | ✅ |
| A Average Shape Drift Score | signals | compartido | 26.03 | ✅ |
| B Shape Signals Computable | signals | compartido | 168 | ✅ |
| C Shape Coverage | signals | sin cláusula computabilidad | 100.0 % | ✅ |
| D Maximum Shape Drift Score | signals | compartido | 100.00 | ✅ |
| E Shape Drift Score Over Time | signals | compartido − fv_label | 14 puntos, pico 62.60 | ✅ |
| F Shape Signal Details | signals | compartido | orden score desc | ✅ |
| H Latest Governed Run | runs | run_id | run 1 Success 18/18 | ✅ |
| I Data Quality — Checks Passed | runs | run_id | 18/18 | ✅ |

## Filtros
| Prueba | Esperado CSV | Grafana | Estado |
|--------|-------------:|--------:|:------:|
| All | 168 / 26.03 / 100 % | 168 / 26.03 / 100 % | ✅ |
| forecast_key=NAM-SDF | 14 / 42.22 | 14 / 42.22 | ✅ |
| region=NAM | 42 / 36.50 | 42 / 36.50 | ✅ |
| drift_status=Critical | 14 / 89.45 | 14 / 89.45 | ✅ |
| forecast_version=v2025-12-01 | 12 / 62.60 | 12 / 62.60 | ✅ |
| key inexistente | 0 (vacío) | 0 (vacío) | ✅ |

## Diferencia E7D.4 vs E7D.5
- **E7D.4 = Shape** (completada aquí, pendiente aceptación visual): divergencia de trayectoria/perfil, 40 % peso.
- **E7D.5 = Stability** (siguiente familia, **NO iniciada**): estabilidad temporal de la señal. Se abordará solo
  con nueva autorización explícita.

## Cierre
| Ítem | Valor |
|------|-------|
| Token | `E7D4_SHAPE_MVP_COMPLETED_VISUALLY_ACCEPTED` |
| Paneles | 10 |
| Discrepancias | 0 |
| Aceptación visual | **Aceptada por Oscar (2026-07-19)** |
| Autorización requerida para E7D.5 | **Sí** |

**Detenido antes de E7D.5**, según lo indicado. Token promovido a
`E7D4_SHAPE_MVP_COMPLETED_VISUALLY_ACCEPTED` aquí y en los 3 docs de estado.
