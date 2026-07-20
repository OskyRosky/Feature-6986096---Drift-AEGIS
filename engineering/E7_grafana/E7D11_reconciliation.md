# E7D.11 — Reconciliation

**Stage:** E7D.11 · **Date:** 2026-07-20
**Method:** Values rendered by the dashboard (read live through the Grafana Infinity datasource, `/api/ds/query`) compared to the governed CSVs / `settings.py`. All diffs 0 or explained.

## Data quality
| Metric | Dashboard | Governed source | Diff |
|---|---:|---:|---:|
| Catalog rows | 18 | `_data_quality_checks.csv` = 18 | 0 |
| Distinct check IDs | 18 | 18 | 0 |
| PASS | 18 | 18 | 0 |
| FAIL | 0 | 0 | 0 |
| Data Quality headline | 18 / 18 | runs.csv checks_passed/total | 0 |
| Checks Passed / Total | 18 / 18 | runs.csv | 0 |
| Checks Failed | 0 | total − passed | 0 |
| Run Status | Success | runs.csv run_status | 0 |

Served-catalog checksum (`current/`) = validation-catalog checksum (`validation/`) = `9E76361…551EE1`. HTTP endpoint from the Grafana container: **200**, 19 lines (header + 18), 18 distinct `check_id`, 18 PASS, 0 FAIL.

## Governed weights (settings.py `WEIGHTS`)
| Family | Dashboard | settings.py | Diff |
|---|---:|---:|---:|
| Performance | 20% | 20.0 | 0 |
| Shape | 40% | 40.0 | 0 |
| Stability | 30% | 30.0 | 0 |
| Volatility | 10% | 10.0 | 0 |
| Sum | 100% | 100.0 | 0 |

## Status thresholds (settings.py `BANDS`) — boundary tests
| Score | Dashboard band | Expected | Match |
|---:|---|---|---|
| 0 | Healthy | Healthy | ✓ |
| 19.999 | Healthy | Healthy | ✓ |
| 20 | Watch | Watch | ✓ |
| 39.999 | Watch | Watch | ✓ |
| 40 | Warning | Warning | ✓ |
| 69.999 | Warning | Warning | ✓ |
| 70 | Critical | Critical | ✓ |
| 100 | Critical | Critical | ✓ |

## Computability (family_scores.csv, live via datasource)
| Family | Dashboard COMPUTED/Total | Governed | Diff |
|---|---:|---:|---:|
| Performance | 156 / 168 | 156 / 168 | 0 |
| Shape | 168 / 168 | 168 / 168 | 0 |
| Stability | 168 / 168 | 168 / 168 | 0 |
| Volatility | 144 / 168 | 144 / 168 | 0 |

Non-computable reasons: Performance `NO_REALIZED_OVERLAP` = 12; Volatility `INSUFFICIENT_VERSIONS` = 24. Diffs 0.

## Dataset inventory (data_manifest.json)
| Dataset | Dashboard | Manifest | Diff |
|---|---:|---:|---:|
| signals | 168 | 168 | 0 |
| family_scores | 672 | 672 | 0 |
| event_history | 71 | 71 | 0 |
| runs | 1 | 1 | 0 |
| catalog | 18 | 18 | 0 |

## Latest governed run (runs.csv)
Run ID 1 · Calculation Version `E5A-v1` · Finished `2026-07-13 22:44` UTC · Runtime 829.37 s · Peak 422.01 MB · Perf mode deep · Idempotent True · Created by drift_engine · Signals 168 · Events 71. All match `forecast_drift_runs.csv`.

**Result: all reconciliations pass with zero unexplained diffs.**
