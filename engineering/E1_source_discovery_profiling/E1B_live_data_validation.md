# E1B — Live Data Validation

**Feature 6986096 — AEGIS Forecast Drift Framework**
**Stage:** E1B — Source Discovery & Data Profiling (Live Data Validation)
**Date:** 2026-07-12
**Method:** Read-only `SELECT` queries against Tesseract (`TesseractEarthDW`) via **Entra ID `ActiveDirectoryInteractive`**, reusing the Code Improvement ingestion config. **No** INSERT/UPDATE/DELETE/MERGE/DDL. Evidence captured as aggregates + `head()`/`TOP`.

> Governance: Microsoft internal / confidential. Server host and connection string are not reproduced here. Read-only only; no data mutated.

---

## 1. Executive summary

Live data **confirms all four Drift families are computable** on data that already exists. The key enabler is verified: `forecast_substrateBE_hdd_region` holds **48 monthly Enterprise ForecastVersions (2021-06-01 → 2026-05-01)**, and **177,898** (Key, target-date) cells have ≥2 versions — exactly the forecast-vs-forecast history Shape/Stability/Volatility need. Grain is clean: **exactly one model per Key per version**. Performance metrics (MAPE/MAE/RMSE/Bias/SMAPE/Accuracy) exist in the `*_metrics` tables but with **only 3 retained versions** — so deep Performance Drift needs recomputation from actuals+forecasts. Three concrete caveats to handle in E2/E3: a **duplicate load in version 2025-06-01**, the **absence of a `Service` column** (must be mapped from `Key`), and the **forward-only** rule for cross-version comparison.

---

## 2. Queries executed (all read-only)

| # | Objective | Query | Result |
| --- | --- | --- | --- |
| 1.1 | Version history | distinct ForecastVersion, range, total rows | 49 versions, 2021-06-01→2026-05-29, 10,193,190 rows |
| 1.2 | Cadence by scenario | versions per Scenario | Enterprise 48, Consumer 47, Basilisk 1 |
| 1.3 | Enterprise cadence | rows per Enterprise version | monthly 2021-06 → 2026-05 (48 versions) |
| 2.1 | Grain | total vs distinct 7-col grain | 10,193,190 vs 9,915,884 (dupes exist) |
| 2.2 | Duplicates | grain HAVING COUNT>1 | all dupes are ForecastVersion=2025-06-01 (x2) |
| 2.3 | Domains | distinct ValueType/Resource/Scenario/ModelVersion | Forecast-Mean only; HDD only; 3 scenarios; many models |
| 2.4 | Model per cell | DISTINCT ModelVersion per Key/version | **1** (one model per Key per version) |
| 3.2 | Multi-version cells | Key+target with ≥2 versions (Enterprise HDD) | **177,898** cells |
| 3.0/3.1 | Cross-version values | value by version for one Key+target | 44–45 versions for a single target date |
| 3.3 | Shape curves | full horizon curve for 3 latest versions | 4,335 rows (curves available per version) |
| 4.1 | Metrics retention | distinct Forecast_Version per *_metrics table | region 3, forest 3, ssd_lvwe 1, ssd_lvne 1 |
| 4.2 | Metrics cadence | region rows per version | 2026-03-07 / 04-16 / 05-01 |
| 4.3 | Metrics schema | TOP 3 region metrics | MAPE/MAE/RMSE/Bias/… all present |
| 5.1 | Actuals coverage | actual rows, range, keys | 547,074 rows 2019-07-01→2026-05-25, 45 keys |
| 5.2 | Forecast horizon | latest Enterprise version range | 2026-04-28 → 2030-04-25, 45 keys |
| 5.3 | Actuals per scenario | actual rows by scenario | Enterprise 318,414 / Consumer 224,971 / Basilisk 3,689 |
| 6.1 | Scenario×Resource | matrix | Enterprise/HDD 5.09M/52 keys/48 v; Consumer/HDD 5.02M; Basilisk/HDD 74k/1 v |
| 6.2 | Region keys | sample distinct keys | APC-DEDICATED, EUR-*, NAM-* … (region-embedded) |
| 6.3 | Forest vs region keys | distinct key counts | forest 155 (APCP150…) vs region 45 |
| 6.4 | Table inventory | substrateBE tables | 40 tables (cpu/iops/ssd/hdd/…) |
| 6.5 | Column inventory | columns of substrateBE objects | **no `Service` column** in hdd_region |

