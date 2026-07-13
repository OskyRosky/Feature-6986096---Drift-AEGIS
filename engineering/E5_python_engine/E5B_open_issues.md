# E5B — Open Issues

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

## Resolved in E5B
| # | Issue | Resolution |
| --- | --- | --- |
| I1 | Key case/whitespace variants split entity history | `canonicalize.py`: non-destructive raw+canonical, collision report, semantic guard. Validated 9→7 (2 merged) on fixture. |
| I2 | Console UnicodeEncodeError on U+2011 path (cp1252) | `logger.ensure_utf8_stdout()`; scripts/tests print relative names. Fixtures exit 0. |
| I3 | Performance sparse (shallow, metric-version misalignment) | `performance_deep.py` deep MAPE recompute; explicit `perf_mode`; coverage 13→78 / 85 on fixture. |
| Atomicity | partial outputs on crash | `.tmp`→`os.replace` atomic writes; failed quality gate does not overwrite. |
| Layout | flat outputs, no retention | `current/ metadata/ validation/ history/` + optional snapshot. |
| Refresh | ad-hoc run_sample only | `scripts/run_refresh.py` reproducible entrypoint with exit codes. |

## Still open (non-blocking for E6)
| # | Issue | Impact | Plan |
| --- | --- | --- | --- |
| O1 | **Live expanded real sample not yet run** in this session (DB env/MFA) | offline validation complete; real-data numbers pending | operator runs `run_refresh --source live --profile expanded --perf-mode deep`; confirms canonicalization/grain/runtime on real data |
| O2 | **pyarrow absent** → no Parquet emitted | CSV is the working contract | `pip install pyarrow` in the drift env (authorize) to enable Parquet + round-trip check |
| O3 | **pytest absent** | fixtures run via standalone runner | optional `pip install pytest`; convert `test_fixtures.py` assertions |
| O4 | Deep vs shallow productive default undecided | affects Performance coverage in E6 | decide after live sample; default shallow, deep as labelled alternative |
| O5 | E3 config `confidence_high_coverage=100` vs engine HIGH≥90 | cosmetic reconciliation | correct E3 config CSV to 90 in a docs pass |
| G3 | No Service dimension | Top Services partial in E6 | mark partial; nullable `service` column present |
| G4 | region↔forest mapping absent | grouping/UX only | nullable `forest`; add mapping when available |
| G7 | TTL view not probed | out of drift scope | future |

## Deferred (need authorization)
Full-history run; anchor/weight/threshold calibration on real distributions;
writing to SQL/Fabric; scheduler/automation; Power BI (E6); Grafana (E7);
cloud deployment (E8).
