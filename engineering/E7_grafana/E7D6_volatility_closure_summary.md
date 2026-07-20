# E7D.6 — Volatility MVP · Closure Summary

**Status token: `E7D6_VOLATILITY_MVP_COMPLETED_VISUALLY_ACCEPTED`** (visually accepted by Oscar 2026-07-19)
Dashboard: **AEGIS Forecast Drift — Volatility** · uid `aegis-forecast-drift-volatility` · v3 · 13 panels
URL: `http://localhost:3000/d/aegis-forecast-drift-volatility` · Folder: *AEGIS Forecast Drift* (`afsjccp27s0e8d`).

> **Post-acceptance polish (v3, 2026-07-19):** (1) Volatility Drift Score Over Time — confirmed the saved time
> range begins at the first real bucket (`from = 2024-06-01`, the 12 computable buckets span 2024-06-01 →
> 2026-05-01); `lineInterpolation=linear` and `showPoints=always` preserved; query and 12 buckets unchanged. The
> "empty space from 2021" was a client-side time-range override (inherited `now-5y`), not in the saved model —
> resolved by opening the canonical dashboard URL. (2) Volatility Profile — `rolling_stddev` raw values span
> **221.6 → 1,270,234** (no governed unit; native dispersion scale). Grafana's inherited `short` unit abbreviated
> them inconsistently as **K / Mil**; replaced with explicit **`locale`** unit (full thousands-grouped integer,
> e.g. `1,270,234`) — no data recalculated. KPIs re-verified unchanged after republish.

> **Shared navigation-contract fix (v4, 2026-07-19):** the **AEGIS Sections** dropdown (`dashboard.links`, tag
> `aegis-nav`) had `keepTime: true` → it carried the **live** (possibly user-zoomed) time range of the previous
> dashboard into the target, so navigating into Volatility showed a stale wide window (the "from 2021" report;
> source saved ranges are actually 2024-03/2024-04, but `keepTime` propagates whatever the user last applied).
> **Fix:** `keepTime: false` (target loads its **own** saved range — Volatility 2024-06-01 → 2026-06-01) and
> `includeVars: true` (preserve the five global filters Forecast Key / Forecast Version / Region / Drift Status /
> Run ID across navigation). The markdown nav bar (id1) uses plain `/d/<uid>` links with **no** `from`/`to` and was
> not a time carrier. This is the **shared nav contract**, so it was applied and republished to **all 11**
> dashboards: foundation (Overview), forecast, performance, shape, stability, volatility, events, timeline,
> top-keys, top-scenarios, settings — **only the `links` block changed**; no queries, data, panels, filters,
> thresholds or time ranges were touched. Live-verified `keepTime=false` + `includeVars=true` on all 11.

> Built from the E7D.5 Stability lineage but **deliberately NOT a mechanical clone**. Volatility is only
> **partially computable (144/168, coverage 85.7 %)**; the 24 non-computable signals are governed by
> `not_computable_reason = INSUFFICIENT_VERSIONS` (first two versions of each key). Governed auxiliary metrics
> (`rolling_stddev`, `rolling_cov`, `rolling_mad`, `oscillation_count`, `sign_change_freq`, `volatility_class`)
> from `family_scores.csv` are surfaced in a dedicated profile table, and a Non-computable Summary + a ranking
> **barchart** are new panels. Structural validation and reconciliation are green; **awaiting Oscar's visual
> acceptance**.

## Estado por fase
| # | Fase | Resultado |
|---|------|-----------|
| 1 | Precheck | ✅ git limpio en lo relevante; grafana Up, aegis-csv healthy; CSVs presentes; Overview/Forecast/Performance/Shape/Stability intactos |
| 2 | Inspección / Ground Truth | ✅ 168 señales; computable **144**; non-computable **24**; coverage **85.7 %**; avg **56.04**; max **100.00** |
| 3 | Computabilidad parcial | ✅ 24 no-computables = 2 primeras versiones × 12 keys (`2024-04-01`,`2024-05-01`), razón `INSUFFICIENT_VERSIONS` (family_scores) |
| 4 | Métricas auxiliares | ✅ inspeccionadas: `rolling_stddev/cov/mad`, `oscillation_count`, `sign_change_freq`, `volatility_class` pobladas 144/168, en family_scores (no en signals) |
| 5 | Filtros | ✅ 5 variables (queryType infinity); version → `fv_label`; contrato compartido; `==` para igualdad en family_scores |
| 6 | Componentes | ✅ **13 paneles** (incl. Non-computable Summary + barchart ranking + Volatility Profile) |
| 7 | Layout | ✅ nav+header, fila KPI (A/B/D/E), trend full-width, barchart full-width, details full-width, profile+non-computable, run+DQ |
| 8 | Construcción | ✅ JSON reescrito desde shell; shell archivado en `archive/aegis-forecast-drift-volatility-shell.json` |
| 9 | Validadores | ✅ 0 fallos (13 paneles, 5 vars wrapped, ds por uid, convertFieldType antes de reducers, barchart, 2 fuentes CSV, sin secretos, sin lenguaje shell; hermanos intactos) |
| 10 | Reconciliación | ✅ 0 discrepancias vs CSV (KPIs + 12 buckets trend + ranking + aux + non-computable) |
| 11 | Pruebas de filtros | ✅ denominador dinámico; versión no-computable → coverage 0 %; key inexistente → vacío sin error |
| 12 | Publicación | ✅ `push-e7d6-volatility.ps1` → v2, inFolder=True, 13 paneles |
| 13 | Artefactos | ✅ 5 docs + PROJECT_STATUS / ROADMAP / README actualizados |

