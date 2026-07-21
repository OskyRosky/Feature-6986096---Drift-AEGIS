# E7D.12 — Refresh Integration (transactional, idempotent)

**Script:** `V2/scripts/sync-governed-data.ps1` (extended in E7D.12)
**Carry-over from E7D.11:** the 18-check data-quality catalog is now regenerated as
part of the governed refresh, not by a separate manual step.

## What the refresh does
1. Validates governed CSV row counts against expected values
   (signals 168 / family_scores 672 / event_history 71 / runs 1). Abort on mismatch.
2. Syncs the byte-equivalent V1 → V2 governed snapshot (SHA256-verified per file).
3. **Integrated catalog step (E7D.12):**
   - Validates the authoritative `validation/_data_quality_checks.csv`
     (must be 18 rows, 18 PASS, 0 FAIL; failures are never hidden).
   - Validates the run row reports `checks_total = checks_passed = 18`.
   - Backs up the prior catalog copies to `.prev` (rollback point).
   - Regenerates the served catalog via `build-e7d11-check-catalog.ps1`.
   - Verifies `validation == served` by SHA256 and re-asserts 18 rows / 18 PASS /
     0 FAIL / 18 distinct DQ ids. On any failure it rolls back and aborts.
4. Writes `data_manifest.json` with `stage = "E7A.2 + E7D.12"`,
   `catalog_refresh_integrated = true`, and per-file hashes.

## Transactional / safety properties
- `-DryRun` previews everything and writes nothing.
- Idempotent: re-running with unchanged inputs reproduces identical checksums.
- Aborts (no partial promotion) if the source is not exactly 18 rows, any check
  FAILs, or checksums differ.
- Prior snapshot preserved for rollback.

## Evidence — DryRun
```
[sync-governed-data] Source OK — 18 checks, 18 PASS, 0 FAIL; run checks 18/18.
[sync-governed-data]   [dry-run] would regenerate + verify the catalog (validation == current, 18/18).
[sync-governed-data] DRY-RUN complete — all sources, row counts and catalog source validated; NOTHING was written.
[sync-governed-data]   catalog_refresh_integrated = True
```

## Evidence — real idempotent run
```
CATALOG WRITTEN — rows=18 pass=18 run=1 checked_at=2026-07-13T22:44:10.988426+00:00
SHA256(validation)=9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1
SHA256(served)   =9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1
identical        =True
[sync-governed-data]   Catalog OK — 18 rows / 18 PASS / 0 FAIL; validation == current (9E76361…551EE1).
[sync-governed-data] Manifest written: V2/data/processed/data_manifest.json
[sync-governed-data] CATALOG_REFRESH_INTEGRATED = True
[sync-governed-data] Snapshot sync COMPLETED - 9 governed files, all SHA256-verified.
```

**Result: `CATALOG_REFRESH_INTEGRATED = True` — PASS.**
