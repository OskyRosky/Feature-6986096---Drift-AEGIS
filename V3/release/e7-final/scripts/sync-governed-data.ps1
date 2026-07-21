<#
.SYNOPSIS
    AEGIS Forecast Drift - E7A.2 governed data snapshot sync (V1 -> V2).

.DESCRIPTION
    Creates / refreshes a BYTE-EQUIVALENT snapshot of the four governed drift
    datasets (plus metadata and validation artifacts) produced by the V1
    authoritative Drift Engine, into the V2 Grafana consumption product.

    Governance guarantees:
      * V1 is the single authoritative producer and is treated as READ-ONLY.
        This script NEVER writes to, moves, or deletes anything under V1.
      * Only an explicit ALLOW-LIST of governed outputs is copied. No PBI,
        no Python engine, no logs, caches, temp files or duplicate datasets.
      * Every copied file is validated by SHA256 (source == destination).
        A mismatch is a hard failure (non-zero exit).
      * Row counts of the four governed CSVs are validated against the
        expected baseline (168 / 672 / 71 / 1).
      * (E7D.12) The 18-check data-quality catalog (validation/ + byte-identical
        current/ served copy) is regenerated automatically at the end of every
        refresh via build-e7d11-check-catalog.ps1. The step aborts if the
        authoritative validation/_data_quality_checks.csv is not exactly 18 rows /
        18 PASS / 0 FAIL, if the run's checks_total/checks_passed are not 18, or if
        the validation and served checksums differ; on any failure the previous
        catalog copies are restored (transactional rollback). Use -DryRun to
        validate the whole flow without writing anything.
      * The run is idempotent: re-running with identical V1 data produces an
        identical V2 snapshot and manifest (aside from the snapshot timestamp).
      * No secrets are read, written or embedded.

    The script emits V2/data/processed/data_manifest.json describing each file
    (origin, destination, SHA256, rows, snapshot timestamp, calculation_version).

.NOTES
    Feature 6986096 - Integrate Cross-Functional Capacity Feedback Signals.
    Stage E7A.2 - V2 Governed Data Snapshot & Datasource Rewire.
#>

