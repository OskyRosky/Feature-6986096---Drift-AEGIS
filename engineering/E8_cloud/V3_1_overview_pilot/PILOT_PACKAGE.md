# V3.1 — Overview Pilot Package (LOCAL, review-only)

**Token:** `V3_1_OVERVIEW_PILOT_PACKAGE_PREPARED_PENDING_PORTAL_APPROVAL`
**Prepared:** 2026-07-21 · **Scope:** local artifacts only — **no Azure, no Grafana portal, no tokens, no SAS, no secrets.**

> **STATUS: PREPARED — NOT YET READY TO IMPORT.**
> Two conditions must be met before this dashboard may be imported (see §7):
> 1. The **real Infinity datasource configuration is confirmed** (plugin present + base URL + auth model).
> 2. A **UID collision check** is performed in the target portal.
> Until both are satisfied, do **not** change UIDs and do **not** declare this ready to import.

---

## 0. Package contents

| File | Purpose |
|---|---|
| `overview-original.json` | Item 1 — exact copy of the V3 Overview dashboard (`aegis-forecast-drift-foundation.json`, 769 lines, SHA-256 `4A1DF596…08C22`). Unmodified. |
| `overview-portal-migration.json` | Item 2 — migration copy with every `http://aegis-csv` replaced by placeholder `__AEGIS_CSV_BASE_URL__`. No secrets. 769 lines, SHA-256 `6DBEC0BA…C6412`. |
| `csv-checksums.txt` | Items 4 & 8 — SHA-256, sizes, counts of the 2 CSVs + reconciliation numbers. |
| `PILOT_PACKAGE.md` | This document (items 3, 5, 6, 7, 9, 10, 11, 12). |

Target Azure context (from the read-only audit, for reference only — **not touched**):
- Managed Grafana **`CapswatComparisions`** · RG `aegis-rg` · sub `994480df-3b35-4498-ae3c-043319315359` · westus2 · Standard X1.
- Storage **`aegisforecasti0654609440`** (blob endpoint `https://aegisforecasti0654609440.blob.core.windows.net/`, `allowBlobPublicAccess=false` → authenticated access required).

---

## 1. Dashboard Overview original (V3)

`overview-original.json` — byte-for-byte copy of
`V3/grafana/dashboards/aegis-forecast-drift-foundation.json`.

- `uid`: `aegis-forecast-drift-foundation` · `title`: "AEGIS Forecast Drift — Overview"
- `schemaVersion`: 39 · `tags`: aegis, forecast-drift, aegis-nav, overview, e7d1
- 5 template variables + 16 panels (2 text, 7 stat, 1 piechart, 1 timeseries, 1 barchart, 2 table, +2 stat DQ/run).
- Datasource used everywhere: type `yesoreyeram-infinity-datasource`, uid `aegis-forecast-drift-csv`.

## 2. Migration copy prepared for the portal (no secrets)

`overview-portal-migration.json` — identical to the original **except** the 18 data-source URLs, where the local host `http://aegis-csv` was replaced by the neutral placeholder `__AEGIS_CSV_BASE_URL__`.

- Replacements applied: **18** · Remaining `aegis-csv` strings: **0** · Placeholders: **18**.
- UIDs **unchanged on purpose** (dashboard uid and datasource uid preserved — see §7 collision gate).
- Secret scan (`sig= / sv= / se= / sp= / SharedAccessSignature / AccountKey / password / secret / Bearer / token=`): **0 matches**.

---

## 3. Exact query & CSV inventory

**Two CSVs are required — and only two:** `forecast_drift_signals.csv` and `forecast_drift_runs.csv`.

### 3a. Template variables (5)

| Variable | CSV | Column(s) | Notes |
|---|---|---|---|
| `forecast_key` | signals | `forecast_key` | multi, includeAll |
| `forecast_version` | signals | `forecast_version` | computed `'v' + forecast_version` → `__value` |
| `region` | signals | `region` | multi, includeAll |
| `drift_status` | signals | `drift_status` | multi, includeAll |
| `run_id` | runs | `calculation_run_id` | multi, includeAll |

### 3b. Panels (16)

