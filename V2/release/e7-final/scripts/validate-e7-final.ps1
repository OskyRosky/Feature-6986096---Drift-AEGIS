<#
    validate-e7-final.ps1  (E7D.12 — final validation orchestrator, read-only)

    Runs the three focused validators (endpoints, navigation, data-quality) plus
    a dashboard-inventory / manifest integrity check, and emits a single verdict:

        E7_FINAL_VALIDATION_PASS   (exit 0)   — all checks green
        E7_FINAL_VALIDATION_FAIL   (exit 1)   — one or more checks failed

    Fully read-only. No secrets are read or printed. Nothing is written or changed.
    Intended to be re-runnable at any time to confirm deployment READINESS
    (readiness only — this does NOT perform any deployment).
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir    = $PSScriptRoot
$v2Root       = Split-Path -Parent $scriptDir
$dashboardDir = Join-Path $v2Root 'grafana\dashboards'
$processed    = Join-Path $v2Root 'data\processed'
$manifest     = Join-Path $processed 'data_manifest.json'

$results = [ordered]@{}

function Run-Validator {
    param([string]$Name,[string]$Path,[hashtable]$SplatArgs)
    Write-Host ''
    Write-Host "----- $Name -----"
    & $Path @SplatArgs
    $code = $LASTEXITCODE
    $script:results[$Name] = ($code -eq 0)
    return ($code -eq 0)
}

# --- 1) Endpoints ---
Run-Validator 'endpoints'  (Join-Path $scriptDir 'test-aegis-endpoints.ps1')     @{} | Out-Null
# --- 2) Navigation ---
Run-Validator 'navigation' (Join-Path $scriptDir 'test-aegis-navigation.ps1')    @{ DashboardDir = $dashboardDir } | Out-Null
# --- 3) Data quality ---
Run-Validator 'data-quality' (Join-Path $scriptDir 'test-aegis-data-quality.ps1') @{ ProcessedDir = $processed } | Out-Null

# --- 4) Inventory + manifest integrity ---
Write-Host ''
Write-Host '----- inventory -----'
$invFail = 0
function Inv { param([bool]$ok,[string]$msg) if ($ok) { "PASS $msg" } else { $script:invFail++; "FAIL $msg" } }

$jsons = @(Get-ChildItem -LiteralPath $dashboardDir -Filter *.json)
$uids  = @($jsons | ForEach-Object { (Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json).uid })
$dupUid = @($uids | Group-Object | Where-Object { $_.Count -gt 1 })
Inv ($jsons.Count -eq 11)  "dashboard JSON files = $($jsons.Count) (10 active + 1 retired = 11)"
Inv ($dupUid.Count -eq 0)  "dashboard uids are unique"

# No placeholder / shell text in the 10 active dashboards
$activeJsons = $jsons | Where-Object { $_.Name -ne 'aegis-forecast-drift-top-scenarios.json' }
$placeholders = @($activeJsons | Where-Object {
    (Select-String -LiteralPath $_.FullName -Pattern 'TODO|PLACEHOLDER|FIXME|Panel Title|lorem ipsum' -SimpleMatch:$false -Quiet)
})
Inv ($placeholders.Count -eq 0) "no placeholder/shell text in active dashboards"

# Manifest catalog integration
if (Test-Path -LiteralPath $manifest) {
    $mf = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    $flag = $false
    if ($mf.PSObject.Properties.Name -contains 'catalog_refresh_integrated') { $flag = [bool]$mf.catalog_refresh_integrated }
    Inv $flag "manifest catalog_refresh_integrated = $flag"
} else {
    Inv $false "data_manifest.json present"
}
$results['inventory'] = ($invFail -eq 0)

# --- Verdict ---
Write-Host ''
Write-Host '================ E7 FINAL VALIDATION SUMMARY ================'
$allPass = $true
foreach ($k in $results.Keys) {
    $v = $results[$k]
    if (-not $v) { $allPass = $false }
    '  {0,-14} : {1}' -f $k, $(if ($v) { 'PASS' } else { 'FAIL' })
}
Write-Host '============================================================'
if ($allPass) {
    Write-Host 'E7_FINAL_VALIDATION_PASS' -ForegroundColor Green
    exit 0
} else {
    Write-Host 'E7_FINAL_VALIDATION_FAIL' -ForegroundColor Red
    exit 1
}