---

## 3. head() of principal results

**1.1 ForecastVersion history**
```
 n_versions    first_v     last_v  total_rows
         49 2021-06-01 2026-05-29    10193190
```
**1.2 Cadence per scenario**
```
  Scenario  n_versions    first_v     last_v   rows_
Enterprise          48 2021-06-01 2026-05-01 5094743
  Consumer          47 2021-06-01 2026-05-01 5024285
  Basilisk           1 2026-05-29 2026-05-29   74162
```
**2.1 / 2.2 Grain + duplicate**
```
 total_rows  distinct_grain
   10193190         9915884     -> 277,306 duplicate rows
duplicates ALL have ForecastVersion=2025-06-01, count=2
```
**2.4 Models per Key per version = 1**
```
Key            ForecastVersion Scenario   n_models
CHE-Go Local   2021-06-01      Enterprise        1
...                                              1
```
**3.2 Multi-version cells (the drift enabler)**
```
 multi_version_cells
              177898
```
**3.1 Stability example — FRA-GO LOCAL, target 2022-01-14 (value changes across versions)**
```
ForecastVersion   Value
2021-06-01   26482.11
2021-07-01   27609.81
2021-08-01   24221.63
2021-09-01   28208.56
2022-01-01   31854.21
2022-02-01   31925.87  <- freezes once target date has passed
```
**4.1 Metrics retention (shallow)**
```
table      n_versions  range
region     3           2026-03-07 .. 2026-05-01
forest     3           2026-04-06 .. 2026-05-01
ssd_lvwe   1           2026-03-12
ssd_lvne   1           2026-03-12
```
**4.3 Region metrics columns present**
```
Key, Count, Mean_Actual, Mean_Forecast, MAE, RMSE, Bias, Bias_Pct, MAPE, SMAPE, Accuracy, Forecast_Version, Start_Date, End_Date, Execution_Date
```
**5.x Actuals + horizon**
```
actuals: 547,074 rows, 2019-07-01 .. 2026-05-25, 45 keys
latest Enterprise forecast horizon: 2026-04-28 .. 2030-04-25, 45 keys
Enterprise 318,414 / Consumer 224,971 / Basilisk 3,689 actual rows
```
**6.5 Service check**
```
hdd_region columns = DateTime, Key, Value, ModelVersion, ForecastVersion, Scenario, Resource, ValueType
-> NO Service, NO Fleet, NO Region column (CPU tables have Fleet/Workload, HDD does not)
```

---

## 4. Findings by objective

**Objective 1 — Version history & cadence:** ✅ Rich. 48 Enterprise versions, **monthly cadence** 2021-06 → 2026-05. Consumer parallel (47). Basilisk = single recent version. Overall table 10.19M rows.

**Objective 2 — Grain:** ✅ Clean, with one caveat. Forecast grain = `Key × DateTime × ForecastVersion × Scenario` (Resource=HDD, ValueType=Forecast-Mean, and **exactly one ModelVersion per cell**). Duplicate load: **ForecastVersion 2025-06-01 has every row twice** (277,306 dupes). ValueType is only `Forecast-Mean` (no upstream intervals).

**Objective 3 — Same Key + target across versions:** ✅ Strong. **177,898** forward cells with ≥2 versions; single target dates covered by up to 44 versions; full horizon curves per version. Nuance: value **freezes** once the target date passes the forecast version → cross-version comparison must be restricted to **forward** cells (`target_date >= forecast_version`).

**Objective 4 — Metrics version retention:** ⚠️ Shallow. Official `*_metrics` keep only **3** versions (region/forest) or **1** (ssd). All Performance columns (MAPE/MAE/RMSE/Bias/Bias_Pct/SMAPE/Accuracy) are present. Deep Performance Drift over the 48-version history requires **recomputing** metrics from actuals+forecasts.

**Objective 5 — Actuals & metrics availability:** ✅ Good. Actuals 2019-07-01 → 2026-05-25 (45 keys); latest forecast horizon to 2030-04-25. Actuals split by scenario (Enterprise 318k). Sufficient overlap for Performance and for pre-actual drift.

**Objective 6 — Dimensions:** ⚠️ Mapping needed. Fact table has **52 keys** (governed = 45); region is **embedded in `Key`**; **no `Service` column** exists in `hdd_region`; **forest** metrics use a **different key namespace** (155 keys, `APCP…`). 40 `substrateBE` tables exist (CPU/IOPS/SSD/HDD/…) — other resources are separate tables.