| id | Title | Type | CSV | Key columns / logic |
|---|---|---|---|---|
| 1 | (nav bar) | text | — | markdown links |
| 2 | (header) | text | — | markdown |
| 10 | Total Signals | stat | signals | count(`drift_event_id`) |
| 11 | Total Events | stat | signals | count where `is_event == 1` |
| 12 | Avg Drift Score | stat | signals | mean(`forecast_drift_score`) |
| 13 | Critical | stat | signals | `drift_status == 'Critical'` |
| 14 | Warning | stat | signals | `drift_status == 'Warning'` |
| 15 | Watch | stat | signals | `drift_status == 'Watch'` |
| 16 | Healthy | stat | signals | `drift_status == 'Healthy'` |
| 20 | Drift Status Distribution | piechart | signals | groupBy `drift_status`, count |
| 21 | Avg Drift Score Over Time | timeseries | signals | groupBy `forecast_version`, mean score (ignores forecast_version filter by design) |
| 22 | Signals by Dominant Drift Family | barchart | signals | groupBy `dominant_drift_family`, count |
| 23 | Forecast Keys by Drift Risk | table | signals | groupBy `forecast_key` → mean/max score, count → **distinct keys = 12** |
| 24 | Latest Governed Run | table | runs | `calculation_run_id, run_status, run_finished_at, signals_written, events_created` |
| 25 | Data Quality — Checks Passed | stat | runs | `checks_passed / checks_total` |

Shared filter expression on all signals panels:
`region IN (${region:singlequote}) && forecast_key IN (${forecast_key:singlequote}) && fv_label IN (${forecast_version:singlequote}) && drift_status IN (${drift_status:singlequote}) && calculation_run_id IN (${run_id:singlequote})`
(panel 21 omits the `fv_label` clause by design). Runs panels (24, 25) filter by `calculation_run_id IN (${run_id:singlequote})`.

---

## 4. Checksums & counts of both CSVs

See `csv-checksums.txt`. Summary:

| CSV | SHA-256 | bytes | cols | rows |
|---|---|---|---|---|
| forecast_drift_signals.csv | `D975B4655DADDFA51F6F3EE4C9388D54197A842C3BC87E9BCF3D94B21C34AEE5` | 97 325 | 54 | 168 |
| forecast_drift_runs.csv | `361BB46BBD6B616BD29581D451F638E4E7C25BAA74E15874153D7014498F06CD` | 444 | 18 | 1 |

`runs.csv` columns (18): calculation_run_id, calculation_version, formula_version, threshold_config_id, weight_config_id, run_started_at, run_finished_at, source_forecast_version_max, signals_written, events_created, runtime_seconds, peak_memory_mb, checks_passed, checks_total, idempotent, perf_mode, run_status, created_by.

---

## 5. Expected datasource contract

| Field | Value / Requirement |
|---|---|
| **Name** (display) | proposed `AEGIS Forecast Drift CSV` (portal display name — free to choose) |
| **UID** | `aegis-forecast-drift-csv` — **must equal** the uid referenced by every panel/variable. **Do NOT rename yet**; verify no collision in the portal first (§7). If a collision exists, a coordinated uid change in BOTH the datasource and the dashboard is required. |
| **Plugin required** | `yesoreyeram-infinity-datasource` (Grafana Infinity, community). Must be installed/available on `CapswatComparisions`. |
| **URL format** | Each query URL = base + `/forecast_drift_signals.csv` or `/forecast_drift_runs.csv`. In the migration copy these read `__AEGIS_CSV_BASE_URL__/…`. At import time resolve to **either** (a) a datasource base URL + relative paths, **or** (b) the full HTTPS blob base. |
| **Query type** | `csv`, `source=url`, `parser=backend`, `root_selector=""`, method GET. |
| **Config to keep SECURE** | The storage **SAS / auth** (because `allowBlobPublicAccess=false`). It must live **only** in the datasource config (secure field / URL secure query param), **never** in the dashboard JSON, never in git, never in this package. |

---

## 6. Substitutions required to remove `http://aegis-csv` (18 total)

Replace every `http://aegis-csv/<file>.csv` with `<resolved base>/<file>.csv`.
In the migration copy the intermediate placeholder is `__AEGIS_CSV_BASE_URL__`.

| Where | CSV | Count |
|---|---|---|
| Variables: `forecast_key`, `forecast_version`, `region`, `drift_status` | signals | 4 |
| Variable: `run_id` | runs | 1 |
| Panels 10, 11, 12, 13, 14, 15, 16, 20, 21, 22, 23 | signals | 11 |
| Panels 24, 25 | runs | 2 |
| **Total** | | **18** |

Breakdown by endpoint: `http://aegis-csv/forecast_drift_signals.csv` → **15**; `http://aegis-csv/forecast_drift_runs.csv` → **3**.

---

## 7. Import plan (step by step)

> Gate A and Gate B **must pass first**. This package is *prepared*, not *ready-to-import*.

