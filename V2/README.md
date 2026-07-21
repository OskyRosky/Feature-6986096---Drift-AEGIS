# AEGIS Forecast Drift — V2 (Grafana Product)

**Feature 6986096 — Integrate Cross-Functional Capacity Feedback Signals.**
Microsoft internal / confidential.

V2 is the **self-contained Grafana consumption product** for the AEGIS Forecast
Drift Framework. It visualizes the four governed drift datasets produced by the
**V1 authoritative Python Drift Engine**. No business or drift logic lives in V2 —
*"el dashboard no cocina datos."*

## Governance

- **V1 = authoritative producer** (read-only from V2's perspective, never mutated).
- **V2 = synchronized consumption snapshot.** `V2/data/processed/` holds a
  **byte-equivalent (SHA256-verified)** copy of the V1 governed outputs.
- All drift math, thresholds, weights, and classifications stay in the V1 engine.

## Layout

```
V2/
├─ data/processed/
│  ├─ current/        # 4 governed CSVs (signals 168, family 672, events 71, runs 1)
│  ├─ metadata/       # run_metadata.json (calculation_version, etc.)
│  ├─ validation/     # data-quality + fixture results
│  └─ data_manifest.json   # per-file origin, dest, SHA256, rows, snapshot timestamp
├─ scripts/
│  └─ sync-governed-data.ps1   # governed V1 -> V2 snapshot sync (idempotent, no secrets)
├─ grafana/provisioning/datasources/aegis-infinity.yaml
├─ nginx/default.conf
├─ docker-compose.yml          # aegis-csv (read-only CSV server on aegis-net)
└─ .env.example                # AEGIS_CSV_DIR override (defaults to ./data/processed/current)
```

## Refreshing the snapshot

After a new V1 Drift Engine run, refresh the V2 snapshot:

```powershell
pwsh V2/scripts/sync-governed-data.ps1
```

The script copies only the governed allow-list, validates row counts
(168/672/71/1) and SHA256 (fails hard on mismatch), and regenerates
`data_manifest.json`. It never writes to V1.

Since **E7D.12** the same run also **regenerates the 18-check data-quality catalog**
transactionally (validates the authoritative source is 18 rows / 0 FAIL, rebuilds
`validation/` + `current/` copies, verifies they are byte-identical by SHA256, rolls
back on any mismatch) and records `catalog_refresh_integrated=true` in the manifest.
Use `-DryRun` to preview without writing anything.

## Serving to Grafana

`docker compose up -d aegis-csv` starts the nginx CSV server, which bind-mounts
`V2/data/processed/current/` **read-only** and serves it at `http://aegis-csv`
inside the `aegis-net` Docker network (no host port). The pre-existing Grafana
(13.0.1) reads it through the **Infinity** datasource
`AEGIS Forecast Drift CSV` (uid `aegis-forecast-drift-csv`).

## Stage history

- **E7A** — Grafana readiness + Infinity datasource (served from V1).
- **E7A.1** — Infinity Functional Query Validation Gate: manual authenticated
  Grafana queries returned 168/672/71/1 (Query Inspector); health check OK; CSV
  parsing + null tolerance PASS; per-panel type hints deferred to E7C/E7D.
  Token `E7A_INFINITY_QUERY_GATE_COMPLETED`. See
  `engineering/E7_grafana/E7A1_infinity_manual_query_evidence.md`.
- **E7A.2** — V2 governed data snapshot + datasource rewire (self-contained V2).
  See `engineering/E7_grafana/E7A2_*`.
- **E7B.0** — Formal closure of E7A.1 (docs + evidence, no MCP). Token
  `E7B0_E7A1_FORMAL_CLOSURE_COMPLETED`. See
  `engineering/E7_grafana/E7B0_closure_summary.md`.
- **E7B.1** — Grafana MCP Connection Preflight (documentation-only; no runtime mutation).
  Selected **Architecture A** for `mcp-grafana` **v0.17.2**: native binary on the
  host, **stdio**, `GRAFANA_URL=http://localhost:3000`, Claude Code **local scope**,
  token via `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` (git-ignored). Least-privilege
  service account `aegis-mcp` + tool allow-list designed; E7B.2–E7B.5 planned.
  Known limitation: no native Infinity/CSV query tool. Token
  `E7B1_MCP_PREFLIGHT_COMPLETED`. See `engineering/E7_grafana/E7B1_*`.
- **E7B.2** — Install pinned Grafana MCP server. Official `mcp-grafana` **v0.17.2**
  (windows/amd64) installed **outside the repo** at
  `%LOCALAPPDATA%\AEGIS\mcp-grafana\v0.17.2\`; SHA256 verified vs release page +
  official `checksums.txt`; `--version`/`--help` OK. Secret-free scripts in
  `V2/scripts/` (`install-mcp-grafana.ps1`, `verify-mcp-grafana.ps1`,
  `mcp-grafana-install-manifest.json`). Not connected to Grafana; no token; no MCP
  registration. Token `E7B2_MCP_INSTALLATION_COMPLETED`. See `engineering/E7_grafana/E7B2_*`.
- **E7B.3** — Service account `aegis-mcp` (Editor, not admin) + short-lived DPAPI-encrypted
  token stored outside the repo; authenticated read-only validation PASS (no writes, no MCP
  registration). Token `E7B3_SERVICE_ACCOUNT_TOKEN_COMPLETED`. See `engineering/E7_grafana/E7B3_*`.
- **E7B.4** — Registered `mcp-grafana` v0.17.2 in Claude Code as stdio server `grafana`
  (local scope, outside repo; secure wrapper, no token in config). Smoke test
  (`initialize`+`list_datasources`) returned `aegis-forecast-drift-csv`; `claude mcp list` =
  **✓ Connected**. No dashboards/writes. Token expires 2026-09-01, revoke at E7D close.
  Token `E7B4_MCP_REGISTRATION_SMOKE_COMPLETED`. See `engineering/E7_grafana/E7B4_*`.
- **E7B.5** — MCP connection closure as a **non-destructive** operational-readiness check
  (token & MCP kept active for E7C/E7D; nothing revoked/removed). Re-verified `✓ Connected`,
  datasource `aegis-forecast-drift-csv` visible, no secrets in repo/config/git, token expiry
  2026-09-01 with definitive revocation at E7D close. No dashboards; E7C not started.
  Token `E7B5_MCP_OPERATIONAL_READINESS_COMPLETED`. See `engineering/E7_grafana/E7B5_operational_readiness.md`.
- **E7C** — Grafana dashboard **foundation preview** built via MCP: folder `AEGIS Forecast Drift`
  (uid `afsjccp27s0e8d`) + dashboard `AEGIS Forecast Drift` (uid `aegis-forecast-drift-foundation`)
  with header, 4 Infinity query variables (forecast_key/region/drift_status/run_id, all with All)
  and 4 preview panels (Latest Run, Total Signals=168, Status Distribution, Top 10 by drift score).
  Datasource health OK; read-only `/api/ds/query` per-panel rows 1/168/168/168 (no No-data);
  pre-existing dashboard untouched; governed export `V2/grafana/dashboards/aegis-forecast-drift-foundation.json`
  (secret-free, UID ref). Foundation preview only — no E7D, no alerts, no threshold/data change.
  URL `http://localhost:3000/d/aegis-forecast-drift-foundation/aegis-forecast-drift`.
  Token `E7C_DASHBOARD_FOUNDATION_PREVIEW_COMPLETED`. See `engineering/E7_grafana/E7C_*`.
- **E7D.0** — Dashboard **Information Architecture & Shared Navigation** (structure only). Product
  backbone = **11 dashboards** in folder `AEGIS Forecast Drift` (uid `afsjccp27s0e8d`) sharing one
  navigation contract, one shared-filter contract and one visual design system. **Overview** = the E7C
  dashboard retitled `AEGIS Forecast Drift — Overview` (uid `aegis-forecast-drift-foundation` retained;
  proposed `-overview` not adopted to avoid deleting the existing dashboard) with the shared nav bar,
  corrected `Forecast Key` label and new `forecast_version` variable. **10 shells** created (Forecast,
  Performance, Shape, Stability, Volatility, Events, Historical Timeline, **Top Forecast Keys** [replaces
  mockup *Top Services* — governed `service` column empty], **Top Scenarios** [single `Enterprise`],
  Settings & Data Quality) — each with shared navigation + applicable shared filters + a purpose panel,
  **no analytical panels**. Shared filters are data-driven (region 9 / forecast_key 12 / forecast_version
  14 / drift_status 4 / run_id 1). Published via `V2/scripts/push-e7d0-structure.ps1` (token DPAPI
  in-memory): Overview v2, shells v1, all in folder; foreign `advs2xz` untouched; datasource unchanged;
  MCP `✓ Connected`; repo secret-literal scan CLEAN. Governed JSON exports in `V2/grafana/dashboards/`.
  No E7D.1, no alerts, no threshold/weight/data change. Token `E7D0_INFORMATION_ARCHITECTURE_COMPLETED`.
  See `engineering/E7_grafana/E7D0_*` (8 docs).
- **E7D.1** — **Overview MVP** (analytical panels) — **COMPLETED, VISUALLY ACCEPTED**. Transformed the
  Overview (uid `aegis-forecast-drift-foundation`, retained) from foundation-preview into a full governed
  analytical dashboard: **7 components / 15 panels** — KPIs (Total Signals 168 · Total Events 71 · Avg Drift
  28.8 · Critical 14 · Warning 34 · Watch 38 · Healthy 82), Drift Status donut (82/38/34/14), Avg Drift over
  time (14 forecast-version points, thresholds 20/40/70, UTC), Signals by dominant family (Stability 88 ·
  Volatility 45 · Shape 27 · Performance 8, neutral color), Forecast Keys by drift risk (12 keys, avg desc —
  NAM-SDF 42.74 — with band-colored Max Drift Status), Latest Governed Run (1 · Success · 2026-07-13 22:44
  UTC · 168 · 71), Data Quality 18/18. All 5 shared filters bound via one `filterExpression` (backend
  parser); the Infinity date-arithmetic bug **and** the frontend ISO-date variable time-inference were fixed
  by filtering `forecast_version` through a non-date **`v`-prefixed label** (`fv_label`) + quoted `run_id`.
  **The first build (v3) rendered "No data" on every panel** — root cause: template variables lacked the
  `queryType:"infinity"` wrapper (empty dropdowns) + panels 23/24 aliased a filtered column. Fixed and
  republished **v5**. A **second defect** (the `forecast_version` variable red-triangled because its ISO-date
  values were inferred as `time`) was fixed in **v6** via the `v`-prefixed label across the variable + 10
  signal panels (trend panel keeps `forecast_version:timestamp` for its X-axis, drops the version clause);
  broken build archived under `V2/grafana/dashboards/archive/`. Post-repair
  end-to-end per-panel replay: **13/13 filter panels PASS, 0 FAIL**; analytical reconciliation 21/21.
  After Oscar visually confirmed the data, a final **visual polish (v7)** applied donut severity colors
  (Healthy green / Watch yellow / Warning orange / Critical red), a 2024-anchored time axis
  (`2024-03-01 → 2026-06-01`, no empty 2022 gap), a slimmer nav/header (`h:3→h:2`, no content/links removed),
  and a corrected filter-semantics note (KPIs/distribution/families/ranking honor all five filters; the trend
  intentionally ignores Forecast Version to preserve full history) — re-validated **13/13 PASS**.
  Published via `V2/scripts/push-e7d1-overview.ps1` (token DPAPI in-memory) → **v7**, `success`, in folder;
  other 10 dashboards untouched; datasource/nginx/Docker/CSV/Python/PBI/weights/thresholds unchanged; no
  alerts/plugins/deletes; no manual commit. **Oscar formally accepted (visually).**
  Token `E7D1_OVERVIEW_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-foundation`. See `engineering/E7_grafana/E7D1_*` (5 docs).
- **E7D.2** — **Forecast MVP** (analytical panels) — **COMPLETED, VISUALLY ACCEPTED**. Rebuilt the
  Forecast dashboard (uid `aegis-forecast-drift-forecast`, retained) from the E7D.0 shell into a full governed
  analytical dashboard: **8 components / 10 panels** — Overall Forecast Drift Score gauge (mean 28.8, bands
  20/40/70), Drift Family Distribution donut (Stability 88 · Volatility 45 · Shape 27 · Performance 8, neutral
  colors), Drift Status Distribution donut (Healthy 82 · Watch 38 · Warning 34 · Critical 14, severity colors),
  Avg Drift Score over time (14 forecast-version points, thresholds 20/40/70, UTC — ignores Forecast Version
  filter), Forecast Keys by avg drift score (12 keys, desc — NAM-SDF 42.74 top), **Drift Score Heatmap**
  (12 keys × 14 versions, one governed score per cell, severity background — single-query pivot via the native
  `groupingToMatrix` transform, since Grafana has no native categorical pivot), Latest
  Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71), Data Quality 18/18. Reused the stable E7D.1
  mechanism verbatim (`queryType`-wrapped variables, `v`-prefixed `fv_label`, quoted `run_id`, no aliasing of
  filtered columns, transform aggregation). Reconciliation **18/18** (8 panel + 4 consistency + 6 filter
  scenarios); pre-publish validator **0 failures**; heatmap gate **14/14** × 12 rows (single batch).
  **Oscar's first visual review (v2)** flagged two defects — the status donut colored by position
  (`palette-classic`) and the heatmap rendered empty (the 14-target Infinity pivot hit per-URL response
  coalescing). **Both fixed:** the donut now uses explicit `byName` severity overrides; the heatmap was
  rebuilt as a **single-query `groupingToMatrix` pivot** (one query, no coalescing, honors the shared
  filters). Published
  only the Forecast dashboard via `V2/scripts/push-e7d2-forecast.ps1` (token DPAPI in-memory) → **v3**,
  `success`, in folder, 10 panels; shell archived at
  `V2/grafana/dashboards/archive/aegis-forecast-drift-forecast-shell.json`. Overview + other 9 dashboards,
  datasource, nginx, Docker, CSVs, Python, Power BI, weights, thresholds, alerts, plugins, token, DPAPI, MCP
  untouched; repo secret-free; no manual commit.
  Token `E7D2_FORECAST_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-forecast`. See `engineering/E7_grafana/E7D2_forecast_*` (6 docs).
