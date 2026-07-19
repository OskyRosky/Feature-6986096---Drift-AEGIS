# PROJECT STATUS — AEGIS Forecast Drift Framework

**Feature 6986096 — Integrate Cross-Functional Capacity Feedback Signals to Align and Improve Capacity Mitigation Actions**
Last updated: 2026-07-19

> Microsoft internal / confidential. Engineering stages (E-prefix) build the product; product/document versions (V1/V2/V3) are separate. See `engineering/ROADMAP.md`.

## Current stage
**E7D.1 — Overview MVP (analytical panels): COMPLETED — VISUALLY ACCEPTED (2026-07-19).**
> The first published build (**v3**) rendered **"No data" on every panel** inside Grafana (empty filters)
> even though external `/api/ds/query` tests passed. **Root cause (two defects):** (1) the 5 template
> variables were stored as **flat Infinity queries without the `queryType:"infinity"` wrapper**, so the
> plugin treated them as legacy → empty dropdowns → `${var:singlequote}` → `region IN ()` → backend error on
> every panel; (2) panels 23/24 **aliased a filtered column** (`Forecast Key`/`Run ID`), which the backend
> filter could not resolve (`No parameter 'forecast_key'/'calculation_run_id' found`). **Both fixed** (variable
> wrapper restored; filtered columns' `text`==selector with display headers moved to rename/`displayName`)
> and republished as **v5**. A **second defect** then surfaced: the `forecast_version` variable alone showed a
> red error triangle because Grafana's frontend infers its **ISO-date** option values as a `time` field,
> emptying that variable → `forecast_version IN ()` → all signal panels "No data" again. **Fixed (v6)** by
> filtering on a non-date **`v`-prefixed label** (`fv_label = 'v' + forecast_version`) across the variable and
> 10 signal panels (the trend panel keeps `forecast_version:timestamp` for its X-axis and drops the version
> clause). Broken JSON archived at
> `V2/grafana/dashboards/archive/aegis-forecast-drift-foundation-e7d1-broken.json`. Post-repair **end-to-end
> per-panel replay of the published targets (All-expanded interpolation): 13/13 filter panels PASS, 0 FAIL.**
> Oscar **visually confirmed** the data and numbers, then requested a final **visual polish (v7)** — donut
> severity colors (Healthy green / Watch yellow / Warning orange / Critical red), a 2024-anchored time axis
> (`2024-03-01 → 2026-06-01`, removing the empty 2022 gap), a slimmer nav/header (`h:3→h:2`, no content or
> links removed, panels reflowed), and a corrected filter-semantics note (KPIs/distribution/families/ranking
> honor all five filters; the **trend intentionally ignores Forecast Version** to preserve full history).
> Polish re-validated **13/13 PASS**, data still visible; **Oscar formally accepted**. Do **not** start E7D.2
> until authorized.

Transformed the **Overview** (uid `aegis-forecast-drift-foundation` **retained**) from the E7C/E7D.0
foundation-preview into a complete **governed analytical dashboard** — **7 components / 15 panels** — adapting
the Power BI V1 Overview logic to Grafana + the read-only governed V2 CSV snapshot (**the dashboard does not
cook data**). Components: **A** KPI row (Total Signals **168** · Total Events **71** · Avg Drift **28.8** ·
Critical **14** · Warning **34** · Watch **38** · Healthy **82**); **B** Drift Status donut (82/38/34/14,
severity palette); **C** Avg Drift Score over time (14 `forecast_version` points, dashed thresholds 20/40/70,
UTC); **D** Signals by dominant family (Stability 88 · Volatility 45 · Shape 27 · Performance 8, **neutral**
color); **E** Forecast Keys by drift risk (12 keys, avg desc — **NAM-SDF 42.74** top — with band-colored
Max Drift Status); **F** Latest Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71); **G** Data
Quality **18 / 18**. All **5 shared filters** bound via a single `filterExpression` (backend parser); the
Infinity date-arithmetic bug **and** the frontend ISO-date variable time-inference were **fixed** by
filtering `forecast_version` through a non-date **`v`-prefixed label** (`fv_label`) and quoting `run_id`
(no Overview question left unanswerable by a CSV limitation). **Analytical reconciliation 21/21, 0
mismatches** via read-only `/api/ds/query`; severity KPIs and family counts each sum to 168. Published via
`V2/scripts/push-e7d1-overview.ps1` (service-account token **DPAPI-decrypted in memory only**, never
printed): Overview → **v7** (repaired ×2, polished ×1), `status=success`, `inFolder=True`, 15 panels. Foreign `advs2xz`
**untouched**; datasource `aegis-forecast-drift-csv`, nginx, Docker, CSVs, Python, Power BI V1, weights,
thresholds **unchanged**; no alerts/plugins; no dashboard deleted; **the other 10 dashboards were not
touched**; **no manual commit**; MCP/token/DPAPI unchanged; repo secret-free. Token:
**E7D1_OVERVIEW_MVP_COMPLETED_VISUALLY_ACCEPTED**. Deliverables: `engineering/E7_grafana/E7D1_*`
(5 docs) + updated `V2/grafana/dashboards/aegis-forecast-drift-foundation.json` + broken-build archive +
`V2/scripts/push-e7d1-overview.ps1`. **Open risk R1** unchanged.
URL `http://localhost:3000/d/aegis-forecast-drift-foundation`.
Next: **E7D.2** — **awaiting visual review + explicit authorization**.

