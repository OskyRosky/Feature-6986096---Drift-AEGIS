# PROJECT STATUS — AEGIS Forecast Drift Framework

**Feature 6986096 — Integrate Cross-Functional Capacity Feedback Signals to Align and Improve Capacity Mitigation Actions**
Last updated: 2026-07-13

> Microsoft internal / confidential. Engineering stages (E-prefix) build the product; product/document versions (V1/V2/V3) are separate. See `engineering/ROADMAP.md`.

## Current stage
**E5B — Production Dataset Validation & Export Hardening: PARTIAL** (offline code
hardening + deterministic validation complete: I1 canonicalization, I2 UTF-8
logging, I3 deep Performance, atomic export, `run_refresh` runner, 18/18 checks,
triple-run idempotency, frozen contract, Power BI boundary). Remaining: run the
**live expanded real sample** (read-only, VPN+MFA) to flip to COMPLETED. Not
E5B = SQL: no DDL, no SQL tables/views, no writes to Tesseract.

## Stage status
| Stage | Name | Status |
| --- | --- | --- |
| E0 | Foundation (Blueprint, Mockup, Git, Governance) | ✅ Complete |
| E1A | Source Discovery & Data Profiling — Document Discovery & Reuse | ✅ Complete |
| E1B | Source Discovery & Data Profiling — Live Data Validation | ✅ Complete (all 4 families computable) |
| E2 | Forecast Drift Information Model | ✅ Complete |
| E3 | Mathematical Drift Model | ✅ Complete |
| E4 | Output Schema Design | ✅ Complete |
| E5A | Python Drift Engine | ✅ Complete |
| E5B | Production Dataset Validation & Export Hardening | ◑ Partial (offline done; live sample pending) |
| E6 | Power BI MVP (local, consume-only) | ⏳ |
| E7 | Grafana MVP (local, consume-only) | ⏳ |
| E8 | Cloud Deployment & Governance | ⏳ |

## Key validated facts (E1B)
- Source `forecast_substrateBE_hdd_region`: 48 monthly Enterprise ForecastVersions (2021-06 → 2026-05); 177,898 multi-version (Key, target) cells; one model per Key×version.
- Official metrics (`*_metrics`) carry MAPE/Bias/Accuracy but only 3 retained versions.
- Actuals 2019-07 → 2026-05; forecast horizon → 2030-04.

## Open gaps
G1 dedupe FV 2025-06-01 (resolved in E2 design) · G2 shallow metric history · G3 no Service column · G4 region↔forest mapping · G5 scenario scope (MVP=Enterprise) · G6 forward-only rule (resolved in E2 design) · G7 TTL view not probed.

## Deliverables index
- `engineering/ROADMAP.md`
- `engineering/E1_source_discovery_profiling/` — E1A source profiling, data dictionary, open questions, closure; E1B live data validation.
- `engineering/E2_information_model/` — information model, entity catalog, relationship matrix, drift-family input matrix, lineage map, open decisions, closure.

## Governance invariants
AEGIS produces governed drift signals; downstream consumes. Read-only against source; no data mutation; no productive SQL/PBI/Grafana yet. Confidential — no server host/credentials in repo.
