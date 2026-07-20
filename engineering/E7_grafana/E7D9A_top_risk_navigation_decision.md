# E7D.9A — Top Risk Navigation Consolidation — Decision

**Stage:** E7D.9A — Top Risk Navigation Consolidation (navigation + destination shell only)
**Date:** 2026-07-20
**Status:** COMPLETED — VISUALLY ACCEPTED (Oscar, 2026-07-20)
**Token:** `E7D9A_TOP_RISK_NAVIGATION_COMPLETED_VISUALLY_ACCEPTED`

## 1. Product decision

The navigation previously exposed **two** separate ranking destinations:

- **Top Forecast Keys**
- **Top Scenarios**

These are consolidated into a **single** executive prioritization section: **Top Risk**.

Rationale:
1. Both are concentration / ranking views of the same governed drift risk.
2. `scenario` is **not** a confirmed governed dimension (the snapshot holds a single value, `Enterprise`).
3. Keeping Top Scenarios risks surfacing non-existent / simulated information.
4. One executive prioritization dashboard is clearer.

Scenario analysis will only be (re)introduced in a later stage **if** a real governed scenario dimension is proven.

## 2. Canonical dashboard selection

| Candidate | UID | Decision |
|-----------|-----|----------|
| Top Forecast Keys | `aegis-forecast-drift-top-keys` | **CANONICAL — reused as Top Risk (UID preserved)** |
| Top Scenarios | `aegis-forecast-drift-top-scenarios` | Absorbed / retired from navigation (preserved for rollback) |

Why Top Forecast Keys is canonical:
- It already sits in the correct folder (`AEGIS Forecast Drift`, uid `afsjccp27s0e8d`).
- Its UID is the more stable/used ranking destination and was the one earmarked as **E7D.9** in the roadmap.
- Reusing it keeps existing `/d/aegis-forecast-drift-top-keys` links and provisioning intact.
- It carries the richer shared-filter set (5 variables: region, forecast_key, forecast_version, drift_status, run_id).

Rules honored:
- ✅ UID of the canonical dashboard preserved (`aegis-forecast-drift-top-keys`).
- ✅ No third dashboard created.
- ✅ Top Scenarios **not** deleted, **not** overwritten, UID **not** swapped.
- ✅ No existing URL broken without documentation (see risks/rollback below).

## 3. What was built (navigation + shell only — NO analytical content)

**Canonical → Top Risk** (`aegis-forecast-drift-top-keys.json`):
- Title → `AEGIS Forecast Drift — Top Risk`.
- Tags → `["aegis","forecast-drift","aegis-nav","top-risk","e7d9a","shell"]`.
- Description → *"Governed ranking and concentration view for forecast drift risk across forecast keys, regions, forecast versions, drift families and severity."*
- Shell content: shared nav panel + header + provisional note *"Top Risk analytical content will be implemented in E7D.9B."* + **5 collapsed rows** with no queries/data: **Top Forecast Keys**, **Top Regions**, **Top Forecast Versions**, **Top Drift Families**, **Risk Details**.
- 5 shared filters retained; NO KPIs / tables / queries added.

**Top Scenarios retirement** (`aegis-forecast-drift-top-scenarios.json`):
- `aegis-nav` **dashboard tag removed** → no longer in the AEGIS Sections dropdown.
- Description → `RETIRED FROM NAVIGATION — consolidated into Top Risk (E7D.9A). Preserved for rollback...`.
- Visible banner added: *"This dashboard has been consolidated into Top Risk."*
- Queries and UID **unchanged**.

**Navigation applied to all 11 dashboards:** the markdown nav panel (id1) now lists 10 sections with a single **Top Risk** link (`/d/aegis-forecast-drift-top-keys`); the `Top Forecast Keys` + `Top Scenarios` pair was replaced everywhere.

## 4. Navigation contract (unchanged rules)

- Top Risk links to the canonical dashboard `/d/aegis-forecast-drift-top-keys`.
- `includeVars = true`, `keepTime = false` (no inherited `from`/`to`).
- Compatible shared filters preserved.
- Top Risk appears exactly once; other section names unchanged.

## 5. Deferred to E7D.9B

All analytical content — Top Forecast Keys ranking, Top Regions, Top Forecast Versions, Top Drift Families,
Risk Details, KPIs, drift-score / event / explanation aggregations — is **out of scope for E7D.9A** and will be
built in **E7D.9B**. The provisional note and empty collapsed rows are placeholders to be replaced in E7D.9B.