**E7D.0 — Dashboard Information Architecture & Shared Navigation: COMPLETE (2026-07-19).**
Materialized the **product backbone** in Grafana: **11 dashboards** in folder **`AEGIS Forecast Drift`**
(uid `afsjccp27s0e8d`), all sharing one navigation contract, one shared-filter contract and one visual
design system. **Overview** = the E7C dashboard retitled to **`AEGIS Forecast Drift — Overview`**
(uid `aegis-forecast-drift-foundation` **retained** — the proposed `aegis-forecast-drift-overview` was
**not** adopted because a safe UID change requires deleting the existing dashboard, which is prohibited),
keeping its E7C functional panels, now with the shared nav bar, the corrected **`Forecast Key`** label and
the new **`forecast_version`** variable (14 values). **10 structural shells** created (Forecast, Performance,
Shape, Stability, Volatility, Events, Historical Timeline, **Top Forecast Keys** [replaces mockup *Top
Services* — `service` empty], **Top Scenarios** [single `Enterprise`], Settings & Data Quality) — each with
shared navigation + applicable shared filters + a purpose/roadmap text panel; **no analytical panels**.
Shared filters (data-driven, no empties): region 9 / forecast_key 12 / forecast_version 14 / drift_status 4 /
run_id 1. Published via `V2/scripts/push-e7d0-structure.ps1` (service-account token DPAPI-decrypted **in
memory only**, never printed): Overview → **v2**, 10 shells → **v1**, all `status=success`, all `inFolder=True`.
Foreign dashboard `advs2xz` **untouched**; datasource `aegis-forecast-drift-csv` **unchanged**; MCP
`✓ Connected`; token-literal repo scan **CLEAN**. **No E7D.1**, no alerts, no threshold/weight/data change;
token not revoked; DPAPI not deleted; MCP not unregistered; no dashboard deleted; **no manual commit**.
Token: **E7D0_INFORMATION_ARCHITECTURE_COMPLETED**. Deliverables: `engineering/E7_grafana/E7D0_*` (8 docs)
+ 11 governed JSON exports in `V2/grafana/dashboards/`. **Open risk R1** unchanged.
Next: **E7D.1 — Overview MVP** — **awaiting visual review + explicit authorization**.

**E7C — Grafana Dashboard Foundation Preview: COMPLETE (2026-07-18).** Built the visual/technical
foundation of the AEGIS Forecast Drift dashboard **via MCP** (consume-only). Created folder
**`AEGIS Forecast Drift`** (uid `afsjccp27s0e8d`) and dashboard **`AEGIS Forecast Drift`**
(uid `aegis-forecast-drift-foundation`, version 1) inside it: a **header** + **4 Infinity query
variables** (`forecast_key` 12 / `region` 9 / `drift_status` 4 / `run_id` 1 — all data-derived,
All option, multi) + **4 preview panels** — A Latest Governed Run (runs.csv), B Total Drift
Signals (**168**), C Drift Status Distribution (Healthy 82 / Watch 38 / Warning 34 / Critical 14),
D Top 10 by `forecast_drift_score`. Datasource `aegis-forecast-drift-csv` health **OK**;
read-only `/api/ds/query` per-panel rows **1/168/168/168** (no No-data). Pre-existing dashboard
`advs2xz` **inspected and untouched**. Governed export
`V2/grafana/dashboards/aegis-forecast-drift-foundation.json` (secret-free, datasource by UID).
Severity palette reserved (Healthy=green/Watch=yellow/Warning=orange/Critical=red). **Foundation
preview only** — no E7D, no full panel set, no alerts, no threshold/weight/data change; token
**not revoked**, DPAPI **not deleted**, MCP **not unregistered**, V1 untouched, **no manual commit**.
Precheck PASS: Grafana running, aegis-csv healthy, MCP `✓ Connected`, DPAPI present+decryptable,
`HEAD==origin/main==4b7c6cc` (auto-commit still only holds E7B.2; E7B.3/4/5 + E7C uncommitted).
Token: **E7C_DASHBOARD_FOUNDATION_PREVIEW_COMPLETED**. Deliverables:
`engineering/E7_grafana/E7C_*` (4 docs) + governed dashboard JSON. **Open risk R1** unchanged.
URL: `http://localhost:3000/d/aegis-forecast-drift-foundation/aegis-forecast-drift`.
Next: **E7D — Grafana Dashboard MVP** — **awaiting visual review + explicit authorization**.

