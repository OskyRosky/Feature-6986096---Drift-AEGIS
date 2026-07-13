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
| **E5** | SQL Implementation & Validation (views/CTEs/procs + validate vs fixtures) | Build | ◑ In progress |
| ├ E5A | Python Drift Engine (read-only ingest + calc + governed datasets) | Build | ✅ Complete |
| └ E5B | SQL Implementation & Validation (DDL + load + views + calibrate) | Build | ⏳ Next (needs auth) |
| **E6** | Power BI MVP (consume only) | Viz | ⏳ |
| **E7** | Grafana Production Dashboard (same SQL, new viz) | Production | ⏳ |
| **E8** | Production Deployment & Governance (refresh, automation, docs) | Ops | ⏳ |

**Principles:** model-first not tool-first; Information Model before math; Data Dictionary is a deliverable **of** E1 (not a separate stage); reuse Code Improvement (reference, don't copy logic); no live SQL until E1B; this project stays an **independent workspace/repo** from Code Improvement.

**Reuse rule:** Code Improvement = forecasting pipeline engineering. Forecast Drift = drift detection, scoring, alerts, visualization. When Drift needs something from the other project, it **references/reuses**, it does not copy the logic.
