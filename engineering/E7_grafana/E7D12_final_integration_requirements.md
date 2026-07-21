# E7D.12 — Final Integration, Regression Validation & Deployment Readiness (Requirements)

**Stage:** E7D.12 (last internal Grafana build/validation stage for AEGIS Forecast Drift V2)
**Authorized by:** Oscar — "Autorizo iniciar E7D.12"
**Date:** 2026-07-20
**Status:** Technical validation PASS — pending visual acceptance

## Purpose
Consolidate the ten active AEGIS Forecast Drift dashboards into a single, governed,
reproducible, locally-runnable product and prove — with evidence — that it is
regression-clean and **ready** for a future corporate portal deployment. This stage
does **not** deploy.

## Hard constraints (verbatim intent)
- NO deployment to the corporate portal.
- NO connection to corporate infrastructure.
- NO Azure resources created.
- NO publishing beyond `localhost`.
- NO new functional version started.
- No new features added.
- Stop after E7D.12 closure. Do not start the deployment.

## In-scope changes (only these)
- Governed data refresh / sync (idempotent, transactional) + automated 18-check
  data-quality catalog regeneration.
- `aegis-csv` container resilience (`restart: unless-stopped`) — already satisfied.
- Local startup / shutdown scripts.
- Read-only validators.
- Documentation, backup/rollback package, deployment-readiness package.

## Out-of-scope (must NOT change)
Drift formulas, family weights, thresholds/classifications, source data, V1 Python
calculation logic, PowerBI V1, dashboard UIDs, datasource UID, DPAPI token, MCP
configuration, corporate permissions. No plugins, no alerts, no dashboard deletion,
no deletion of the retired Top Scenarios dashboard, no manual commit.

## The ten active dashboards (navigation order)
1. Overview · 2. Forecast · 3. Performance · 4. Shape · 5. Stability ·
6. Volatility · 7. Events · 8. Historical Timeline · 9. Top Risk ·
10. Settings & Data Quality.

**Top Scenarios** is retired from navigation (absorbed into Top Risk) and preserved
for rollback only.

## Governance principle
"El dashboard no cocina datos." All drift logic lives in the V1 Python engine.
V2 dashboards read governed, SHA256-verified CSVs only.
