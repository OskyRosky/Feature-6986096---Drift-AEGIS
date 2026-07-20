# E7D.11 — Filter Validation

**Stage:** E7D.11 · **Date:** 2026-07-20

## Filter model
Settings & Data Quality is a **run-scoped governance page**, not an analytical slice-and-dice page. It exposes a single template variable:

- **`run_id`** (Infinity query over `forecast_drift_runs.csv`, `includeAll`/`multi`, default **All**). In the current governed snapshot there is exactly **one** run (`calculation_run_id = 1`), so the picker has one value plus **All**.

The analytical filters used on Overview/Timeline/Top Risk (forecast_key, forecast_version, region, drift_status, drift_family) are intentionally **not** present here: every panel is either run-scoped (checks, run provenance) or a governed-config/reference panel (weights, thresholds, lineage). This avoids "No data caused by configuration".

## Panels and their scope
| Panel | Source | Scope | Honors run_id |
|---|---|---|---|
| DQ 18/18, Checks Passed/Failed/Total, Run Status (id 10–14) | runs.csv | run | ✓ (`calculation_run_id IN (${run_id:singlequote})`) |
| Latest Validation Run (id 20) | runs.csv | run | ✓ |
| Check Catalog (id 30) | served catalog | run 1 (catalog carries `calculation_run_id`) | shows all 18 (single run) |
| Checks by Category (id 40) | served catalog | derived | n/a (grouping) |
| Weights / Thresholds (id 50/52) | settings.py (markdown) | governed config | n/a |
| Computability / Non-computable (id 60/62) | family_scores.csv | run | single run |
| Inventory / Lineage / Governance / Limitations (id 70/72/80/82) | manifest / static | reference | n/a |
| Latest Governed Run — Provenance (id 90) | runs.csv | run | ✓ |

## Tests
| Test | Expected | Result |
|---|---|---|
| `run_id = All` | all run-scoped panels render run 1; DQ 18/18 | ✓ (baseline) |
| `run_id = 1` | identical to All (single run) | ✓ (baseline) |
| Catalog column filter `Status = PASS` | 18 rows | ✓ (all PASS) |
| Catalog column filter `Category (derived)` | subset per category rollup | ✓ |
| No panel returns "No data" from configuration | none | ✓ |

Live filter clicks in the Grafana UI are confirmed by Oscar during visual acceptance; the values above are the governed baselines and were verified through `/api/ds/query`.
