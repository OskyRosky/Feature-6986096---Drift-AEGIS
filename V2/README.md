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
- **E7D.1** — **Overview MVP** (analytical panels) — **REPAIRED, PENDING VISUAL ACCEPTANCE**. Transformed the
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
  Published via `V2/scripts/push-e7d1-overview.ps1` (token DPAPI in-memory) → **v6**, `success`, in folder;
  other 10 dashboards untouched; datasource/nginx/Docker/CSV/Python/PBI/weights/thresholds unchanged; no
  alerts/plugins/deletes; no manual commit. **Oscar visually confirmed the Overview now shows data**;
  formal sign-off pending. Token `E7D1_OVERVIEW_MVP_REPAIRED_PENDING_VISUAL_ACCEPTANCE`.
  URL `http://localhost:3000/d/aegis-forecast-drift-foundation`. See `engineering/E7_grafana/E7D1_*` (5 docs).
