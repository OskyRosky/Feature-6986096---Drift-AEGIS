# E7D.12 — Structural & Visual Validation

Two layers: (A) **structural** checks that are automatable from JSON/API/data
(completed, PASS); (B) **visual acceptance** by Oscar (pending).

## A. Structural checks (automated) — PASS
| # | Check | Result |
|---|---|---|
| 1 | 11 dashboard JSON files present (10 active + 1 retired) | PASS |
| 2 | Dashboard UIDs unique | PASS |
| 3 | No placeholder / shell / "Panel Title" / TODO text in active dashboards | PASS |
| 4 | Every panel datasource = `aegis-forecast-drift-csv` (no legacy datasource) | PASS |
| 5 | No broken / unknown datasource UID references | PASS |
| 6 | Native `aegis-nav` dropdown present on all 10 active dashboards | PASS |
| 7 | Top Scenarios absent from navigation | PASS |
| 8 | 5 governed CSV endpoints serve expected line counts (169/673/72/2/19) | PASS |
| 9 | Directory listing blocked; `/healthz` returns `ok` | PASS |
| 10 | Data-quality catalog 18/18/0, validation == served (SHA256) | PASS |
| 11 | Orchestrator verdict | `E7_FINAL_VALIDATION_PASS` |

No placeholder panels, empty filters, red-triangle datasource errors, or legacy
datasources were detected structurally.

## B. Visual acceptance (Oscar) — ACCEPTED (2026-07-20)
Confirmed by Oscar in the running Grafana (`http://localhost:3000`, folder "AEGIS
Forecast Drift"). The agent browser is unauthenticated; Oscar validated the visuals.

- [x] Navigation dropdown lists exactly the 10 sections in order (Overview →
      Settings & Data Quality); Top Scenarios not shown.
- [x] Each dashboard renders with no red-triangle / datasource error and no empty
      panels.
- [x] Shared filters behave (Forecast Key, Forecast Version, Region, Drift Status,
      Run ID); time range not inherited across sections.
- [x] Headline numbers match the regression baselines (e.g. Overview 168 / 71 / 12 /
      18-18; Top Risk NAM-SDF 42.74; Volatility avg 56.04 / coverage 85.7%).
- [x] Settings & Data Quality shows 18/18/0 with the 18 checks and weights
      20/40/30/10.

Additional confirmations by Oscar: no unexpected "No data"; Top Risk and Settings &
Data Quality correct; catalog DQ-01→DQ-18; release package 28 files / 28 hashes;
`RELEASE_MANIFEST_VALID=True`; `E7_FINAL_VALIDATION_PASS`.

**Oscar confirmed visual acceptance on 2026-07-20.** Closure token promoted to
`E7D12_FINAL_INTEGRATION_COMPLETED_VISUALLY_ACCEPTED`; global E7 close
`E7_GRAFANA_V2_COMPLETED_DEPLOYMENT_READY`. AEGIS Forecast Drift V2 is finished and
locally validated; deployment-ready; NOT yet deployed. Next step: Corporate Grafana
Portal Deployment (`http://aegis-csv` is a local source and must be replaced by a
governed source reachable from the portal).

Current token: `E7D12_FINAL_INTEGRATION_COMPLETED_VISUALLY_ACCEPTED`.
