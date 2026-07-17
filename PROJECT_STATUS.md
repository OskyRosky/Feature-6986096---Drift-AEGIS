# PROJECT STATUS — AEGIS Forecast Drift Framework

**Feature 6986096 — Integrate Cross-Functional Capacity Feedback Signals to Align and Improve Capacity Mitigation Actions**
Last updated: 2026-07-17

> Microsoft internal / confidential. Engineering stages (E-prefix) build the product; product/document versions (V1/V2/V3) are separate. See `engineering/ROADMAP.md`.

## Current stage
**E7B.0 — Formal Closure of E7A.1 (Infinity Query Gate): COMPLETE (2026-07-17).**
Documentation-and-evidence-only stage (no MCP, no system changes). Formally
registered and closed **E7A.1 — Infinity Functional Query Validation Gate** using
manual evidence from the user's authenticated Grafana session: datasource **Health
check successful**; one Infinity query per dataset (CSV / Backend parser / URL /
Table / GET) returned **168 / 672 / 71 / 1** in the Query Inspector. CSV parsing,
tabular usability, and null/empty tolerance = PASS; explicit per-field Grafana
type hints (Time/Number) **deferred to E7C/E7D** (no auto timestamp→Time claim).
Updated `E7A_validation_results.csv` (V14 DEFERRED→PASS; added V18–V25) and closure
docs. Tokens: E7A.1 = **E7A_INFINITY_QUERY_GATE_COMPLETED**; E7B.0 =
**E7B0_E7A1_FORMAL_CLOSURE_COMPLETED**. Deliverables:
`engineering/E7_grafana/E7A1_infinity_manual_query_evidence.md`,
`engineering/E7_grafana/E7B0_closure_summary.md`. **Open risk R1:** external
auto-commit/push to `origin/main` (commits `add`) still active — detected/reported
only. Next: **E7B.1 — MCP Preflight** — **awaiting explicit authorization**.

**E7A.2 — V2 Governed Data Snapshot & Datasource Rewire: COMPLETE (2026-07-17).**
V2 is now a **self-contained Grafana product**. Created a byte-equivalent,
SHA256-verified governed snapshot of the four V1 datasets (+ metadata +
validation) under `V2/data/processed/`, plus an idempotent sync script
`V2/scripts/sync-governed-data.ps1` (allow-list copy, count + hash validation,
manifest `data_manifest.json`, no secrets). Rewired **only** the `aegis-csv` bind
mount from `V1/data/processed/current/` to `V2/data/processed/current/`
(read-only), keeping container name, `aegis-net`, `http://aegis-csv`, datasource
uid `aegis-forecast-drift-csv`, the Grafana container, volume, and port 3000
unchanged. Restarted only `aegis-csv`. Validated: mount RW=false on V2; 4 CSVs
served (**168 / 672 / 71 / 1**); V1==V2 hashes match; Grafana healthy (13.0.1) and
reaches `http://aegis-csv`; Infinity + datasource intact; `V1/data` clean; no
secrets. Token: E7A2_V2_DATA_SNAPSHOT_COMPLETED. Deliverables in
`engineering/E7_grafana/E7A2_*`. Next: **E7B — MCP connection** — **awaiting explicit
authorization**.

**E7A — Grafana Readiness & Data Source: COMPLETE (2026-07-16).** The existing
local Grafana (Enterprise **13.0.1**, container `grafana`, port 3000, volume
`grafana-storage`) was **preserved** (not recreated). Added a read-only CSV HTTP
server `aegis-csv` (nginx:1.27-alpine) under `V2/`, serving the four governed
CSVs from `V1/data/processed/current/` on an internal `aegis-net` network (no host
port). Installed **Infinity 3.10.1** into Grafana and provisioned datasource
**`AEGIS Forecast Drift CSV`** (uid `aegis-forecast-drift-csv`). Validated: Grafana
healthy; Infinity registered; datasource provisioned; all four CSVs reachable by
DNS with exact counts **168 / 672 / 71 / 1**; `text/csv`; mount read-only; datasets
and secrets untouched; volume backed up outside the repo. Token:
E7A_READINESS_DATASOURCE_COMPLETED. Deliverables in `engineering/E7_grafana/`.
Next: **E7B — MCP connection** (service account + token + `mcp-grafana`) — **awaiting
explicit authorization**; no dashboards, service accounts, or MCP created yet.

**E6 — Power BI MVP (local, consume-only): PARTIAL.** Governed semantic model
`AEGIS_Forecast_Drift` authored via Power BI MCP over `V1/data/processed/current/`:
5 tables, shared `DriftDataFolder` parameter, **4 active relationships** (incl.
Calendar), 24 presentation-only measures (no DAX business logic), exported +
corrected to importable TMDL (`V1/PBI/tmdl/`; re-import validated: 5 tables / 24
measures / 4 rels). Official file `V1/PBI/AEGIS_Forecast_Drift.pbix`. **Real Full
refresh executed in the running Desktop and validated in-model** (DAX):
signals 168 / family 672 / events 71 / runs 1 (Calendar 1096), 24 measures
compile with values identical to Python (status 14/34/38/82, deep, 18/18, True),
4 active relationships. 11 pages + AEGIS sidebar specified. Remaining: **save the
`.pbix`** and author the visual pages + sidebar. Token: E6_POWER_BI_MVP_PARTIAL
(stays PARTIAL until visuals are built). Next: build visuals (V1 Power BI only).

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
| E5B | Production Dataset Validation & Export Hardening | ✅ Complete (offline + live validated) |
| E6 | Power BI MVP (local, consume-only) | ◑ Partial (model + measures + specs + TMDL; .pbix visuals manual) |
| E7 | Grafana MVP (local, consume-only) | ◑ In progress (E7A ✅ readiness & datasource; E7B ⏳) |
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
