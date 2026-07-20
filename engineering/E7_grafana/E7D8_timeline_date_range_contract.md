# E7D.8 — Historical Timeline · Date Range Contract

This is the most important contract of E7D.8: the **Date Range control is functional, not decorative**. It was reverse-engineered from the Infinity backend's real capabilities (probes 1–7, live `/api/ds/query`) and then proven with counts.

## Infinity backend constraints (PROVEN)
1. **The backend ignores the dashboard/native time range** — even for `type: timestamp` columns (71 rows returned regardless of the picker). → A native time picker cannot filter this CSV. **Decision: hide the native picker.**
2. **`filterExpression` operators:** `==`, `!=`, `IN (...)` work on strings; `>=`, `<=`, `>`, `<` work **only on numbers** (`forecast_version >= '2026-01-01'` → HTTP 400 "not a number").
3. **No string→number cast functions** (`int64`, `tonumber`, `toFloat`, `float`, `number`, `parseInt`, `double`, … all "Undefined function"). `+` **concatenates** strings.
4. **No date→epoch functions** (`toDate`, `date`, `unixEpoch`, `timestamp`, … all Undefined). `startsWith` is Undefined.
5. **Raw date columns are coerced:** `forecast_version == '2026-05-01'` → 0 rows. The v-prefixed computed key works: `fv_label == 'v2026-05-01'` → 5 rows.

## Working mechanism
Date Range is implemented as a **Grafana custom single-select variable** `date_range`. Each option value is a **pipe-bounded list of `fv_label` values** (a "haystack"). Panels add one clause:

```
&& contains('${date_range:raw}', '|' + fv_label + '|')
```

`contains(haystack, '|' + fv_label + '|')` returns true only when the record's version is inside the selected window. Pipe delimiters make membership exact (no partial matches). Option values contain **no commas and no colons**, so they survive Grafana's custom-variable query parsing.

## Windows (reference now = 2026-07-20, frozen snapshot)
| Option (label) | Haystack (fv_label members) | Expected events |
|----------------|------------------------------|-----------------|
| All available history *(default)* | all 14 versions | **71** |
| Year to date | v2026-01-01 … v2026-05-01 | **40** |
| Last 180 days | v2026-02-01 … v2026-05-01 | **32** |
| Last 90 days | v2026-05-01 | **5** |
| Last 60 days | `\|__none__\|` | **0** |
| Last 30 days | `\|__none__\|` | **0** |
| Year 2024 | v2024-04-01 … v2024-08-01 | **5** |
| Year 2025 | v2025-06-01 … v2025-12-01 | **26** |
| Year 2026 | v2026-01-01 … v2026-05-01 | **40** |

The windows are **static** because the governed snapshot is a single frozen run; "days ago" are computed once against 2026-07-20. `Last 60/30 days` legitimately return **0** because the most recent governed version (2026-05-01) is older than 60 days relative to the snapshot reference — this is surfaced honestly (empty result, not an error).

## Live proof (GATE B, `/api/ds/query`)
```
YTD        rows=40  (expect 40)   PASS
Last180d   rows=32  (expect 32)   PASS
Last90d    rows=5   (expect 5)    PASS
Last60/30d rows=0   (expect 0)    PASS
Year2024   rows=5   (expect 5)    PASS
Year2025   rows=26  (expect 26)   PASS
All        rows=71  (expect 71)   PASS
```

## Documented limitation
Free-form arbitrary date ranges (e.g. pick any two calendar dates) via the native picker are **not** wired to Infinity, because the backend cannot evaluate them. The discrete windows plus year buckets (2024 / 2025 / 2026) are the offered, honest substitute and cover the custom-range demonstration requirement.
