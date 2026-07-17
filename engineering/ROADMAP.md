# AEGIS Forecast Drift — Engineering Roadmap (E0-E8)

**Feature 6986096.** Adopted 2026-07-12 (Oscar). This engineering roadmap is used to **build** the product. The Blueprint remains the conceptual source of truth.

> **Naming discipline:** `E`-stages = engineering phases (below). `V1/V2/V3` = product/document versions used by the README and Blueprint. Keep them separate to avoid the pre-existing "V1" collision (Blueprint V1, README V1=Power BI, folders V1/V2/V3).

| Stage | Name | Nature | Status |
| --- | --- | --- | --- |
| **E0** | Foundation — Blueprint, Mockup, Git, Governance | Docs/setup | ✅ Complete |
| **E1** | Source Discovery & Data Profiling | Discover (no calc) | ◑ In progress |
| ├ E1A | Document Discovery & Reuse (no live SQL) | Docs from existing knowledge | ✅ Complete |
| └ E1B | Live Data Validation (read-only SQL) | Confirm hypotheses | ✅ Complete (all 4 families computable) |
| **E2** | Forecast Drift Information Model (tables, grain, relations, lineage) | Design | ✅ Complete |
| **E3** | Mathematical Drift Model (formulas + known-answer fixtures) | Math | ✅ Complete |
| **E4** | Output Schema Design — `aegis_forecast_drift_signals` (design only) | Design | ✅ Complete |
| **E5** | SQL Implementation & Validation (views/CTEs/procs + validate vs fixtures) | Build | ✅ Complete |
| ├ E5A | Python Drift Engine (read-only ingest + calc + governed datasets) | Build | ✅ Complete |
| └ E5B | **Production Dataset Validation & Export Hardening** (canonicalization, atomic export, refresh runner, contract) | Build | ✅ Complete — offline hardening + expanded live read-only run validated (2026-07-13) |
| **E6** | Power BI MVP (consume only) | Viz | ◑ In progress — model `AEGIS_Forecast_Drift` refreshed + validated in Desktop (in-model 168/672/71/1, 24 measures=Python, 4 rels); TMDL at `V1/PBI/tmdl/`; save `.pbix` + author visuals pending (PARTIAL) |
| **E7** | Grafana Production Dashboard (same SQL, new viz) | Production | ◑ In progress |
| ├ E7A | Grafana Readiness & Data Source (Infinity + read-only CSV server) | Build | ✅ Complete (2026-07-16) — existing Grafana 13.0.1 preserved; Infinity 3.10.1 + datasource `AEGIS Forecast Drift CSV`; counts 168/672/71/1 served internally |
| ├ E7A.1 | Infinity Functional Query Validation Gate (in-Grafana query per dataset) | Validate | ✅ Complete (2026-07-17) — manual authenticated Grafana queries; Query Inspector 168/672/71/1; health check OK; CSV/null parsing PASS; type hints → E7C/E7D. Token `E7A_INFINITY_QUERY_GATE_COMPLETED` |
| ├ E7A.2 | V2 Governed Data Snapshot & Datasource Rewire (self-contained V2) | Build | ✅ Complete (2026-07-17) — byte-equivalent SHA256-verified snapshot under `V2/data/processed/` + `sync-governed-data.ps1`; `aegis-csv` rewired to V2 (read-only); V1 untouched; Grafana/UID/port unchanged |
| ├ E7B.0 | Formal Closure of E7A.1 (docs + evidence, no MCP) | Docs | ✅ Complete (2026-07-17) — evidence registered; V14 DEFERRED→PASS; closure docs. Token `E7B0_E7A1_FORMAL_CLOSURE_COMPLETED` |
| └ E7B.1 | MCP Connection Preflight (assess prerequisites only) | Build | ⏳ (awaiting authorization) |
| **E8** | Production Deployment & Governance (refresh, automation, docs) | Ops | ⏳ |

**Principles:** model-first not tool-first; Information Model before math; Data Dictionary is a deliverable **of** E1 (not a separate stage); reuse Code Improvement (reference, don't copy logic); no live SQL until E1B; this project stays an **independent workspace/repo** from Code Improvement.

**Reuse rule:** Code Improvement = forecasting pipeline engineering. Forecast Drift = drift detection, scoring, alerts, visualization. When Drift needs something from the other project, it **references/reuses**, it does not copy the logic.