**E7B.5 — MCP Connection Closure (Operational Readiness): COMPLETE (2026-07-18).**
Executed as a **NON-DESTRUCTIVE** closure (scope corrected): the token and MCP connection
**remain active** because E7C/E7D still need them. E7B.5 did **not** revoke the token, delete
the DPAPI secret, run `remove-grafana-mcp-token.ps1`, run `claude mcp remove grafana`, or
unregister the MCP. Readiness re-verified: MCP `grafana` **`✓ Connected`** (local, stdio,
`Environment: empty`); datasource **`aegis-forecast-drift-csv`** visible via `list_datasources`
(2 clean JSON lines); **no secrets** in repo (REPO_SCAN=CLEAN), Claude config (no token
prefix), or git tree (0 tracked secret files); DPAPI secret present outside repo; token **expires
2026-09-01**; **definitive revocation deferred to E7D close**. Grafana container running;
**no dashboards created; E7C not started.** Git integrity: `HEAD==origin/main==4b7c6cc`;
last auto-commit `4b7c6cc "add"` (E7B.2 deliverables). Token:
**E7B5_MCP_OPERATIONAL_READINESS_COMPLETED**. Deliverable:
`engineering/E7_grafana/E7B5_operational_readiness.md`. **Open risk R1:** external
auto-commit/push to `origin/main` — watch, do not modify. **No blockers for E7C.**
Next: **E7C — Dashboard Foundation** — **awaiting explicit authorization**.

**E7B.4 — Register MCP in Claude Code + Connectivity Smoke Test: COMPLETE (2026-07-18).**
Registered the official `mcp-grafana` v0.17.2 server in **Claude Code** as stdio server
**`grafana`**, **local scope** (`~/.claude.json`, outside repo, not committed), command =
the secure wrapper `V2/scripts/start-mcp-grafana.ps1` (**`Environment: empty`** — no token
in config; the wrapper decrypts the DPAPI token in memory). Hardened the wrapper so
**stdout carries only MCP JSON-RPC** and all diagnostics go to stderr. **Standalone MCP
smoke test** (`initialize` + `list_datasources`) returned clean JSON including
`aegis-forecast-drift-csv`; `claude mcp list`/`get grafana` report **`✓ Connected`**.
**No dashboards/folders created; no writes; E7C not started.** Token stays DPAPI-encrypted
outside repo; **expires 2026-09-01; revoke at E7D close**. Integrity unchanged: Grafana &
aegis-csv healthy; V2 168/672/71/1; V1 intact. Pre-registration post-auto-commit check:
`HEAD==origin/main==4b7c6cc`, no secret tracked/physical in repo. Token:
**E7B4_MCP_REGISTRATION_SMOKE_COMPLETED**. Deliverables: `engineering/E7_grafana/E7B4_*`
(5 docs) + hardened `V2/scripts/start-mcp-grafana.ps1`. **Open risk R1:** external
auto-commit/push to `origin/main` (last `4b7c6cc`, no secrets) — watch, do not modify.
**No blockers for E7B.5.** Next: **E7B.5 — MCP connection closure (revoke token, security
validation)** — **awaiting explicit authorization**.