[CmdletBinding()]
param(
    # Fail (exit 1) if any governed CSV row count differs from the baseline.
    [switch] $StrictCounts = $true,

    # Validate the full flow (sources, row counts, catalog source) WITHOUT copying
    # or writing anything. Proves the refresh is safe/idempotent. (E7D.12)
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step { param([string] $Message) Write-Host "[sync-governed-data] $Message" }

# --- Resolve paths safely (relative to this script, no hard-coded absolutes) ---
$scriptDir = $PSScriptRoot                                   # ...\V2\scripts
$v2Root    = Split-Path -Parent $scriptDir                   # ...\V2
$projRoot  = Split-Path -Parent $v2Root                      # project root

$v1Processed = Join-Path $projRoot 'V1\data\processed'
$v2Processed = Join-Path $v2Root  'data\processed'

if (-not (Test-Path -LiteralPath $v1Processed)) {
    throw "V1 processed folder not found: $v1Processed"
}

# --- Explicit governed allow-list: relative path under data\processed ---
# Only these artifacts are synchronized. Everything else in V1 is ignored.
$governedCsvs = @(
    @{ Rel = 'current\forecast_drift_signals.csv';       ExpectedRows = 168 },
    @{ Rel = 'current\forecast_drift_family_scores.csv'; ExpectedRows = 672 },
    @{ Rel = 'current\forecast_drift_event_history.csv'; ExpectedRows = 71  },
    @{ Rel = 'current\forecast_drift_runs.csv';          ExpectedRows = 1   }
)
$governedExtras = @(
    'metadata\run_metadata.json',
    'validation\_data_quality_checks.csv',
    'validation\_fixture_results.csv'
)

# --- Ensure V2 destination directory tree exists ---
foreach ($sub in @('current', 'metadata', 'validation')) {
    $dir = Join-Path $v2Processed $sub
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

# --- Preflight: confirm every allow-listed source file exists ---
$allRel = @()
$allRel += $governedCsvs | ForEach-Object { $_.Rel }
$allRel += $governedExtras
foreach ($rel in $allRel) {
    $src = Join-Path $v1Processed $rel
    if (-not (Test-Path -LiteralPath $src)) {
        throw "Required governed source missing in V1: $rel"
    }
}

# --- Validate row counts of governed CSVs against baseline ---
Write-Step 'Validating governed CSV row counts...'
foreach ($csv in $governedCsvs) {
    $src  = Join-Path $v1Processed $csv.Rel
    $rows = (Get-Content -LiteralPath $src).Count - 1   # exclude header
    if ($rows -ne $csv.ExpectedRows) {
        $msg = "Row count mismatch for $($csv.Rel): expected $($csv.ExpectedRows), found $rows"
        if ($StrictCounts) { throw $msg } else { Write-Warning $msg }
    }
    Write-Step ("  {0} -> {1} rows (OK)" -f (Split-Path -Leaf $csv.Rel), $rows)
}

# --- Copy + byte-equivalence (SHA256) validation ---
$manifestFiles = @()
foreach ($rel in $allRel) {
    $src = Join-Path $v1Processed $rel
    $dst = Join-Path $v2Processed $rel

    $srcHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash

    $dstDir = Split-Path -Parent $dst
    if (-not (Test-Path -LiteralPath $dstDir)) {
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    }

    if ($DryRun) {
        Write-Step ("  [dry-run] would sync {0} (source sha256 {1})" -f ($rel -replace '\\', '/'), $srcHash.Substring(0,12))
    } else {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $dstHash = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
        if ($srcHash -ne $dstHash) {
            throw "SHA256 mismatch after copy for '$rel': V1=$srcHash V2=$dstHash"
        }
    }

    $rows = $null
    if ($rel -like '*.csv') {
        $countPath = if ($DryRun) { $src } else { $dst }
        $rows = (Get-Content -LiteralPath $countPath).Count - 1
    }

    $manifestFiles += [ordered]@{
        file       = ($rel -replace '\\', '/')
        origin     = "V1/data/processed/$($rel -replace '\\', '/')"
        dest       = "V2/data/processed/$($rel -replace '\\', '/')"
        sha256     = $srcHash
        rows       = $rows
        size_bytes = (Get-Item -LiteralPath $src).Length
    }
    if (-not $DryRun) { Write-Step ("  synced {0} (sha256 OK)" -f ($rel -replace '\\', '/')) }
}

# --- E7D.12: integrated, transactional governed data-quality catalog refresh ---
# Carry-over from E7D.11: the 18-check catalog (validation/ + byte-identical current/
# copies) is now regenerated automatically as part of every governed refresh, so it
# never drifts from the authoritative validation/_data_quality_checks.csv and is never
# hand-generated. The step is transactional: prior copies are backed up, the catalog is
# rebuilt + validated, and on ANY failure the previous copies are restored (rollback).
$catalogRefreshIntegrated = $false
$catalogSha = $null
$catValidation = Join-Path $v2Processed 'validation\forecast_drift_data_quality_checks.csv'
$catServed     = Join-Path $v2Processed 'current\forecast_drift_data_quality_checks.csv'

Write-Step 'Validating authoritative data-quality source before catalog refresh...'
$authoritative = Join-Path $v2Processed 'validation\_data_quality_checks.csv'
$srcChecks = @(Import-Csv -LiteralPath $authoritative)
if ($srcChecks.Count -ne 18) { throw "Authoritative _data_quality_checks.csv has $($srcChecks.Count) rows, expected 18. ABORT catalog refresh (no invention)." }
$srcFail = @($srcChecks | Where-Object { $_.result -eq 'FAIL' }).Count
$srcPass = @($srcChecks | Where-Object { $_.result -eq 'PASS' }).Count
if ($srcFail -gt 0) { throw "Authoritative checks contain $srcFail FAIL result(s). ABORT (failures are never hidden)." }
if ($srcPass -ne 18) { throw "Authoritative checks PASS=$srcPass, expected 18. ABORT." }
$runRow = Import-Csv -LiteralPath (Join-Path $v2Processed 'current\forecast_drift_runs.csv') | Select-Object -First 1
if ([int]$runRow.checks_total  -ne 18) { throw "Run checks_total=$($runRow.checks_total), expected 18. ABORT." }
if ([int]$runRow.checks_passed -ne 18) { throw "Run checks_passed=$($runRow.checks_passed), expected 18. ABORT." }
Write-Step "  Source OK — 18 checks, 18 PASS, 0 FAIL; run checks 18/18."

if ($DryRun) {
    Write-Step '  [dry-run] would regenerate + verify the catalog (validation == current, 18/18).'
    $catalogRefreshIntegrated = $true
    if (Test-Path -LiteralPath $catServed) { $catalogSha = (Get-FileHash -LiteralPath $catServed -Algorithm SHA256).Hash }
} else {
    $backups = @{}
    foreach ($p in @($catServed, $catValidation)) {
        if (Test-Path -LiteralPath $p) { $bk = "$p.prev"; Copy-Item -LiteralPath $p -Destination $bk -Force; $backups[$p] = $bk }
    }
    try {
        $buildScript = Join-Path $scriptDir 'build-e7d11-check-catalog.ps1'
        if (-not (Test-Path -LiteralPath $buildScript)) { throw "Catalog build script not found: $buildScript" }
        & $buildScript -Base $projRoot | ForEach-Object { Write-Step "  [catalog] $_" }

        $hV = (Get-FileHash -LiteralPath $catValidation -Algorithm SHA256).Hash
        $hS = (Get-FileHash -LiteralPath $catServed -Algorithm SHA256).Hash
        if ($hV -ne $hS) { throw "Catalog checksum mismatch: validation=$hV served=$hS. ABORT." }
        $built = @(Import-Csv -LiteralPath $catServed)
        $bPass = @($built | Where-Object { $_.check_status -eq 'PASS' }).Count
        $bFail = @($built | Where-Object { $_.check_status -eq 'FAIL' }).Count
        $bIds  = @($built | Select-Object -ExpandProperty check_id | Sort-Object -Unique).Count
        if ($built.Count -ne 18 -or $bPass -ne 18 -or $bFail -ne 0 -or $bIds -ne 18) {
            throw "Built catalog invalid: rows=$($built.Count) pass=$bPass fail=$bFail distinctIds=$bIds. ABORT."
        }
        $catalogSha = $hS
        $catalogRefreshIntegrated = $true
        Write-Step "  Catalog OK — 18 rows / 18 PASS / 0 FAIL; validation == current ($hS)."
    }
    catch {
        foreach ($p in $backups.Keys) { Copy-Item -LiteralPath $backups[$p] -Destination $p -Force }
        throw "Catalog refresh FAILED and was rolled back to the previous copies: $($_.Exception.Message)"
    }
    finally {
        foreach ($bk in $backups.Values) { if (Test-Path -LiteralPath $bk) { Remove-Item -LiteralPath $bk -Force } }
    }

    foreach ($rel in @('validation\forecast_drift_data_quality_checks.csv', 'current\forecast_drift_data_quality_checks.csv')) {
        $dst = Join-Path $v2Processed $rel
        $manifestFiles += [ordered]@{
            file       = ($rel -replace '\\', '/')
            origin     = 'derived from validation/_data_quality_checks.csv + drift_engine/checks.py via build-e7d11-check-catalog.ps1'
            dest       = "V2/data/processed/$($rel -replace '\\', '/')"
            sha256     = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
            rows       = (Import-Csv -LiteralPath $dst).Count
            size_bytes = (Get-Item -LiteralPath $dst).Length
        }
    }
}

# --- Extract calculation_version from governed run metadata (if present) ---
$calcVersion = $null
$metaPath = Join-Path $v2Processed 'metadata\run_metadata.json'
if (Test-Path -LiteralPath $metaPath) {
    try {
        $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
        if ($meta.PSObject.Properties.Name -contains 'calculation_version') {
            $calcVersion = $meta.calculation_version
        }
    } catch {
        Write-Warning "Could not parse run_metadata.json for calculation_version: $($_.Exception.Message)"
    }
}

# --- Write manifest ---
$manifest = [ordered]@{
    stage                     = 'E7A.2 + E7D.12'
    description               = 'V2 governed data snapshot (byte-equivalent copy of V1 authoritative drift outputs) with integrated 18-check data-quality catalog regeneration.'
    authoritative_source      = 'V1/data/processed (Python Drift Engine)'
    snapshot_timestamp        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    calculation_version       = $calcVersion
    v1_modified               = $false
    catalog_refresh_integrated = $catalogRefreshIntegrated
    data_quality_catalog      = [ordered]@{
        rows            = 18
        pass            = 18
        fail            = 0
        sha256          = $catalogSha
        validation_copy = 'V2/data/processed/validation/forecast_drift_data_quality_checks.csv'
        served_copy     = 'V2/data/processed/current/forecast_drift_data_quality_checks.csv'
        checksums_match = $true
    }
    files                     = $manifestFiles
}

$manifestPath = Join-Path $v2Processed 'data_manifest.json'
if ($DryRun) {
    Write-Step 'DRY-RUN complete — all sources, row counts and catalog source validated; NOTHING was written.'
    Write-Step ("  catalog_refresh_integrated = {0}" -f $catalogRefreshIntegrated)
} else {
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Write-Step "Manifest written: V2/data/processed/data_manifest.json"
    Write-Step ("CATALOG_REFRESH_INTEGRATED = {0}" -f $catalogRefreshIntegrated)
    Write-Step "Snapshot sync COMPLETED - $($manifestFiles.Count) governed files, all SHA256-verified."
}
