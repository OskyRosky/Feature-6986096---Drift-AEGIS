<#
    test-aegis-navigation.ps1  (E7D.12 validator — read-only)

    Validates the navigation contract by inspecting the dashboard JSON on disk
    (source of truth, fully reproducible, no Grafana token required):

      * Exactly 10 dashboards are tagged 'aegis-nav' (the active navigation set).
      * 'Top Scenarios' is present on disk but NOT tagged 'aegis-nav' (retired,
        preserved for rollback only).
      * Every nav dashboard carries the native dropdown link:
          asDropdown=true, type='dashboards', tags contains 'aegis-nav',
          includeVars=true, keepTime=false, and NO hardcoded url.
      * No dashboard references a legacy/unknown datasource UID
        (only 'aegis-forecast-drift-csv' plus each dashboard's own uid are allowed).

    Read-only. No secrets. Exit 0 = PASS, exit 1 = FAIL.
#>
[CmdletBinding()]
param(
    [string] $DashboardDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $DashboardDir) {
    $DashboardDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'grafana\dashboards'
}
if (-not (Test-Path -LiteralPath $DashboardDir)) { throw "Dashboard dir not found: $DashboardDir" }

$navExpected      = 10
$dsUidAllowed     = 'aegis-forecast-drift-csv'
$scenariosUid     = 'aegis-forecast-drift-top-scenarios'
$fail = 0
$navCount = 0

Write-Host '=== test-aegis-navigation ==='
$files = Get-ChildItem -LiteralPath $DashboardDir -Filter *.json | Sort-Object Name
foreach ($f in $files) {
    $j = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
    $tags = @(); if ($j.PSObject.Properties.Name -contains 'tags' -and $j.tags) { $tags = @($j.tags) }
    $isNav = $tags -contains 'aegis-nav'
    $navLink = $null
    if ($j.PSObject.Properties.Name -contains 'links' -and $j.links) {
        $navLink = $j.links | Where-Object { $_.type -eq 'dashboards' -and (@($_.tags) -contains 'aegis-nav') } | Select-Object -First 1
    }

    if ($j.uid -eq $scenariosUid) {
        # Retired scenario: must exist, must NOT be in nav.
        if ($isNav) { $fail++; 'FAIL top-scenarios is tagged aegis-nav (must be retired from nav)' }
        else        { 'PASS top-scenarios present, correctly NOT in nav (rollback-only)' }
        continue
    }

    if ($isNav) { $navCount++ }
    $problems = @()
    if (-not $isNav)                    { $problems += 'missing aegis-nav tag' }
    if (-not $navLink)                  { $problems += 'missing native aegis-nav dropdown link' }
    else {
        if (-not $navLink.asDropdown)   { $problems += 'asDropdown!=true' }
        if (-not $navLink.includeVars)  { $problems += 'includeVars!=true' }
        if ($navLink.keepTime)          { $problems += 'keepTime!=false' }
        if ($navLink.url)               { $problems += 'hardcoded url present' }
    }
    # Datasource UID scan
    $badDs = (Select-String -LiteralPath $f.FullName -Pattern '"uid"\s*:\s*"([^"]+)"' -AllMatches).Matches |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique |
        Where-Object { $_ -ne $dsUidAllowed -and $_ -ne $j.uid }
    if ($badDs) { $problems += ("unexpected uid ref: {0}" -f ($badDs -join ',')) }

    if ($problems.Count -gt 0) { $fail++; 'FAIL {0}: {1}' -f $f.Name, ($problems -join '; ') }
    else                       { 'PASS {0}' -f $f.Name }
}

if ($navCount -ne $navExpected) {
    $fail++
    'FAIL aegis-nav dashboard count = {0}, expected {1}' -f $navCount, $navExpected
} else {
    'PASS aegis-nav dashboard count = {0}' -f $navCount
}

if ($fail -eq 0) { Write-Host 'NAVIGATION: PASS'; exit 0 } else { Write-Host "NAVIGATION: FAIL ($fail failing check(s))"; exit 1 }