1. **Gate A — Infinity datasource confirmation.** Confirm on `CapswatComparisions` (data-plane / portal): (a) the Infinity plugin is installed/available; (b) the intended datasource base URL; (c) the auth model (SAS in secure field). *Control-plane `grafanaPlugins=null` is not conclusive — verify via Administration → Plugins or `/api/plugins`.*
2. **Gate B — UID collision check.** In the target portal verify that datasource uid `aegis-forecast-drift-csv` and dashboard uid `aegis-forecast-drift-foundation` are **not already taken**. If taken, plan a coordinated uid change (both datasource + dashboard) — **not done in this package**.
3. **Storage** (needs Storage access — see §11): create a container, upload the 2 CSVs, generate a **read-only SAS**. *(Not part of this package.)*
4. **Datasource** (needs Grafana Admin — see §10): create the Infinity datasource per §5, put the base URL + SAS in the **datasource** config only.
5. **Resolve placeholders**: replace `__AEGIS_CSV_BASE_URL__` in the migration copy with the resolved base (or switch the 18 URLs to datasource-relative paths).
6. **Folder + import**: create a dedicated "AEGIS Forecast Drift" folder; import the resolved migration JSON into it. Do not touch the team's Substrate dashboards.
7. **Reconcile** (§8) and capture evidence.

---

## 8. Expected reconciliation

| KPI | Expected | Panel / source | Evidence |
|---|---|---|---|
| **Signals** | **168** | panel 10 count(drift_event_id) | signals rows = 168; runs.signals_written = 168 |
| **Drift Events** | **71** | panel 11 count(is_event==1); panel 24 events_created | signals is_event=1 → 71; runs.events_created = 71 |
| **Forecast Keys** | **12** | panel 23 distinct forecast_key | distinct(forecast_key) = 12 |
| **Data Quality** | **18 / 18** | panel 25 checks_passed/checks_total | runs.checks_passed=18, checks_total=18 |

Supporting distribution (panels 13–16, 20): Critical 14 · Warning 34 · Watch 38 · Healthy 82 (Σ = 168).

---

## 9. Rollback plan

All pilot changes are additive and isolated — rollback = delete, in reverse order:
1. Delete the imported Overview dashboard.
2. Delete the dedicated "AEGIS Forecast Drift" folder (if empty).
3. Delete the Infinity datasource `aegis-forecast-drift-csv` (only if created for this pilot).
4. Revoke/expire the read-only SAS; delete the uploaded CSVs; delete the container.
5. (Optional) Uninstall the Infinity plugin **only** if it was installed solely for this pilot **and** no other dashboard depends on it — confirm with the Grafana Admin first.

The team's existing Substrate CPU/HDD dashboards and datasources are never modified, so no rollback touches them. Local artifacts in this package are unaffected by any portal action.

---

## 10. Actions the Grafana Admin must perform

*(Audit finding: the Grafana Admin on `CapswatComparisions` is user `38f2f24f-0fa6-4348-991e-6a2bacde2daf` — not Oscar. Oscar's only observed path is Grafana **Viewer** via a group, unverified → cannot perform these.)*
1. Confirm / install the **Infinity plugin** (`yesoreyeram-infinity-datasource`).
2. Perform the **UID collision check** (Gate B).
3. Create the **Infinity datasource** and store the base URL + SAS in its secure config.
4. Create the dedicated **folder** and **import** the resolved migration dashboard.
5. (If needed) grant Oscar **Grafana Editor/Admin** to let him run steps 3–4 himself.

## 11. Actions that require Storage access

*(Audit finding: 0 direct role assignments for Oscar on storage `aegisforecasti0654609440`.)*
1. Create a blob **container** for the governed CSVs.
2. **Upload** `forecast_drift_signals.csv` + `forecast_drift_runs.csv`.
3. Generate a **read-only SAS** (container/blob-scoped, time-limited) for the datasource.
4. (Optional) Store the SAS in Key Vault `aegisforecasti2896306308`.
Requires e.g. **Storage Blob Data Contributor** (upload) + rights to generate SAS, or an Owner/Contributor to grant them.

## 12. No-secrets confirmation

- **No SAS, token, key, password, or secret was incorporated** into any file in this package.
- Automated secret scan over both JSON artifacts: **0 matches** (`sig= / sv= / se= / sp= / SharedAccessSignature / AccountKey / password / secret / Bearer / token=`).
- The only auth (storage SAS) is deferred to the **datasource** config at import time and is explicitly kept out of the dashboard JSON and git.
- No Grafana token was requested or generated. No Azure write was performed.
