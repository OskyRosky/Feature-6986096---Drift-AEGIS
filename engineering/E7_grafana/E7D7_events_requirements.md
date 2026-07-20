# E7D.7 — Events Dashboard · Requirements

**Stage:** E7D.7 — AEGIS Forecast Drift · Forecast Drift Events Dashboard MVP
**Date:** 2026-07-19
**Dashboard:** `AEGIS Forecast Drift — Events` · uid `aegis-forecast-drift-events`
**Outcome token (pre-review):** `E7D7_EVENTS_MVP_IMPLEMENTED_PENDING_VISUAL_ACCEPTANCE`

## Objective

Transform the Events shell into a **read-only operational dashboard** that lets Oscar query and
analyze the governed forecast-drift **event log**. The dashboard answers:

1. How many drift events exist? → **Total Events** KPI (71).
2. Which are the most recent? → **Latest Event** + descending **Governed Event Log**.
3. Which Forecast Keys are affected? → **Affected Forecast Keys** KPI (12) + Events by Forecast Key.
4. Which families generate the most events? → **Events by Drift Family** (Shape 26 / Stability 24 / Volatility 15 / Performance 6).
5. Which events are Warning / Critical? → **Warning** (34) / **Critical** (14) KPIs + Events by Drift Status.
6. What score is associated with each event? → **Drift Score** column (`forecast_drift_score`).
7. What governed explanation/context exists? → **Explanation** column (`explanation`, 71/71 populated).
8. From which Forecast Version / Region / Run? → columns + **Latest Governed Run**.
9. Date/time of the event? → **Event Timestamp** column (`detected_on`, 2026-07-13 UTC).
10. Which operational fields are not yet available? → documented below (service, scenario, separate severity, event_type).

## Mandatory principles honored

- Read-only: **no** resolve / acknowledge / close / edit actions.
- No invented lifecycle statuses. The only governed lifecycle field, `event_status`, exists and is
  surfaced verbatim (constant value **Open**).
- `drift_status` is treated as the governed **severity band** (Healthy/Watch/Warning/Critical), not an
  operational state. No **separate** Severity is invented (`severity` is a partial alias of
  `drift_status` and is not surfaced).
- No invented **Scenario**, **Service** or **Event Type**; those columns are empty / single-valued /
  absent in the governed snapshot.
- No keys/services/explanations copied from the mockup. The mockup's "170 events" is illustrative;
  the governed baseline is **71**.

## Baseline (governed V2 snapshot, run 1)

| Metric | Value |
|---|---:|
| Total Events (`is_event = 1`) | 71 |
| Critical / Warning / Watch / Healthy | 14 / 34 / 13 / 10 |
| Family shape / stability / volatility / performance | 26 / 24 / 15 / 6 |
| Affected Forecast Keys | 12 |
| Forecast Versions among events | 12 |
| Events with explanation | 71 / 71 |
| Max drift score | 84.72 |
| Latest run `events_created` | 71 (reconciles) |

## Scope boundary

Only the Events dashboard and its E7D.7 artifacts are modified. Overview, Forecast, Performance,
Shape, Stability and Volatility are untouched. Historical Timeline, Top Forecast Keys, Top Scenarios
and Settings & Data Quality are **not** started. No CSV / Python / Power BI / datasource / nginx /
Docker / token / DPAPI / MCP / weights / thresholds changes. No plugins, alerts, deletes or manual commit.