- **E7D.3** — **Performance MVP** (analytical panels) — **COMPLETED, VISUALLY ACCEPTED**. Rebuilt the
  Performance dashboard (uid `aegis-forecast-drift-performance`, retained) from the E7D.0 shell into a full
  governed analytical dashboard for the performance drift family (weight 20%): **9 components / 11 panels** —
  Average Performance Drift Score (**7.71**, bands 20/40/70), Performance Signals Computable (**156**), Average
  MAPE Change (**0.81 %**, `MAPE_deep`, percent unit), Performance Coverage (**92.9 %** = 156/168, green ≥ 0.9),
  Performance Drift Score over time (13 forecast-version points, thresholds 20/40/70, UTC — ignores Forecast
  Version; peaks 38.19 @ 2025-06-01 and 23.19 @ 2026-03-07), Performance Signal Details (per-signal, score desc,
  Computable Yes/No, severity status), Non-computable Performance Summary (**NO_REALIZED_OVERLAP 12** from family
  scores), Latest Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71), Data Quality 18/18. **No value
  hardcoded** — every KPI reduces the datasource live. **Computability predicate solved** (score empty for
  non-computable rows; Infinity numeric `>= 0` → HTTP 400 / truthy-empty and ternary computed columns
  unsupported): select score as string, filter `performance_drift_score != ''` (156), `convertFieldType` →
  number for the mean/trend, boolean computed flag for coverage. Reused the stable E7D.1/E7D.2 mechanism verbatim
  (`queryType`-wrapped variables, `v`-prefixed `fv_label`, quoted `run_id`, no aliasing of filtered columns,
  transform aggregation); Run + DQ cloned 1:1 from Forecast. Reconciliation **all matched, 0 mismatches** (4 KPI
  + 4 consistency + 13-bucket trend + details + 7 filter scenarios); pre-publish validator **0 failures**.
  Documented limitations: only `MAPE_deep` rows expose Current/Previous MAPE (details blank elsewhere by design);
  the Non-computable Summary honors only Forecast Key + Forecast Version (family scores lack region/status/run_id).
  Published only the Performance dashboard via `V2/scripts/push-e7d3-performance.ps1` (token DPAPI in-memory) →
  **v2**, `success`, in folder, 11 panels; shell archived at
  `V2/grafana/dashboards/archive/aegis-forecast-drift-performance-shell.json`. Overview + Forecast + other 8
  dashboards, datasource, nginx, Docker, CSVs, Python, Power BI, weights, thresholds, alerts, plugins, token,
  DPAPI, MCP untouched; repo secret-free; no manual commit. Agent browser unauthenticated → live render awaits
  Oscar. **Oscar's v2 review found one defect — Performance Coverage rendered empty — fixed in v3:** `is_comp`
  (`performance_drift_score != ''`) came back **boolean** so `mean` yielded no value; added
  `convertFieldType is_comp → number` → **92.9 %** (denominator dynamic, not hardcoded). Republished only
  Performance → **v3**, `success`, in folder, 11 panels. **Oscar visually accepted v3 on 2026-07-19** (Coverage
  92.9 %, all other components correct).
  Token `E7D3_PERFORMANCE_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-performance`. See `engineering/E7_grafana/E7D3_performance_*` (5 docs).
