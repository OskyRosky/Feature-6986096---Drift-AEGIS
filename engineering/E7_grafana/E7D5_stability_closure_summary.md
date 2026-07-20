# E7D.5 — Stability MVP · Closure Summary

**Status token: `E7D5_STABILITY_MVP_COMPLETED_VISUALLY_ACCEPTED`**
Dashboard: **AEGIS Forecast Drift — Stability** · uid `aegis-forecast-drift-stability` · v2 · 10 panels
URL: `http://localhost:3000/d/aegis-forecast-drift-stability` · Folder: *AEGIS Forecast Drift* (`afsjccp27s0e8d`).

> Built by cloning the **visually-accepted Shape (E7D.4)** structure and swapping the governed metric to
> `stability_drift_score` (family weight **30 %**). Polish accepted for Shape v3 was applied from the start:
> time range starts at the first real data (**2024-04-01**), trend `lineInterpolation = linear`, per-version
> points visible. Structural validation and reconciliation are green; **awaiting Oscar's visual acceptance**.

## Estado por fase
| # | Fase | Resultado |
|---|------|-----------|
| 1 | Precheck | ✅ git HEAD==origin/main; grafana Up, aegis-csv healthy; CSVs presentes; Overview/Forecast/Performance/Shape intactos |
| 2 | Inspección / Ground Truth | ✅ 168 señales; computable 168; coverage 100.0 %; avg 38.93; max 100.00 |
| 3 | Filtros | ✅ 5 variables (queryType infinity); version → `fv_label`; contrato de filtro compartido |
| 4 | Componentes | ✅ 10 paneles (sin Non-computable Summary por 168/168; sin KPI MAPE por ausencia de métrica auxiliar) |
| 5 | Layout | ✅ nav+header, fila KPI (A/B/C/D), trend full-width, details full-width, run + DQ |
| 6 | Construcción incremental | ✅ JSON reescrito desde shell; shell archivado en `archive/` |
| 7 | Validadores | ✅ 0 fallos reales (estructura, 5 vars wrapped, ds por uid, convertFieldType antes de reducers, sin secretos, sin lenguaje shell; hermanos intactos) |
| 8 | Reconciliación | ✅ 0 discrepancias vs CSV (KPIs + 14 puntos de trend) |
| 9 | Pruebas de filtros | ✅ denominador dinámico; coverage 100 %; key inexistente → vacío sin error |
| 10 | Publicación | ✅ `push-e7d5-stability.ps1` → v2, inFolder=True, 10 paneles |
| 11 | Artefactos | ✅ 5 docs + PROJECT_STATUS / ROADMAP / README actualizados |

## KPIs
| KPI | Fórmula | CSV esperado | Grafana | Estado |
|-----|---------|-------------:|--------:|:------:|
| Average Stability Drift Score | mean(stability_drift_score) | 38.93 | 38.93 | ✅ |
| Stability Signals Computable | count(stability_drift_score≠'') | 168 | 168 | ✅ |
| Stability Coverage | mean(is_comp→number) | 100.0 % | 100.0 % | ✅ |
| Maximum Stability Drift Score | max(stability_drift_score) | 100.00 | 100.00 | ✅ |

## Paneles
| Panel | Fuente | Filtros | Resultado | Estado |
|-------|--------|---------|-----------|:------:|
| Nav / Header (text) | — | — | Stability marcado | ✅ |
| A Average Stability Drift Score | signals | compartido | 38.93 | ✅ |
| B Stability Signals Computable | signals | compartido | 168 | ✅ |
| C Stability Coverage | signals | sin cláusula computabilidad | 100.0 % | ✅ |
| D Maximum Stability Drift Score | signals | compartido | 100.00 | ✅ |
| E Stability Drift Score Over Time | signals | compartido − fv_label | 14 puntos, pico 74.14 | ✅ |
| F Stability Signal Details | signals | compartido | orden score desc | ✅ |
| H Latest Governed Run | runs | run_id | run 1 Success 18/18 | ✅ |
| I Data Quality — Checks Passed | runs | run_id | 18/18 | ✅ |

## Filtros
| Prueba | Esperado CSV | Grafana | Estado |
|--------|-------------:|--------:|:------:|
| All | 168 / 38.93 / 100 % | 168 / 38.93 / 100 % | ✅ |
| forecast_key=NAM-SDF | 14 / 54.78 | 14 / 54.78 | ✅ |
| region=NAM | 42 / 50.71 | 42 / 50.71 | ✅ |
| drift_status=Critical | 14 / 95.35 | 14 / 95.35 | ✅ |
| forecast_version=v2025-12-01 | 12 / 74.14 | 12 / 74.14 | ✅ |
| key inexistente | 0 (vacío) | 0 (vacío) | ✅ |

## Diferencia E7D.5 vs E7D.6
- **E7D.5 = Stability** (completada aquí, pendiente aceptación visual): estabilidad temporal / comportamiento de
  revisión acumulada entre versiones, **30 %** peso.
- **E7D.6 = Volatility** (siguiente familia, **NO iniciada**): dispersión / oscilación de la señal
  (`rolling_stddev`, `cov`, `mad`, `oscillation`, `sign_change_freq`), **10 %** peso. Se abordará solo con nueva
  autorización explícita.

## Cierre
| Ítem | Valor |
|------|-------|
| Token | `E7D5_STABILITY_MVP_IMPLEMENTED_PENDING_VISUAL_ACCEPTANCE` |
| Paneles | 10 |
| Discrepancias | 0 |
| Aceptación visual | **Aceptada por Oscar (2026-07-19)** |
| Autorización requerida para E7D.6 | **Sí** |

**Oscar aceptó visualmente E7D.5 el 2026-07-19.** Token promovido a
`E7D5_STABILITY_MVP_COMPLETED_VISUALLY_ACCEPTED`. Autorizado iniciar E7D.6 (Volatility).
