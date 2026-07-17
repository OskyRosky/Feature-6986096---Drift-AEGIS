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
    [switch] $StrictCounts = $true
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
    Copy-Item -LiteralPath $src -Destination $dst -Force

    $dstHash = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
    if ($srcHash -ne $dstHash) {
        throw "SHA256 mismatch after copy for '$rel': V1=$srcHash V2=$dstHash"
    }

    $rows = $null
    if ($rel -like '*.csv') { $rows = (Get-Content -LiteralPath $dst).Count - 1 }

    $manifestFiles += [ordered]@{
        file       = ($rel -replace '\\', '/')
        origin     = "V1/data/processed/$($rel -replace '\\', '/')"
        dest       = "V2/data/processed/$($rel -replace '\\', '/')"
        sha256     = $dstHash
        rows       = $rows
        size_bytes = (Get-Item -LiteralPath $dst).Length
    }
    Write-Step ("  synced {0} (sha256 OK)" -f ($rel -replace '\\', '/'))
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
    stage                = 'E7A.2'
    description          = 'V2 governed data snapshot (byte-equivalent copy of V1 authoritative drift outputs).'
    authoritative_source = 'V1/data/processed (Python Drift Engine)'
    snapshot_timestamp   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    calculation_version  = $calcVersion
    v1_modified          = $false
    files                = $manifestFiles
}

$manifestPath = Join-Path $v2Processed 'data_manifest.json'
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Step "Manifest written: V2/data/processed/data_manifest.json"
Write-Step "Snapshot sync COMPLETED - $($manifestFiles.Count) governed files, all SHA256-verified."
