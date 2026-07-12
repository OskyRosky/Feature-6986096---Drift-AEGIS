# E1A — Source Profiling & Reuse (Document Discovery)

**Feature 6986096 — AEGIS Forecast Drift Framework**
**Stage:** E1A (Document Discovery & Reuse) — no live SQL executed.
**Method:** Reviewed the Blueprint V2, the HTML prototype, and the existing **AEGIS Forecasting / Code Improvement** project (ingestion code + governed data contract). All findings below are grounded in real source code and real CSV headers from Code Improvement; none require a live connection to state.

> Governance: Microsoft internal / confidential. This document deliberately omits the SQL server host, connection strings, and credentials. Database object (table/view/column) names are included because they are required to design the information model.

---

## 1. Source inventory

| # | Source object | Type | Provides | Drift family served |
| --- | --- | --- | --- | --- |
| 1 | `dbo.forecast_substrateBE_hdd_region` | Fact table | Forecast values + actuals, per Key/target date/**ForecastVersion** | Shape, Stability, Volatility (+ actuals for Performance) |
| 2 | `dbo.forecast_substrateBE_hdd_region_metrics` | Metrics table | Official accuracy metrics per Key per Forecast_Version | **Performance** |
| 3 | `dbo.forecast_substrateBE_hdd_forest_metrics` | Metrics table | Same metrics at **forest** grain (finer than region) | Performance (finer grain) |
| 4 | `dbo.forecast_substrateBE_ssd_phx_lvwe_metrics` / `_ssd_phx_lvne_metrics` | Metrics tables | Same metrics for SSD/Phoenix resources | Performance (other resources, future) |
| 5 | `vw_SubstrateBE_MonthsToLive_Snapshot` / `_TimeSeries` | Views (referenced, not ingested) | TTL / months-to-live signal | Performance (TTL), optional |
| 6 | Code Improvement `data/processed/` contract | Governed CSVs | forecasts / actuals / entities / run_metadata (LATEST version only) | Reference pattern + single-version reuse |

**Column sets (verbatim from Code Improvement):**

- Fact `forecast_substrateBE_hdd_region`: `DateTime, Key, Value, ModelVersion, ForecastVersion, Scenario, Resource, ValueType`.
- Metrics `*_metrics`: `Key, Count, Mean_Actual, Mean_Forecast, MAE, RMSE, Bias, Bias_Pct, MAPE, SMAPE, Accuracy, Forecast_Version, Start_Date, End_Date, Execution_Date`.
- Processed contract: `forecasts.csv(entity_key,date,forecast_value,model_version,forecast_version,scenario,resource,value_type,source_file)`; `actuals.csv(entity_key,date,actual_value,forecast_version,scenario,resource,source_file)`; `entities.csv(entity_key,first/last_actual_date,first/last_forecast_date,actual_rows,forecast_rows,model_count)`; `run_metadata.csv(run_timestamp,forecast_version,...,entity_count,model_count,...)`.

---

## 2. THE key enabler for Drift — ForecastVersion history

The Code Improvement ingestion **always** pins to the latest version:

```
WHERE [ForecastVersion] = (SELECT MAX([ForecastVersion]) ... Scenario='Enterprise' AND ValueType='Forecast-Mean')
```

Its own code comment warns that many ForecastVersions coexist in the table (other scenarios/newer runs). **Consequence:**

- The governed `data/processed` layer keeps **one** forecast_version (`2026-05-01`) → good for Accuracy, **insufficient for Drift**.
- Shape / Stability / Volatility Drift compare **forecast-vs-forecast across versions**, so they must read the fact table **without the MAX filter**, selecting multiple ForecastVersions for the same `Key` + `DateTime`.
- This is the single most important thing to confirm in **E1B**: how many historical ForecastVersions exist, their cadence, and how far back.

---

## 3. Grain analysis

| Dataset | One row represents | Grain keys |
| --- | --- | --- |
| Fact (forecast values) | one predicted value for one future date, from one model, in one version | `Key × DateTime × ModelVersion × ForecastVersion × Scenario × Resource × ValueType` |
| Fact (actuals) | one observed value for one date | `Key × DateTime` (ModelVersion='actual') |
| Metrics tables | accuracy of one Key for one version over one evaluation window | `Key × Forecast_Version × (Start_Date..End_Date)` |
| Processed forecasts.csv | latest-version forecast point | `entity_key × date` (one model_version, one forecast_version) |

Open grain question (for the Information Model / E1B): the Blueprint UX references **Scenario / Key / Service / Forest / Region**, but the fact table exposes `Key`, `Scenario`, `Resource` only. Region appears embedded in `Key` (e.g. `APC-*`); **Service** and **Forest** need explicit mapping — forest metrics exist as a separate table (`_hdd_forest_metrics`, keys like `NAMP108`).

---

## 4. Field coverage per Drift family

| Drift family | Needs | Available today? | Source |
| --- | --- | --- | --- |
| **Performance** | MAPE, MAE, RMSE, Bias, SMAPE, Accuracy per version | ✅ Yes (upstream) | `*_metrics` tables (have `Forecast_Version`) |
| **Performance (TTL)** | months-to-live | ⚠️ Referenced, not ingested | `vw_SubstrateBE_MonthsToLive_*` (needs governance validation) |
| **Shape** | forecast trajectory (curve) across ≥2 versions | ⚠️ Data exists in fact table but only latest is materialized | `forecast_substrateBE_hdd_region` without MAX filter |
| **Stability** | same target_date value across versions | ⚠️ Same as Shape | same |
| **Volatility** | rolling variance/CoV across versions | ⚠️ Same as Shape | same |

**Reading:** Performance Drift is the **best-supported** family (metrics tables already carry a version axis). Shape, Stability and Volatility all depend on the **same single enabler** — multi-ForecastVersion history in the fact table — which is the primary E1B validation.

---

## 5. Reuse map from Code Improvement (what NOT to rebuild)

| Reuse | From Code Improvement | Status |
| --- | --- | --- |
| Connection recipe (pyodbc + ODBC Driver 18 + Entra ID Interactive, Encrypt=yes) | `python/ingestion/config.py` | Reuse as-is (reference, do not copy secrets/host) |
| Extraction pattern (parameterized SELECTs, version resolution) | `python/ingestion/queries.py`, `export_*.py` | Reuse pattern; **remove the MAX filter for drift history** |
| Source table + column semantics | fact + metrics tables | Reuse directly |
| Governed data contract style (typed CSV, run_metadata lineage) | `data/processed/*` | Reuse as design pattern for the drift output |
| Key/entity list (45 keys, 2019→2030 coverage) | `entities.csv`, `run_metadata.csv` | Reuse as reference scope |

**Rule (governance):** Drift **references or re-derives** from these sources; it does not copy pipeline logic into this repo. Repositories, prompts, decisions, deliverables and commits stay independent from Code Improvement.

---

## 6. Gaps / hypotheses to validate in E1B (live data)

1. **ForecastVersion history depth & cadence** in `forecast_substrateBE_hdd_region` (how many versions, how far back, how often produced). *Blocking for Shape/Stability/Volatility.*
2. **Metrics tables version retention** — do `*_metrics` keep multiple `Forecast_Version` rows or only the latest? *Blocking for Performance Drift over time.*
3. **Grain confirmation** — is there exactly one `ModelVersion` per Key per version, or several?
4. **Service / Forest / Region dimensionality** — where does `Service` live; forest vs region grain decision.
5. **Scenario & Resource scope** — Enterprise + HDD only for MVP, or include others.
6. **Metric window semantics** — meaning/stability of `Start_Date`/`End_Date` windows across versions.
7. **TTL governance** — is `vw_SubstrateBE_MonthsToLive_*` a governed, queryable source or roadmap.

These map 1:1 to the open-questions list (`E1A_open_questions.md`).
