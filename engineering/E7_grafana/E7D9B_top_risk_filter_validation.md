# E7D.9B — Top Risk · Filter Validation

Shared template variables (all `includeAll`, `multi`, sorted): **Forecast Key · Forecast Version · Region · Drift Status · Run ID**. Forecast Version emits `__value = 'v' + forecast_version` so panel filters (`fv_label IN (...)`) match reliably.

Every signals panel reacts to all 5 filters. Family panels (id50/id51) react to Forecast Key + Forecast Version only (family_scores lacks region/status/run columns — documented deviation; Region still narrows via 1:1 key mapping).

## Expected results (recomputed from CSV, for Oscar's live click-through)

| Filter scenario | Signals | Avg | Critical | Events | Notes |
|-----------------|---------|-----|----------|--------|-------|
| **All** | 168 | 28.83 | 14 | 71 | full universe |
| Forecast Key = NAM-SDF | 14 | 42.74 | 4 | 10 | highest-risk key |
| Region = NAM | 42 | 39.18 | 9 | 29 | 3 keys (SDF, MULTITENANT, MSIT) |
| Drift Status = Critical | 14 | — | 14 | — | Critical KPI = total = 14 |
| Forecast Version = 2025-12-01 | 12 | 53.25 | 3 | — | worst version |
| Run ID = 1 | 168 | 28.83 | 14 | 71 | single governed run |
| Forecast Key = NAM-SDF + Region = NAM | 14 | 42.74 | 4 | 10 | consistent (key ⊂ region) |
| Region = NAM + Drift Status = Critical | 9 | — | 9 | — | NAM critical subset |
| back to All | 168 | 28.83 | 14 | 71 | ranking restored |

## Ranking-change checks
- Selecting Region = NAM promotes NAM-SDF / NAM-MULTITENANT / NAM-MSIT and drops all other keys from the Forecast Key panels.
- Selecting Drift Status = Critical narrows every signals panel to the 14 critical signals; the Forecast Key Risk Summary then shows only keys carrying critical signals with Worst Status = Critical.
- Family panels remain stable under Region/Status/Run changes (documented) but react to Forecast Key / Forecast Version.

## Validation method
Row counts and aggregates above are computed from the served CSVs (sole truth). Live datasource confirmed responsive via `/api/ds/query`. **Visual per-filter click validation is performed by Oscar in his authenticated Grafana session** (agent browser is unauthenticated).