## KPIs
| KPI | Fórmula | CSV esperado | Grafana | Estado |
|-----|---------|-------------:|--------:|:------:|
| Average Volatility Drift Score | mean(volatility_drift_score, computable) | 56.04 | 56.04 | ✅ |
| Volatility Signals Computable | count(volatility_drift_score≠'') | 144 | 144 | ✅ |
| Volatility Coverage | mean(is_comp→number) | 85.7 % | 85.7 % | ✅ |
| Maximum Volatility Drift Score | max(volatility_drift_score) | 100.00 | 100.00 | ✅ |

## Paneles
| Panel | Fuente | Filtros | Resultado | Estado |
|-------|--------|---------|-----------|:------:|
| Nav / Header (text) | — | — | Volatility marcado, weight 10 %, 144/168 | ✅ |
| A Average Volatility Drift Score | signals | compartido +`!=''` | 56.04 | ✅ |
| B Volatility Signals Computable | signals | compartido +`!=''` | 144 | ✅ |
| D Volatility Coverage | signals | sin cláusula computabilidad | 85.7 % | ✅ |
| E Maximum Volatility Drift Score | signals | compartido +`!=''` | 100.00 | ✅ |
| F Volatility Drift Score Over Time | signals | compartido − fv_label | 12 buckets, pico 78.13@2026-01-01 | ✅ |
| G Volatility Drift Score by Forecast Key | signals | compartido +`!=''` | barchart, NAM-SDF 82.21 top | ✅ |
| H Volatility Signal Details | signals | compartido (muestra no-computables) | orden score desc | ✅ |
| I Volatility Profile — Aux Metrics | family_scores | key+version | 144 filas, orden rolling_cov | ✅ |
| J Non-computable Summary | family_scores | key+version | INSUFFICIENT_VERSIONS 24 | ✅ |
| K Latest Governed Run | runs | run_id | run 1 Success 18/18 | ✅ |
| L Data Quality — Checks Passed | runs | run_id | 18/18 | ✅ |

## Filtros
| Prueba | Esperado CSV | Grafana | Estado |
|--------|-------------:|--------:|:------:|
| All | 168 / 144 / 85.7 % / 56.04 | idem | ✅ |
| forecast_key=NAM-SDF | 14 / 12 / 82.21 | idem | ✅ |
| region=NAM | 42 / 36 / 73.63 | idem | ✅ |
| drift_status=Critical | 14 / 14 / 100 % / 87.90 | idem | ✅ |
| version=v2026-01-01 | 12 / 12 / 78.13 | idem | ✅ |
| version=v2024-04-01 (no-computable) | 12 / 0 / **0 %** | idem | ✅ |
| key inexistente | 0 (vacío) | 0 (vacío) | ✅ |

## Diferencia E7D.6 vs E7D.7
- **E7D.6 = Volatility** (completada aquí, pendiente aceptación visual): dispersión / oscilación / cambio de
  signo de la señal (`volatility_drift_score` + auxiliares gobernados), **10 %** peso, **cómputo parcial 144/168**.
- **E7D.7 = Events** (siguiente sección, **NO iniciada**): eventos de drift gobernados (`forecast_drift_events`),
  severidad, línea de tiempo de eventos. Se abordará solo con nueva autorización explícita.

## Cierre
| Ítem | Valor |
|------|-------|
| Token | `E7D6_VOLATILITY_MVP_COMPLETED_VISUALLY_ACCEPTED` |
| Paneles | 13 (v3) |
| Discrepancias | 0 |
| Aceptación visual | **Aceptada (Oscar, 2026-07-19)** |
| Autorización requerida para E7D.7 | **Sí** |

**Completado:** E7D.6 Volatility visualmente aceptado por Oscar (v3, tras pulido de rango temporal y unidad de
`rolling_stddev`). E7D.7 (Events) **NO iniciada** — requiere nueva autorización explícita. **Detenerse antes de
E7D.7.**