**E7B.3 — Grafana Service Account & Secure Token: COMPLETE (2026-07-18).** Created the
dedicated Grafana service account **`aegis-mcp`** (login `sa-1-aegis-mcp`, org role
**Editor**, **not** admin) and a short-lived token with explicit expiration. **Verified**
that `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` **is** supported in v0.17.2 (binary strings +
README @ tag) but **rejected** it (plaintext at rest); instead the token is stored
**encrypted with Windows DPAPI (CurrentUser)** at `%LOCALAPPDATA%\AEGIS\secrets\grafana\`
(**outside the repo**) and decrypted **only in process memory** by the launch wrapper,
which sets `GRAFANA_SERVICE_ACCOUNT_TOKEN` process-scoped and restricts MCP tools to
`search,datasource,dashboard,folder`. Created four ASCII, **secret-free** scripts in
`V2/scripts/` (`store-`, `start-`, `verify-`, `remove-grafana-mcp-token.ps1`). User
created the account+token and stored it (`TOKEN_STORED=True`). **Authenticated read-only**
validation PASSED: identity `sa-1-aegis-mcp`, Editor permissions (no `users:read`/
`server.admin`), datasource `aegis-forecast-drift-csv` visible — **no writes, no MCP
registration, no dashboards created, token never printed**. Integrity unchanged: Grafana
& aegis-csv healthy; V2 168/672/71/1; V1 intact. Token: **E7B3_SERVICE_ACCOUNT_TOKEN_COMPLETED**.
Deliverables: `engineering/E7_grafana/E7B3_*` (5 docs) + `V2/scripts/*grafana-mcp-token.ps1`.
**Token not revoked** — kept until E7C/E7D complete or expiration. **Open risk R1:** external
auto-commit/push to `origin/main` (fired overnight as `4b7c6cc`, no secrets) — watch, do
not modify. **No blockers for E7B.4.** Next: **E7B.4 — Register MCP in Claude Code +
connectivity smoke test** — **awaiting explicit authorization**.

**E7B.2 — Install Pinned Grafana MCP Server: COMPLETE (2026-07-17).** Installed the
**official** `mcp-grafana` **v0.17.2** binary (windows/amd64) **outside the repo** at
`%LOCALAPPDATA%\AEGIS\mcp-grafana\v0.17.2\`, verified integrity (SHA256 `939eb0f4…eb62616`
matched **both** the release page **and** the official `checksums.txt`), and validated it
runs locally (`--version`=0.17.2; `--help` shows stdio + `--disable-write`/tool flags).
Created reproducible **secret-free** scripts in `V2/scripts/` (`install-mcp-grafana.ps1`
idempotent, `verify-mcp-grafana.ps1` read-only, `mcp-grafana-install-manifest.json`).
**No connection to Grafana; no service account; no token; no Claude Code registration;
no `.mcp.json`.** Binary kept out of the repo so R1 cannot publish it; PATH not modified.
Integrity unchanged: Grafana & aegis-csv healthy; V2 168/672/71/1; V1 intact. Token:
**E7B2_MCP_INSTALLATION_COMPLETED**. Deliverables: `engineering/E7_grafana/E7B2_*` (5 docs)
+ `V2/scripts/*`. **Open risk R1:** external auto-commit/push to `origin/main` — watch,
do not modify (fired as `b60f2b9` on the prior E7B.1 corrections). **No blockers for E7B.3.**
Next: **E7B.3 — Service account `aegis-mcp` + token** — **awaiting explicit authorization**.

**E7B.1 — Grafana MCP Connection Preflight: COMPLETE (2026-07-17).** Documentation-only
stage (no runtime mutation): produced six deliverables + status updates, but **nothing
installed, no service account/token, no MCP config**. Determined
the safe, reproducible way to connect Claude Code to Grafana via the official
`mcp-grafana` server (**v0.17.2**, requires Grafana ≥9.0; we have 13.0.1). **Selected
Architecture A:** native binary on the Windows host, **stdio**,
`GRAFANA_URL=http://localhost:3000`, Claude Code **local scope**, token via
`GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` (git-ignored) — zero impact on `aegis-net`/existing
containers, trivial rollback. Designed least-privilege service account `aegis-mcp`,
secret handling, tool allow-list (`datasource`+`search`/`dashboard` only, `--disable-write`
for reads, write scoped to a single temp smoke dashboard), and the E7B.2–E7B.5 plan.
**Known limitation:** no native Infinity/CSV query tool (CSV read only via Infinity
panel + `run_panel_query`, disabled by default). Integrity unchanged: Grafana & aegis-csv
healthy; V2 168/672/71/1; V1==V2; V1 intact. Token: **E7B1_MCP_PREFLIGHT_COMPLETED**.
Deliverables: `engineering/E7_grafana/E7B1_*` (6 docs). **Open risk R1:** external
auto-commit/push to `origin/main` — watch, do not modify. **No blockers for E7B.2.**
Next: **E7B.2 — Install pinned MCP server** — **awaiting explicit authorization**.

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
| E7 | Grafana MVP (local, consume-only) | ◑ In progress (E7A ✅; E7A.1/E7A.2/E7B.0/E7B.1/E7B.2/E7B.3/E7B.4/E7B.5 ✅; E7C ✅ foundation dashboard `aegis-forecast-drift-foundation` (folder `afsjccp27s0e8d`, data OK); **E7D.0 ✅** product backbone = 11 dashboards (Overview + 10 shells, shared nav/filters/visual system); E7D.1–E7D.12 ⏳) |
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