- **E7D.4** — **Shape MVP** (analytical panels) — **COMPLETED, VISUALLY ACCEPTED**. Rebuilt the Shape
  dashboard (uid `aegis-forecast-drift-shape`, retained) from the E7D.0 shell into a full governed analytical
  dashboard for the shape drift family (weight 40%): **8 components / 10 panels** — Average Shape Drift Score
  (**26.03**, bands 20/40/70), Shape Signals Computable (**168**), Shape Coverage (**100.0 %** = 168/168, green ≥
  0.9), Maximum Shape Drift Score (**100.00**), Shape Drift Score over time (14 forecast-version points, UTC —
  ignores Forecast Version; peak 62.60 @ 2025-12-01, secondary 44.08 @ 2026-03-07, low 9.59 @ 2026-04-16), Shape
  Signal Details (per-signal, score desc, full width), Latest Governed Run (1 · Success · 2026-07-13 22:44 UTC ·
  168 · 71), Data Quality 18/18. **No value hardcoded** — every KPI reduces the datasource live. **Data-driven
  scope:** Shape is 168/168 computable (0 non-computable) → Non-computable Summary panel **intentionally omitted**
  (Details widened to full width); the snapshot exposes a single `shape_drift_score` with no auxiliary/MAPE metric
  → 4th KPI is **Maximum Shape Drift Score** and the Details table carries no Current/Previous columns. Reused the
  stable E7D.1/E7D.2/E7D.3 mechanism verbatim (`queryType`-wrapped variables, `v`-prefixed `fv_label`, quoted
  `run_id`, no aliasing of filtered columns, transform aggregation; the E7D.3 boolean fix `convertFieldType
  is_comp → number` before `mean` applied to Coverage); Run + DQ cloned 1:1. Structural validator **0 failures**;
  reconciliation **all matched, 0 discrepancies** (4 KPI + 14-bucket trend + 6 filter scenarios: All→168/26.03/100 %,
  NAM-SDF→14/42.22, region NAM→42/36.50, Critical→14/89.45, v2025-12-01→12/62.60, missing key→0). Published only
  the Shape dashboard via `V2/scripts/push-e7d4-shape.ps1` (token DPAPI in-memory) → **v2**, `success`, in folder,
  10 panels; shell archived at `V2/grafana/dashboards/archive/aegis-forecast-drift-shape-shell.json`. Overview +
  Forecast + Performance + other 7 dashboards, datasource, nginx, Docker, CSVs, Python, Power BI, weights,
  thresholds, alerts, plugins, token, DPAPI, MCP untouched; repo secret-free; no manual commit. Agent browser
  unauthenticated → live render awaits Oscar's visual acceptance. Do **not** start E7D.5 (Stability).
  **Oscar visually accepted 2026-07-19**; minor post-acceptance polish (**v3**) on the trend panel only — time
  start moved to first real data 2024-04-01 (removes empty pre-2024 space) and `lineInterpolation` smooth →
  linear, real per-version points kept, no query/metric/filter/KPI/table/other-dashboard change, KPIs intact.
  Token `E7D4_SHAPE_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-shape`. See `engineering/E7_grafana/E7D4_shape_*` (5 docs).