---

## 5. Drift computability by family

| Family | Computable? | Basis (validated) | Caveat / transformation |
| --- | --- | --- | --- |
| **Performance** | ✅ Yes (shallow via metrics; deep via recompute) | `*_metrics` MAPE/Bias/Accuracy with `Forecast_Version` (3 versions) | Only 3 metric versions → recompute from actuals+forecasts for deeper history |
| **Shape** | ✅ Yes | Full horizon curves per version; 177,898 multi-version cells | Dedupe 2025-06-01; compare forward horizon; define curve distance |
| **Stability** | ✅ Yes | Same Key+future target across up to 44 versions | Forward-only (`target_date >= forecast_version`); value freezes after target passes |
| **Volatility** | ✅ Yes | Cross-version value series per Key+target | Needs ≥N versions per cell; rolling variance/CoV; forward-only |

**All four families are computable on existing data.**

---

## 6. Validated base structure, keys, transformations

**Validated base structure & keys**
- Fact `forecast_substrateBE_hdd_region`: grain `Key × DateTime × ForecastVersion × Scenario` (HDD, Forecast-Mean, 1 model/cell). Actuals = `ModelVersion='actual'`.
- Metrics `*_metrics`: grain `Key × Forecast_Version × window(Start_Date..End_Date)`.

**Sources & columns:** see `E1A_data_dictionary.csv` (updated with E1B status).

**Version history:** 48 Enterprise monthly versions 2021-06 → 2026-05 (fact); 3 versions (metrics region/forest); 1 (ssd).

**Temporal coverage:** actuals 2019-07-01 → 2026-05-25; forecast horizon → 2030-04-25.

**Reused fields (direct from source):** Key, DateTime, Value, ModelVersion, ForecastVersion, Scenario, Resource, ValueType; metrics MAPE/MAE/RMSE/Bias/Bias_Pct/SMAPE/Accuracy/Count/Mean_Actual/Mean_Forecast/Forecast_Version/Start_Date/End_Date/Execution_Date.

**Derived fields (to compute in E3):** `horizon_days`, `is_forward`, `value_delta`, `value_delta_pct` (Stability), `shape_distance` (Shape), `rolling_cov` (Volatility), `metric_delta` (Performance), then per-family sub-scores → drift_score → severity → drift_type → explanation.

**Required transformations:**
1. **Dedupe** exact duplicate rows (ForecastVersion 2025-06-01).
2. **Forward filter** `target_date >= forecast_version` for Shape/Stability/Volatility.
3. **Version pairing** ordered by (Key, Scenario) → consecutive-version deltas.
4. **Stability:** per fixed future target_date, `value_delta[/pct]` across versions.
5. **Shape:** per version, align horizon curve; distance between consecutive versions.
6. **Volatility:** rolling std / CoV over last N versions per (Key, target).
7. **Performance:** metric deltas across `Forecast_Version` (or recompute from actuals+forecasts for depth).
8. **Region/Service mapping:** parse region from `Key`; define Service source (TBD).

---

## 7. Gaps & blockers

| # | Item | Type | Action |
| --- | --- | --- | --- |
| G1 | ForecastVersion **2025-06-01 duplicated x2** | Data quality | Dedupe/exclude in E2 ingestion contract |
| G2 | Official metrics keep only **3 versions** | Coverage | Decide: 3-point Performance Drift vs recompute metrics from fact table |
| G3 | **No `Service` column** in hdd_region | Dimension gap | Map from Key / locate a dimension table (stakeholder input) |
| G4 | **Key namespace** region (45/52) vs forest (155) | Grain | Decide region vs forest grain for MVP |
| G5 | **Scenario scope** Enterprise/Consumer/Basilisk | Scope | Confirm MVP scenarios (likely Enterprise first) |
| G6 | **Forward-only** cross-version rule (value freezes post-target) | Method | Encode `is_forward` filter in all shape/stability/volatility logic |
| G7 | TTL view **not yet probed** | Coverage | Probe `vw_SubstrateBE_MonthsToLive_*` if TTL enters Drift Score v0 (Blueprint Q A6) |

---

## Status token
**E1B_LIVE_DATA_VALIDATION_COMPLETED** — read-only only; no data mutation; no commit; no advance to E2. All four Drift families validated as computable on existing data, subject to gaps G1–G7.
