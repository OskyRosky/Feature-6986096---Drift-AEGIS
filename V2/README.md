# AEGIS Forecast Drift — V2 (Grafana Product)

**Feature 6986096 — Integrate Cross-Functional Capacity Feedback Signals.**
Microsoft internal / confidential.

V2 is the **self-contained Grafana consumption product** for the AEGIS Forecast
Drift Framework. It visualizes the four governed drift datasets produced by the
**V1 authoritative Python Drift Engine**. No business or drift logic lives in V2 —
*"el dashboard no cocina datos."*

## Governance

- **V1 = authoritative producer** (read-only from V2's perspective, never mutated).
- **V2 = synchronized consumption snapshot.** `V2/data/processed/` holds a
  **byte-equivalent (SHA256-verified)** copy of the V1 governed outputs.
- All drift math, thresholds, weights, and classifications stay in the V1 engine.

## Layout

```
V2/
├─ data/processed/
│  ├─ current/        # 4 governed CSVs (signals 168, family 672, events 71, runs 1)
│  ├─ metadata/       # run_metadata.json (calculation_version, etc.)
│  ├─ validation/     # data-quality + fixture results
│  └─ data_manifest.json   # per-file origin, dest, SHA256, rows, snapshot timestamp
├─ scripts/
│  └─ sync-governed-data.ps1   # governed V1 -> V2 snapshot sync (idempotent, no secrets)
├─ grafana/provisioning/datasources/aegis-infinity.yaml
├─ nginx/default.conf
├─ docker-compose.yml          # aegis-csv (read-only CSV server on aegis-net)
└─ .env.example                # AEGIS_CSV_DIR override (defaults to ./data/processed/current)
```

## Refreshing the snapshot

After a new V1 Drift Engine run, refresh the V2 snapshot:

```powershell
pwsh V2/scripts/sync-governed-data.ps1
```

The script copies only the governed allow-list, validates row counts
(168/672/71/1) and SHA256 (fails hard on mismatch), and regenerates
`data_manifest.json`. It never writes to V1.

## Serving to Grafana

`docker compose up -d aegis-csv` starts the nginx CSV server, which bind-mounts
`V2/data/processed/current/` **read-only** and serves it at `http://aegis-csv`
inside the `aegis-net` Docker network (no host port). The pre-existing Grafana
(13.0.1) reads it through the **Infinity** datasource
`AEGIS Forecast Drift CSV` (uid `aegis-forecast-drift-csv`).

## Stage history

- **E7A** — Grafana readiness + Infinity datasource (served from V1).
- **E7A.1** — Infinity Functional Query Validation Gate: manual authenticated
  Grafana queries returned 168/672/71/1 (Query Inspector); health check OK; CSV
  parsing + null tolerance PASS; per-panel type hints deferred to E7C/E7D.
  Token `E7A_INFINITY_QUERY_GATE_COMPLETED`. See
  `engineering/E7_grafana/E7A1_infinity_manual_query_evidence.md`.
- **E7A.2** — V2 governed data snapshot + datasource rewire (self-contained V2).
  See `engineering/E7_grafana/E7A2_*`.
- **E7B.0** — Formal closure of E7A.1 (docs + evidence, no MCP). Token
  `E7B0_E7A1_FORMAL_CLOSURE_COMPLETED`. See
  `engineering/E7_grafana/E7B0_closure_summary.md`.
- **E7B.1** — MCP Connection Preflight — not started (awaiting authorization).