- **E7D.5** — **Stability MVP** (analytical panels) — **COMPLETED, VISUALLY ACCEPTED**. Built the
  Stability dashboard (uid `aegis-forecast-drift-stability`, retained) from the E7D.0 shell into a full governed
  analytical dashboard for the stability drift family (weight 30%) by cloning the accepted Shape (E7D.4)
  structure and swapping the metric to `stability_drift_score`: **8 components / 10 panels** — Average Stability
  Drift Score (**38.93**, bands 20/40/70), Stability Signals Computable (**168**), Stability Coverage
  (**100.0 %** = 168/168, green ≥ 0.9), Maximum Stability Drift Score (**100.00**), Stability Drift Score over
  time (14 forecast-version points, UTC — ignores Forecast Version; peak 74.14 @ 2025-12-01, secondary 56.47 @
  2026-04-06 / 55.36 @ 2026-03-07, low 16.08 @ 2026-04-16), Stability Signal Details (per-signal, score desc,
  full width), Latest Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71), Data Quality 18/18. **No
  value hardcoded** — every KPI reduces the datasource live. **Data-driven scope:** Stability is 168/168
  computable (0 non-computable) → Non-computable Summary panel **intentionally omitted** (Details widened to full
  width); the snapshot exposes a single `stability_drift_score` with no auxiliary/MAPE metric → 4th KPI is
  **Maximum Stability Drift Score** and no Current/Previous columns; richer stability auxiliaries
  (`structural_break_flag`, `cumulative_revision_pct`, `version_count`) populated but intentionally not integrated
  in this single-source MVP (future enhancement). Reused the stable E7D.1–E7D.4 mechanism verbatim
  (`queryType`-wrapped variables, `v`-prefixed `fv_label`, quoted `run_id`, no aliasing of filtered columns,
  transform aggregation; boolean fix `convertFieldType is_comp → number` before `mean` on Coverage); accepted
  Shape v3 polish (time start 2024-04-01, trend `lineInterpolation` linear, points visible) applied from the
  start. Structural validator **0 real failures**; reconciliation **all matched, 0 discrepancies** (4 KPI +
  14-bucket trend + 6 filter scenarios: All→168/38.93/100 %, NAM-SDF→14/54.78, region NAM→42/50.71,
  Critical→14/95.35, v2025-12-01→12/74.14, missing key→0). Published only the Stability dashboard via
  `V2/scripts/push-e7d5-stability.ps1` (token DPAPI in-memory) → **v2**, `success`, in folder, 10 panels; shell
  archived at `V2/grafana/dashboards/archive/aegis-forecast-drift-stability-shell.json`. Overview + Forecast +
  Performance + Shape + other 6 dashboards, datasource, nginx, Docker, CSVs, Python, Power BI, weights,
  thresholds, alerts, plugins, token, DPAPI, MCP untouched; repo secret-free; no manual commit. Agent browser
  unauthenticated → live render awaited Oscar's visual acceptance. **Oscar visually accepted 2026-07-19.**
  Token `E7D5_STABILITY_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-stability`. See `engineering/E7_grafana/E7D5_stability_*` (5 docs).

