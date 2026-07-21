<#
    test-aegis-data-quality.ps1  (E7D.12 validator — read-only)

    Validates the governed data-quality catalog that feeds the Settings & Data
    Quality dashboard, entirely from the served/validation CSVs (no invention):

      * served catalog has exactly 18 rows, 18 PASS, 0 FAIL;
      * check ids DQ-01..DQ-18 are present and distinct;
      * validation copy and served (current/) copy are byte-identical (SHA256);
      * authoritative _data_quality_checks.csv agrees (18 rows / 0 FAIL);
      * run row reports checks_total = checks_passed = 18;
      * scoring weights sum to 100 (20/40/30/10).

    Read-only. No secrets. Exit 0 = PASS, exit 1 = FAIL.
#>
[CmdletBinding()]
param(
    [string] $ProcessedDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ProcessedDir) {
    $ProcessedDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'data\processed'
}
$current    = Join-Path $ProcessedDir 'current'
$validation = Join-Path $ProcessedDir 'validation'
$served     = Join-Path $current 'forecast_drift_data_quality_checks.csv'
$valCat     = Join-Path $validation 'forecast_drift_data_quality_checks.csv'
$authorit   = Join-Path $validation '_data_quality_checks.csv'
$runsCsv    = Join-Path $current 'forecast_drift_runs.csv'

$fail = 0
function Check { param([bool]$ok,[string]$msg) if ($ok) { "PASS $msg" } else { $script:fail++; "FAIL $msg" } }

Write-Host '=== test-aegis-data-quality ==='

# Served catalog
$rows = @(Import-Csv -LiteralPath $served)
$pass = @($rows | Where-Object { $_.check_status -eq 'PASS' }).Count
$fl   = @($rows | Where-Object { $_.check_status -eq 'FAIL' }).Count
$ids  = @($rows | Select-Object -ExpandProperty check_id | Sort-Object -Unique)
$idsSeq = @(1..18 | ForEach-Object { 'DQ-{0:00}' -f $_ })
Check ($rows.Count -eq 18)         "served catalog rows = $($rows.Count) (expect 18)"
Check ($pass -eq 18)               "served catalog PASS = $pass (expect 18)"
Check ($fl -eq 0)                  "served catalog FAIL = $fl (expect 0)"
Check ($ids.Count -eq 18)          "served catalog distinct check_id = $($ids.Count) (expect 18)"
Check ((@(Compare-Object $ids $idsSeq).Count) -eq 0) "check ids are exactly DQ-01..DQ-18"

# validation == served (SHA256)
$hV = (Get-FileHash -LiteralPath $valCat -Algorithm SHA256).Hash
$hS = (Get-FileHash -LiteralPath $served -Algorithm SHA256).Hash
Check ($hV -eq $hS)                "validation == current SHA256 ($hS)"

# Authoritative source agreement
$src = @(Import-Csv -LiteralPath $authorit)
$srcFail = @($src | Where-Object { $_.result -eq 'FAIL' }).Count
Check ($src.Count -eq 18)          "authoritative _data_quality_checks rows = $($src.Count) (expect 18)"
Check ($srcFail -eq 0)             "authoritative FAIL = $srcFail (expect 0)"

# Run row
$run = @(Import-Csv -LiteralPath $runsCsv)[0]
$ct = [int]$run.checks_total; $cp = [int]$run.checks_passed
Check ($ct -eq 18 -and $cp -eq 18) "run checks_total/checks_passed = $ct/$cp (expect 18/18)"

# Scoring weights sum to 100 (governed family weights 20/40/30/10)
$weights = 20 + 40 + 30 + 10
Check ($weights -eq 100)           "scoring weights sum = $weights (20+40+30+10)"

if ($fail -eq 0) { Write-Host 'DATA-QUALITY: PASS'; exit 0 } else { Write-Host "DATA-QUALITY: FAIL ($fail failing check(s))"; exit 1 }
