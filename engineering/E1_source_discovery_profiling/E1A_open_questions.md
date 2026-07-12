# E1A — Open Questions (to validate in E1B and with stakeholders)

**Feature 6986096 — AEGIS Forecast Drift Framework**
Two blocks: **(A) Stakeholder / scope questions** (from Blueprint §16 — business decisions) and **(B) Technical data questions** (to confirm with live SQL in E1B). Nothing here is answered by assumption.

---

## A. Stakeholder / scope questions (Blueprint §16)

| # | Question | Owner | Blocks |
| --- | --- | --- | --- |
| A1 | Which forecast metrics are prioritized for MVP (MAPE / Bias / Accuracy / TTL)? | Boon | E3 Performance Drift |
| A2 | Which scenarios and keys are included first? | Sihui | E1B scope, E2 |
| A3 | Which forecast versions should be compared (all history / last N)? | Chinmay | E3 Shape/Stability/Volatility |
| A4 | Which target dates are tracked for Stability Drift? | Boon | E3 Stability |
| A5 | What thresholds define Watch / Warning / Critical (0-20/20-40/40-70/70+)? | Boon / Nayeli | E3 scoring, E4 |
| A6 | Should TTL be included in Drift Score v0? | Sihui | E3 Performance, source #5 |
| A7 | Power BI only, or SQL + Power BI first? | Boon | E5/E6 ordering (engineering roadmap already chose SQL-first) |
| A8 | Which downstream consumers need access first? | — | E4 output contract |

---

## B. Technical data questions (confirm live in E1B — no SQL run yet)

| # | Question | Why it matters | Blocks |
| --- | --- | --- | --- |
| B1 | How many historical **ForecastVersions** exist in `forecast_substrateBE_hdd_region`, how far back, and at what cadence? | The ingestion pins to `MAX(ForecastVersion)`; drift needs multiple versions | Shape, Stability, Volatility (all three) |
| B2 | Do the `*_metrics` tables retain **multiple `Forecast_Version` rows** per Key, or only the latest? | Performance Drift tracks metric change across versions | Performance Drift |
| B3 | Is there exactly **one `ModelVersion` per Key per version**, or several? | Determines the comparison unit for shape/stability | E2 grain, E3 |
| B4 | Where does **`Service`** live? Is it derivable from `Key`, or a separate dimension/table? | Blueprint UX groups by Service; fact table exposes only `Key/Scenario/Resource` | E2 Information Model |
| B5 | **Forest vs Region grain** — should drift run at region (`Key` like `APC-*`) or forest (`_hdd_forest_metrics`, keys like `NAMP108`) or both? | Affects grain, volume, and joins | E2, E3 |
| B6 | **Scenario/Resource scope** for MVP — Enterprise + HDD only, or include SSD/other resources & scenarios (Basilisk)? | Bounds the data pulled | E1B queries, E2 |
| B7 | Semantics of metric window (`Start_Date`/`End_Date`) — fixed window or per-version rolling? Comparable across versions? | Performance Drift compares like-for-like windows | Performance Drift |
| B8 | Is `vw_SubstrateBE_MonthsToLive_*` a **governed, queryable** source (grain, columns, refresh)? | TTL is optional for Drift Score v0 | Performance (TTL), A6 |
| B9 | For **Stability Drift**, which fixed future target dates have coverage across enough versions to be meaningful? | Depends on B1 + target-date density | E3 Stability |
| B10 | Actuals availability lag vs forecast target dates (how much of the horizon has actuals)? | Drift is designed to fire even before actuals; confirm boundary | E3 Performance vs pre-actual families |

---

## Notes
- The engineering roadmap has already answered A7 in principle (**SQL/model-first, Power BI last**); confirm with Boon so expectations align.
- B1 and B2 are the **highest-priority** unblockers: together they decide whether all four drift families are computable on existing data.
- All B-questions are designed to be answered by **read-only** profiling queries in E1B (counts, DISTINCT versions, MIN/MAX dates) — no data mutation.