- **E7D.6** — **Volatility MVP** (analytical panels) — **COMPLETED, VISUALLY ACCEPTED (Oscar, 2026-07-19)**. Built the
  Volatility dashboard (uid `aegis-forecast-drift-volatility`, retained) from the E7D.0 shell into a full governed
  analytical dashboard for the volatility drift family (weight 10%), **deliberately NOT a mechanical clone** of
  Stability/Shape because Volatility is only **partially computable (144/168, coverage 85.7 %)**: **13 panels** —
  Average Volatility Drift Score (**56.04**, bands 20/40/70), Volatility Signals Computable (**144**), Volatility
  Coverage (**85.7 %** = 144/168), Maximum Volatility Drift Score (**100.00**), Volatility Drift Score over time
  (**12** forecast-version points, UTC — ignores Forecast Version, axis starts **2024-06-01**; peak 78.13 @
  2026-01-01), Volatility Drift Score by Forecast Key (**horizontal barchart**, NAM-SDF 82.21 top), Volatility
  Signal Details (per-signal, score desc, full width, shows non-computable rows), Volatility Profile — Governed
  Auxiliary Metrics (from `forecast_drift_family_scores.csv`: `rolling_stddev/cov/mad`, `oscillation_count`,
  `sign_change_freq`, `volatility_class`; 144 rows), Non-computable Summary (**INSUFFICIENT_VERSIONS = 24**),
  Latest Governed Run (1 · Success · 2026-07-13 22:44 UTC · 168 · 71), Data Quality 18/18. **No value hardcoded** —
  every KPI reduces the datasource live. **Data-driven scope:** the 24 non-computable signals are the first two
  versions of each of the 12 keys (`2024-04-01`, `2024-05-01`), governed by `INSUFFICIENT_VERSIONS` →
  **Non-computable Summary panel IS built** (unlike Stability/Shape at 168/168); Coverage is a first-class dynamic
  KPI; averages/max exclude non-computable (never zeroed); governed **auxiliaries live in family_scores.csv (not
  signals.csv)** → dedicated Volatility Profile table honoring only `forecast_key` + `forecast_version`
  (documented two-table exception); ranking barchart is a new panel type; trend starts at first computable bucket
  2024-06-01. Reused the E7D.1–E7D.5 mechanism verbatim (`queryType`-wrapped variables, `v`-prefixed `fv_label`,
  quoted `run_id`, `convertFieldType` before numeric reducers; Infinity requires **`==`** for equality in
  family_scores filters). Structural validator **0 failures**; reconciliation **all matched, 0 discrepancies** (4
  KPI + 12-bucket trend + key ranking + aux 144 + non-computable 24 + 8 filter scenarios incl. non-computable
  version v2024-04-01 → 12/0/**0 % coverage**). Published only the Volatility dashboard via
  `V2/scripts/push-e7d6-volatility.ps1` (token DPAPI in-memory) → **v3** (post-acceptance polish), `success`, in folder, 13 panels; shell
  archived at `V2/grafana/dashboards/archive/aegis-forecast-drift-volatility-shell.json`. **Post-acceptance polish
  (v3):** trend saved range confirmed to start at first real bucket `2024-06-01` (`linear` + `showPoints=always`
  kept; query/12 buckets unchanged — the "2021" gap was a client-side time override, not the model); Volatility
  Profile `rolling_stddev` (raw 221.6→1,270,234, no governed unit) set to explicit **`locale`** unit
  (thousands-grouped integer) instead of ambiguous `short` K/Mil — no data recalculated. Overview + Forecast +
  Performance + Shape + Stability + other 5 dashboards, datasource, nginx, Docker, CSVs, Python, Power BI,
  weights, thresholds, alerts, plugins, token, DPAPI, MCP untouched; repo secret-free; no manual commit. Agent
  browser unauthenticated → live render **visually accepted by Oscar (2026-07-19)**. Do **not** start E7D.7 (Events).
  Token `E7D6_VOLATILITY_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-volatility`. See `engineering/E7_grafana/E7D6_volatility_*` (5 docs).

- **E7D.7** — **Events MVP** (governed event log) — **COMPLETED, VISUALLY ACCEPTED (Oscar, 2026-07-20)**. Transformed the
  Events dashboard (uid `aegis-forecast-drift-events`, retained) from the E7D.0 shell into a **read-only** operational
  view of the governed drift-**event** log. **Data finding:** `forecast_drift_event_history.csv` is a thin 7-column
  lifecycle table (all `new_status=Open`, single `changed_at`) — **not** the rich source; the **71 governed events are
  the `forecast_drift_signals.csv` subset where `is_event=1`**, which carries every rich field (forecast_key, region,
  dominant_drift_family, forecast_drift_score, drift_status, explanation, event_status). **13 panels:** Total Events
  (**71**), Critical (**14**), Warning (**34**), Affected Forecast Keys (**12**), Latest Event, Events by Drift Family
  donut (shape 26/stability 24/volatility 15/performance 6, non-severity palette), Events by Drift Status donut
  (Critical 14/Warning 34/Watch 13/Healthy 10, severity palette), Events by Forecast Key barchart (single detection
  instant → **no over-time trend**), Governed Event Log (71 rows, newest-first, native column-filter search, wrapped
  Explanation), Latest Governed Run (1·Success·168·71), Data Quality 18/18. **Read-only** — no resolve/ack/close/edit,
  no invented lifecycle states (only governed `event_status=Open` shown), no invented Severity (`drift_status` = the
  governed band; `severity` alias not surfaced), no invented Service/Scenario/Event Type (empty/single/absent).
  **6 filters:** forecast_key, forecast_version (via `fv_label`), region, drift_status, run_id, **drift_family** (local)
  — *documented deviation vs E7D.0 matrix* (Events adds forecast_version + drift_family because events are the signals
  subset). **Nothing hardcoded** (71 = `is_event=1`; the mockup's "170" is illustrative; the CSV is the sole truth).
  Infinity rule reaffirmed: every `filterExpression` column must be selected/computed (`fv_label = 'v'+forecast_version`
  needs `forecast_version` selected). Reconciliation **0 discrepancies** (KPIs + distributions + affected keys +
  explanation 71/71 + event_status Open + max 84.72 + run footer + **9 filter scenarios**: All 71 / NAM 29 / Critical 14
  / Run1 71 / shape 26 / NAM-MSIT 9 / v2026-05-01 5 / back-to-All 71 / NAM+Critical 9). Published **only** the Events
  dashboard via `V2/scripts/push-e7d7-events.ps1` (token DPAPI in-memory) → **v4**, `success`, in folder, 13 panels,
  `keepTime=false`/`includeVars=true`, saved range 2026-07-01→07-31 (UTC, picker hidden); shell archived at
  `V2/grafana/dashboards/archive/aegis-forecast-drift-events-shell.json`. **Visual repair (v5):** the
  Events-by-Drift-Status donut now uses explicit `byName` fixed-color overrides (Healthy green / Watch yellow /
  Warning orange / Critical red) instead of palette-classic, and the Latest Event panel height was reduced
  h:4→h:3 (KPIs re-verified unchanged: 71 / 14 / 34 / 12, DQ 18/18). **Allowed exception:** shared `links` block
  keeps keepTime=false/includeVars=true. Historical Timeline, Top Forecast Keys, Top Scenarios, Settings & Data Quality
  **not started**. Overview + Forecast + Performance + Shape + Stability + Volatility, datasource, nginx, Docker, CSVs,
  Python, Power BI, weights, thresholds, alerts, plugins, token, DPAPI, MCP untouched; JSON secret-free; no manual
  commit. **Oscar visually accepted on 2026-07-20** (Latest Event full row, status colors, data + all panels). **Stop before E7D.8 (Historical Timeline) — awaiting authorization.**
  Token `E7D7_EVENTS_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-events`. See `engineering/E7_grafana/E7D7_events_*` (6 docs).

- **E7D.8** — **Historical Timeline MVP** (governed chronological view) — **COMPLETED — VISUALLY ACCEPTED (Oscar, 2026-07-20)**. Rebuilt
  the Historical Timeline (uid `aegis-forecast-drift-timeline`, retained) from the E7D.0 shell into a **read-only** governed
  timeline. **Central rule upheld — NO FABRICATED HISTORY:** each of the **71** records is a governed drift event
  (`is_event=1`, run 1) positioned by **`forecast_version`** — the only governed field with real temporal spread (14
  versions in signals, **12 among events**, 2024-04→2026-05). `detected_on=created_at=changed_at` collapse to a **single**
  detection instant (2026-07-13 22:38 UTC) → surfaced as a fact, not 71 clumped rows. Lifecycle = **71 initial `Open`, 0
  transitions** → reported verbatim; no invented status changes; no invented Forecast Generated / Alert Triggered activity.
  **Date Range is FUNCTIONAL (the key acceptance), proven live via `/api/ds/query`:** All **71** · YTD **40** · Last180d
  **32** · Last90d **5** · Last60d/30d **0** · 2024 **5** · 2025 **26** · 2026 **40**. Mechanism (reverse-engineered via
  probes 1–7): the Infinity backend **ignores the native time range** and cannot cast numbers/dates (`>=`/`<=` only on
  numbers; no `toDate`/`int64`/`startsWith`; `+` concatenates), so the timeline uses `fv_label='v'+forecast_version` and a
  **custom `date_range` variable** filtering by `contains('${date_range:raw}', '|'+fv_label+'|')` over pipe-bounded version
  haystacks; the **native time picker is hidden** (would be a dead control). **14 panels:** nav, header, temporal-model note,
  KPIs (Timeline Records 71 / Drift Events 71 / Forecast Versions 12 / Affected Forecast Keys 12 / Lifecycle Records 71),
  Historical Timeline table (drift by forecast_version, newest first, colored family+status, wrapped explanation), Drift
  Events by Forecast Version barchart (chronological, sums to 71), Timeline Records by Forecast Key barchart, Historical
  Details table (Timeline Date / Date Basis / Timeline Type / Forecast Key / Region / Previous Version / Drift Family /
  Drift Score / Drift Status / Lifecycle Status / Explanation / Run ID), Latest Governed Run (1·Success·168·71), Data Quality
  (`18 / 18 checks passed`). **7 filters:** forecast_key, forecast_version (`fv_label`), region, drift_status, run_id,
  drift_family, **date_range** (custom, default *All available history*). **Documented deviations:** native picker hidden;
  no Timeline Type dropdown (single governed category); filter set adds region+forecast_version+drift_family vs the E7D.0
  matrix; **Timeline Records == Drift Events (=71)** by construction. **GATES A–F all pass; reconciliation 0 discrepancies.**
  Published **only** the Timeline dashboard via `V2/scripts/push-e7d8-timeline.ps1` (token DPAPI in-memory) → **v3**,
  `success`, in folder, 14 panels, keepTime=false/includeVars=true/UTC/timepicker hidden; shell archived at
  `V2/grafana/dashboards/archive/aegis-forecast-drift-timeline-shell.json`. All other dashboards + CSV/Python/PBI/datasource/nginx/Docker/token/DPAPI/MCP/weights/
  thresholds **unchanged**; no manual commit. **Visual repair before acceptance:** Data Quality rebuilt as the known-good
  Shape/Stability/Volatility **stat** (`dq = checks_passed + ' / ' + checks_total`, `colorMode background`, no organize
  transform) after the initial `dq_label`+`lastNotNull` stat rendered “No data”; Lifecycle Records `textMode`→`value`
  (republished **v5**). **Oscar visually accepted 2026-07-20** (18 / 18 large green, KPIs 71/71/12/12/71, Latest Run,
  Date Range functional). Token `E7D8_HISTORICAL_TIMELINE_MVP_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-timeline`. See `engineering/E7_grafana/E7D8_timeline_*` (7 docs).

- **E7D.9A** — **Top Risk Navigation Consolidation** (navigation + shell only) — **COMPLETED — VISUALLY ACCEPTED (Oscar,
  2026-07-20)**. Consolidated the two ranking destinations **Top Forecast Keys** + **Top Scenarios** into one executive
  section **Top Risk**. **Canonical dashboard = the existing Top Forecast Keys shell, UID `aegis-forecast-drift-top-keys`
  preserved** (no link/provisioning breakage) — renamed *AEGIS Forecast Drift — Top Risk*, retagged `top-risk`/`e7d9a`,
  description set to the governed-ranking blurb; shell shows shared nav + 5 shared filters + header + a provisional note
  (*“Top Risk analytical content will be implemented in E7D.9B”*) + **5 collapsed rows** (Top Forecast Keys, Top Regions,
  Top Forecast Versions, Top Drift Families, Risk Details) **with no queries/data**. **Top Scenarios**
  (uid `aegis-forecast-drift-top-scenarios`) is **RETIRED FROM NAVIGATION / ABSORBED INTO TOP RISK** — `aegis-nav` tag
  removed (out of the dropdown), queries/UID untouched, preserved for rollback with a visible “consolidated into Top
  Risk” banner. Navigation applied to all 11 dashboards: the markdown nav panel lists 10 sections (Overview → Settings)
  with a single **Top Risk** link; `/api/search?tag=aegis-nav` returns **10** dashboards (Top Risk present, Top Scenarios
  absent). `includeVars=true`, `keepTime=false` preserved. Published via `V2/scripts/push-e7d9a-top-risk-navigation.ps1`
  (token DPAPI in-memory) — 11/11 `success`; backups under `archive/top-risk-navigation-pre-e7d9a/`. **No queries/KPIs/
  tables built; no dashboard deleted; no CSV/Python/datasource/Docker/nginx/token/DPAPI/MCP change; no manual commit.**
  **Stop before E7D.9B.** Token `E7D9A_TOP_RISK_NAVIGATION_COMPLETED_VISUALLY_ACCEPTED`.
  URL `http://localhost:3000/d/aegis-forecast-drift-top-keys`. See `engineering/E7_grafana/E7D9A_top_risk_*` (3 docs).

- **E7D.9B** — **Top Risk Dashboard Content** (governed rankings & concentration) — **COMPLETED — VISUALLY ACCEPTED (Oscar, 2026-07-20)**. Converted the E7D.9A shell (UID `aegis-forecast-drift-top-keys` **preserved**) into a governed
  executive/operational view: removed the 5 empty collapsed rows + provisional note and added **15 analytical panels**
  driven exclusively by the governed `forecast_drift_score` (primary ranking = **average per dimension**) and
  `forecast_drift_family_scores` (family ranking, aggregated **standalone** — never joined-then-counted). KPI row
  (Forecast Keys 12 · Avg 28.83 · Critical 14 · Drift Events 71), Highest-Risk Forecast Key (**NAM-SDF 42.74**), Top
  Forecast Keys / Regions / Forecast Versions bars, Top Drift Families + Drift Family Computability, **Risk
  Concentration Matrix** (key × family, built from signals **native** family columns — **no join**), **Consolidated Risk
  Details** (168 rows, per-signal governed explanations, drill links to Forecast/Events/Historical Timeline), Latest
  Governed Run + Data Quality (18/18). **Cardinality Gate A PASS** (signals 168 = 168 distinct id; family_scores
  672 = 168×4; no signals×family_scores join). All rankings/KPIs/matrix reconcile to the served CSVs with **zero diffs**;
  ternary computed columns validated live via `/api/ds/query`. Published via `V2/scripts/push-e7d9b-top-risk.ps1`
  (token DPAPI in-memory) → `success` version 4, then **repaired & republished version 5** (a read-only audit found
  id51/id60 averaged non-computable family scores as 0 → fixed: id51 computable-only mean via `family_score != ''` +
  counts joined by `drift_family`; id60 four per-metric `!= ''` queries joined by `forecast_key`, empties → null not 0;
  **Oscar visually accepted** Volatility 56.04, Performance 7.71, matrix NAM-SDF 82.21/8.80); E7D.9A shell archived to
  `archive/aegis-forecast-drift-top-risk-shell-e7d9a.json`. **Documented deviations:** per-key Dominant Family omitted
  from the summary (14 versions/key, no groupBy mode); Family panels honor Forecast Key + Forecast Version only
  (family_scores lacks region/status/run); family bar colored by severity thresholds (brand colors in
  computability/matrix/details). **No CSV/Python/PowerBI/datasource/Docker/nginx/token/DPAPI/MCP/weights/thresholds
  change; no other dashboard touched; no manual commit; R1 unchanged.** Token
  `E7D9B_TOP_RISK_DASHBOARD_COMPLETED_VISUALLY_ACCEPTED`. **Stop before E7D.11 (not yet authorized).** URL `http://localhost:3000/d/aegis-forecast-drift-top-keys`. See
  `engineering/E7_grafana/E7D9B_top_risk_*` (8 docs).
- **E7D.10** — ~~Top Scenarios~~ — **ABSORBED INTO TOP RISK** at E7D.9A; no standalone implementation.
- **E7D.11** — **Settings & Data Quality Dashboard Content** (governed checks & model parameters) — **COMPLETED —
  VISUALLY ACCEPTED (Oscar, 2026-07-20)**. Rebuilt the Settings & Data Quality dashboard (uid
  `aegis-forecast-drift-settings` **preserved**) from the E7D.0 shell into a governed, **read-only** view of the **18
  governed data-quality checks** + model parameters. **GATE A PASSED** — the 18 checks are sourced authoritatively from
  `validation/_data_quality_checks.csv` (18 rows, all PASS) + `checks.py`; **none invented / split / merged / renamed**
  (`canonical_check_name` verbatim; category/scope/rule/expected are a documented presentation layer). A reproducible
  generator `V2/scripts/build-e7d11-check-catalog.ps1` derives the machine-readable catalog
  `validation/forecast_drift_data_quality_checks.csv` (SHA-256 `9E76361…551EE1`) and **aborts if ≠ 18**. **Serving —
  Option B (Oscar-authorized 2026-07-20):** a **single** exact-match nginx allowlist rule
  (`location = /forecast_drift_data_quality_checks.csv`) was added (no wildcard, no directory listing,
  `location / { return 404; }` preserved); `nginx -t` OK; **only the aegis-csv container restarted** (Grafana not
  restarted). The catalog is served as a **byte-identical copy** in `data/processed/current/` (same checksum). Endpoint
  from the Grafana container: **HTTP 200**, 19 lines, 18 distinct IDs, 18 PASS, 0 FAIL. The catalog table reads it via
  **Infinity URL** `http://aegis-csv/forecast_drift_data_quality_checks.csv` (**not hardcoded, not inline**). **22
  panels** — Data Quality **18/18** (green), Checks Passed **18** / Failed **0** / Total **18**, Run Status Success,
  Latest Validation Run, **18-check catalog**, Checks by Category (9 derived categories → 18), Governed Weights
  (20/40/30/10 = 100), Status Thresholds & boundary behavior ([0,20)/[20,40)/[40,70)/[70,100]), Computability Coverage
  (156/168 · 168/168 · 168/168 · 144/168), Non-Computable Reasons (NO_REALIZED_OVERLAP 12 · INSUFFICIENT_VERSIONS 24),
  Dataset Inventory (168/672/71/1/18), Data Lineage, Governance Rules, Known Limitations, Latest Governed Run —
  Provenance. All figures reconcile to the governed CSVs / `settings.py` with **zero diffs**, verified live via
  `/api/ds/query`. Published via `V2/scripts/push-e7d11-settings-data-quality.ps1` (token DPAPI in-memory) → `success`
  version 4; E7D.0 shell archived to `archive/aegis-forecast-drift-settings-shell-e7d11.json`. **No score / weight /
  threshold / validation-logic change; no other dashboard touched; no manual commit; R1 unchanged.** Token
  `E7D11_SETTINGS_DATA_QUALITY_COMPLETED_VISUALLY_ACCEPTED`. **Carry-over to E7D.12:** verify the governed refresh
  auto-regenerates the `validation/` + `current/` catalog copies (matching SHA-256). **Stop before E7D.12 (not yet
  authorized).** URL `http://localhost:3000/d/aegis-forecast-drift-settings`. See `engineering/E7_grafana/E7D11_*` (10 docs).
- **E7D.12** — Final Integration, Regression Validation & Deployment Readiness. **Completed — visually
  accepted (Oscar, 2026-07-20).** Consolidated the **10 active dashboards** (Top Scenarios retired from nav,
  preserved for rollback) into one governed, reproducible, local product. The governed refresh
  `V2/scripts/sync-governed-data.ps1` now **regenerates the 18-check data-quality catalog inside a transactional,
  idempotent** run (DryRun supported; rolls back on any mismatch), so the served catalog stays in lockstep with
  `_data_quality_checks.csv` and is never hand-generated — `validation == served` (SHA-256 `9E76361…551EE1`), manifest
  `catalog_refresh_integrated=true`, emits `CATALOG_REFRESH_INTEGRATED=True` (E7D.11 carry-over resolved). Added local
  `start-aegis-grafana.ps1` / `stop-aegis-grafana.ps1` and four read-only validators
  (`validate-e7-final.ps1` → **`E7_FINAL_VALIDATION_PASS`**, `test-aegis-endpoints.ps1`, `test-aegis-navigation.ps1`,
  `test-aegis-data-quality.ps1`). Navigation (10 `aegis-nav`, native dropdown includeVars=true/keepTime=false, Top
  Scenarios absent, no legacy datasource), 5 shared filters, and per-dashboard data all reconcile to the live CSVs.
  Secret scan **0 matches**. Backup/rollback package `V2/release/e7-final/` (+ `SHA256SUMS.txt` / `ROLLBACK.md` /
  `UID_INVENTORY.md` / `VERSION_INFO.md`); deployment-readiness `engineering/E7_grafana/deployment_readiness/`
  (blocker: `http://aegis-csv` won't resolve in a corporate portal). `aegis-csv` `restart: unless-stopped` (already
  satisfied). No formula/weight/threshold/UID/datasource-UID/DPAPI/MCP change; no plugins/alerts/deletes; **no
  deployment**; no manual commit; R1 unchanged. Token `E7D12_FINAL_INTEGRATION_COMPLETED_VISUALLY_ACCEPTED` (Oscar
  visually accepted 2026-07-20); global E7 close `E7_GRAFANA_V2_COMPLETED_DEPLOYMENT_READY`. **AEGIS Forecast Drift
  V2 is finished and locally validated; deployment-ready; NOT yet deployed.**
  **Next:** Corporate Grafana Portal Deployment — **requires separate authorization; NOT started** (`http://aegis-csv`
  is a local source and must be replaced by a governed source reachable from the portal). See
  `engineering/E7_grafana/E7D12_*` (12 docs). URL `http://localhost:3000/dashboards?tag=aegis-nav`.
