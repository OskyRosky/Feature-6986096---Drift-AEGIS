# E6 — Local Refresh Runbook

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

Architecture: `Tesseract read-only → Python Drift Engine → governed CSV
(V1/data/processed/current) → Power BI Desktop`. Power BI never connects to
Tesseract and never recomputes drift.

## Correct order (always)
1. **Run Python** (produces/refreshes governed datasets).
2. **Validate outputs** (checks + row counts).
3. **Open / Refresh Power BI**.

## 1. Run the Python refresh
From the repo (VPN + Entra MFA required for `--source live`):
```powershell
$env:AEGIS_DRIFT_SQL_SERVER="<host>"; $env:AEGIS_DRIFT_SQL_DATABASE="<db>"
cd "V1\python"
python -m drift_engine.scripts.run_refresh --source live --profile expanded --perf-mode deep
```
Offline dry validation (no DB): `--source synthetic --profile expanded`.
Exit code `0` = success; outputs written atomically to
`V1/data/processed/current/` (+ `metadata/`, `validation/`).

## 2. Validate outputs
- `V1/data/processed/validation/_data_quality_checks.csv` → all PASS.
- `V1/data/processed/metadata/run_metadata.json` → `checks_passed=checks_total`,
  `idempotent=true`, expected `signal_rows` (168 on the E5B live sample).

## 3. Refresh Power BI
### First-time setup (once)
1. Open **Power BI Desktop**.
2. Import the semantic model from `V1/powerbi/tmdl/`:
   - Preferred: **Tabular Editor** → open the TMDL folder → save to a new model,
     or use *Get Data → more → TMDL* / Power BI project (PBIP) import; or
   - Recreate the connection by pointing the `DriftDataFolder` parameter to your
     local `V1/data/processed/current/` folder.
3. Set the **`DriftDataFolder`** parameter (Transform data → Edit parameters) to
   the absolute path of `V1/data/processed/current/` **on this machine** (end
   with a trailing `\`). This is the only path to change.
4. **Refresh** — the four tables load from CSV.
5. Create the **Calendar → signals[forecast_version]** relationship (the DAX
   calculated `Calendar` table materializes only now, in Desktop).
6. Build the report pages per `E6_page_specifications.md` and the sidebar per
   `E6_sidebar_navigation_spec.md`. Save as
   `V1/powerbi/AEGIS_Forecast_Drift_MVP.pbix`.

### Routine refresh (after a new Python run)
- Power BI Desktop → **Home → Refresh**. No model changes needed; stable file
  names in `current/` keep the connection valid.

## Path hygiene
- The single machine-specific value is the `DriftDataFolder` parameter. Avoid
  hard-coding paths inside individual queries.
- `V1/data/` (real governed outputs) stays **git-ignored**; never commit data.
- The `.pbix` may be committed (no embedded credentials) or kept local per policy.

## Do / Don't
- DO: aggregate, filter, visualize, navigate.
- DON'T: recompute drift scores, severity, thresholds, version pairing or events
  in DAX; connect Power BI to SQL; write back to any source.
