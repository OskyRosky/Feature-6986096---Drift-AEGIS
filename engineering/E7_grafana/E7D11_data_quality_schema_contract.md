# E7D.11 — Data-Quality Catalog Schema Contract

**Stage:** E7D.11 · **Date:** 2026-07-20
**Artifact:** `V2/data/processed/validation/forecast_drift_data_quality_checks.csv` (+ byte-identical served copy in `current/`).

## Provenance & integrity
- **Authoritative source:** `validation/_data_quality_checks.csv` (columns `check,result,detail`, 18 rows).
- **Generator:** `V2/scripts/build-e7d11-check-catalog.ps1` — reproducible, driven by the source CSV; **aborts** if the source ≠ 18 checks, if a source check lacks documented metadata, or if built rows ≠ 18 / PASS ≠ 18. Writes the validation artifact, its `.sha256`, and a byte-identical served copy whose checksum is asserted equal.
- **SHA-256 (both copies):** `9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1`.
- **Encoding:** UTF-8, CSV, all fields quoted (Windows PowerShell `Export-Csv`). The Infinity backend CSV parser handles quoted fields.

## Column schema (15 columns)
| # | Column | Type | Governed? | Description |
|---:|---|---|---|---|
| 1 | `calculation_run_id` | string | governed | Run that produced the checks (1). |
| 2 | `check_order` | number | derived | 1..18 presentation order. |
| 3 | `check_id` | string | derived | `DQ-01`..`DQ-18` stable identifier. |
| 4 | `canonical_check_name` | string | **governed (verbatim)** | Exact `check` value from the engine output. |
| 5 | `display_name` | string | derived | Human-friendly label (1:1 with canonical). |
| 6 | `category` | string | derived | Presentation grouping justified by `checks.py`. |
| 7 | `scope` | string | derived | Dataset/config the check targets. |
| 8 | `rule_description` | string | derived | Plain-language rule (1:1 with `checks.py`). |
| 9 | `expected_value` | string | derived | Expected outcome. |
| 10 | `observed_value` | string | governed-derived | Source `detail` when present, else faithful pass statement. |
| 11 | `check_status` | string | **governed** | `result` (PASS/FAIL) from the engine output. |
| 12 | `severity` | string | derived | Constant `blocking` (all governance checks are blocking). |
| 13 | `evidence_source` | string | derived | `validation/_data_quality_checks.csv`. |
| 14 | `evidence_reference` | string | governed-derived | `checks.py::run_checks -> <name> = <detail>`. |
| 15 | `checked_at_utc` | timestamp | governed | Run `run_finished_at` (2026-07-13T22:44:10Z). |

## Rules
- **No invention.** Every row corresponds to exactly one source check; the loop is source-driven.
- **Canonical preserved.** `canonical_check_name` is never altered; `display_name`/`category`/`scope` are additive presentation.
- **Determinism.** Re-running the generator on the same inputs yields the identical checksum.
- **Serving.** The served copy is generated (never hand-edited) and must carry the same checksum as the validation copy; the generator fails otherwise.
