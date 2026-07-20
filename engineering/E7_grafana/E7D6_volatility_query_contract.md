# E7D.6 — Volatility MVP · Query Contract

Datasource: **AEGIS Forecast Drift CSV** (`yesoreyeram-infinity-datasource`, uid `aegis-forecast-drift-csv`,
referenced by UID). Parser `backend`. Docker-internal URLs (never `localhost` inside queries):
`http://aegis-csv/forecast_drift_signals.csv`, `/forecast_drift_family_scores.csv`, `/forecast_drift_runs.csv`.

## Template variables (5)
All `queryType:"infinity"` wrapper, `includeAll:true`, `multi:true`, `allValue:null`, `refresh:1`, `sort:1`.

| Var | Source column | Notes |
|-----|---------------|-------|
| `forecast_key` | `forecast_key` (signals) | |
| `forecast_version` | `forecast_version` (signals) | computed column `__value = 'v' + forecast_version` → option value is the `fv_label` string |
| `region` | `region` (signals) | |
| `drift_status` | `drift_status` (signals) | |
| `run_id` | `calculation_run_id` (runs) | |

## Shared filter contract (signals-based panels: KPIs A/B/E + barchart G + details H)
```
region IN (${region:singlequote})
  && forecast_key IN (${forecast_key:singlequote})
  && fv_label IN (${forecast_version:singlequote})
  && drift_status IN (${drift_status:singlequote})
  && calculation_run_id IN (${run_id:singlequote})
  && volatility_drift_score != ''      # (omitted by Coverage D and Details H)
```
- `fv_label` = computed `'v' + forecast_version`; the version filter matches on this **label**, never a raw date.
- `${var:singlequote}` renders `'a','b'` so `IN (...)` stays valid for multi-select + All.
- Infinity requires `==` for equality (single `=` throws *"invalid filter expression. Invalid token '='"*);
  `!=` and `IN (...)` are valid as written.

## Per-panel contract
| id | Panel | Source | Query columns / computed | Transforms | Reducer |
|----|-------|--------|--------------------------|-----------|---------|
| 10 | **A** Average Volatility Drift Score | signals | `volatility_drift_score`+dims; shared filter **incl.** `!= ''` | `convertFieldType volatility_drift_score→number` | **mean** (dec 2, thr 20/40/70) |
| 11 | **B** Volatility Signals Computable | signals | `volatility_drift_score`+dims; shared filter **incl.** `!= ''` | — | **count** |
| 13 | **D** Volatility Coverage | signals | computed `is_comp = volatility_drift_score != ''`; shared filter **without** computability clause (denominator = all filtered rows) | `convertFieldType is_comp→number` | **mean** → % (percentunit dec1, thr red / 0.7 / 0.9) |
| 14 | **E** Maximum Volatility Drift Score | signals | `volatility_drift_score`+dims; shared filter **incl.** `!= ''` | `convertFieldType volatility_drift_score→number` | **max** (dec 2, thr 20/40/70) |
| 30 | **F** Volatility Drift Score Over Time | signals | `forecast_version` (timestamp) + `volatility_drift_score`; shared filter **minus** `fv_label`, **incl.** `!= ''` | `convertFieldType→number` + `groupBy forecast_version → mean` | series mean (linear, points always) |
| 40 | **G** Volatility Drift Score by Forecast Key | signals | `forecast_key` + `volatility_drift_score`; shared filter **incl.** `!= ''` | `convertFieldType→number` + `groupBy forecast_key → mean` + `sortBy mean desc` | **barchart** horizontal, showValue always (thr 20/40/70) |
| 50 | **H** Volatility Signal Details | signals | `forecast_key, forecast_version, previous_forecast_version, region, drift_status, volatility_drift_score, is_comp`; shared filter **without** computability clause (shows non-computable rows) | `convertFieldType` + `sortBy volatility_drift_score desc` + `organize` | table (Computable Yes/No) |
| 55 | **I** Volatility Profile — Governed Auxiliary Metrics | **family_scores** | `forecast_key, forecast_version, volatility_class, rolling_stddev, rolling_cov, rolling_mad, oscillation_count, sign_change_freq`; filter `drift_family == 'volatility' && eligibility_status == 'COMPUTED' && forecast_key IN(...) && fv_label IN(...)` | `convertFieldType` (5 numerics) + `sortBy rolling_cov desc` + `organize` | table |
| 56 | **J** Non-computable Summary | **family_scores** | `not_computable_reason, forecast_key`; filter `drift_family == 'volatility' && eligibility_status == 'NOT_COMPUTABLE' && forecast_key IN(...) && fv_label IN(...)` | `groupBy not_computable_reason → count(forecast_key)` + `sortBy count desc` + `organize` | table (Reason / Signals) |
| 60 | **K** Latest Governed Run | runs | selected by `run_id` | filter `calculation_run_id IN (${run_id})` | table |
| 70 | **L** Data Quality — Checks Passed | runs | computed `dq = checks_passed + '/' + checks_total` | `lastNotNull` | stat |

## Two-source design (documented exception)
The governed volatility auxiliaries (`rolling_stddev`, `rolling_cov`, `rolling_mad`, `oscillation_count`,
`sign_change_freq`, `volatility_class`) exist **only** in `forecast_drift_family_scores.csv`, which has no
`region` / `drift_status` / `calculation_run_id` / `previous_forecast_version` columns. `region` / status / run
live **only** in `signals.csv`. A per-row merge honoring all five filters would need a fragile cross-CSV
composite-key join over the equal 168-row universe, which breaks Grafana's outer-join filtering. **Decision:**
keep two tables — **Details (id50)** from signals honoring all five filters, and **Volatility Profile (id55)**
from family_scores honoring only `forecast_key` + `forecast_version`. The Non-computable Summary (id56) is also
family_scores-scoped and honors the same two filters.

## Boolean-computed-column rule (critical)
A computed column such as `volatility_drift_score != ''` / `is_comp` returns to Grafana as a **boolean** frame
field. Numeric reducers (`mean`, `max`) over a boolean yield **empty**. Every numeric reduction over such a
column **must** be preceded by `convertFieldType → number` (applied on id10/13/14/30/40, plus the 5 aux numerics
on id55). Same fix first used for Coverage in E7D.3 and reused for Shape/Stability.

## Computability handling
- **Averages & maximum** (id10/14/40/30) exclude non-computable signals via `volatility_drift_score != ''` —
  they are never treated as zero.
- **Coverage** (id13) keeps the full filtered universe as denominator (no computability clause) → 85.7 % at All,
  and **dynamic** (e.g. a non-computable version selection yields 0 %).
- **Details** (id50) omits the computability clause so non-computable rows are visible with `Computable = No`.
- **Trend** (id30) starts at **2024-06-01** (first computable bucket); the two non-computable versions
  (`2024-04-01`, `2024-05-01`) are excluded, not zeroed.
