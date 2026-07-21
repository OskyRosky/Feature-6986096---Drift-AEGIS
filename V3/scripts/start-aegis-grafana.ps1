<#
    start-aegis-grafana.ps1  (E7D.12 — local bring-up)

    Safe, idempotent local startup for the AEGIS Forecast Drift V2 Grafana stack.
    Brings up the read-only CSV server (aegis-csv) via Docker Compose, ensures the
    pre-existing Grafana container is running and attached to the shared aegis-net
    network, and verifies the five governed CSV endpoints plus the Grafana UI.

    It NEVER:
      * prints, reads into output, or modifies the DPAPI service-account token;
      * registers or reconfigures MCP;
      * recreates or migrates the Grafana container or its volume;
      * deletes containers, volumes or networks;
      * changes ports, the aegis-net network, or any governed data.

    Grafana is started only if it already EXISTS and is stopped. If Grafana is not
    present at all, the script reports it and continues (aegis-csv is independent).

    Usage:  pwsh -File V2/scripts/start-aegis-grafana.ps1
#>
[CmdletBinding()]
param(
    [int] $HealthTimeoutSec = 60,
    [string] $GrafanaContainer = 'grafana',
    [string] $Network = 'aegis-net',
    [string] $GrafanaUrl = 'http://localhost:3000'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$m) Write-Host "[start-aegis] $m" }
function Write-Ok   { param([string]$m) Write-Host "[start-aegis] OK  - $m" -ForegroundColor Green }
function Write-Warn2{ param([string]$m) Write-Host "[start-aegis] WARN- $m" -ForegroundColor Yellow }

# --- Resolve paths relative to this script (handles the Unicode hyphen in the repo path) ---
$scriptDir = $PSScriptRoot
$v2Root    = Split-Path -Parent $scriptDir
$compose   = Join-Path $v2Root 'docker-compose.yml'
if (-not (Test-Path -LiteralPath $compose)) { throw "docker-compose.yml not found at: $compose" }

# --- Docker present? ---
try { docker version --format '{{.Server.Version}}' | Out-Null }
catch { throw "Docker does not appear to be running. Start Docker Desktop and retry." }

# --- 1) Bring up aegis-csv via Compose (does not touch Grafana) ---
Write-Info "Starting aegis-csv via Docker Compose ($compose)..."
Push-Location $v2Root
try {
    docker compose up -d aegis-csv | Out-Null
} finally { Pop-Location }

# --- 2) Ensure Grafana is running (start only if it exists and is stopped; never recreate) ---
$grafExists = (docker ps -a --filter "name=^/$GrafanaContainer$" --format '{{.Names}}') -eq $GrafanaContainer
if ($grafExists) {
    $grafRunning = (docker ps --filter "name=^/$GrafanaContainer$" --format '{{.Names}}') -eq $GrafanaContainer
    if (-not $grafRunning) {
        Write-Info "Grafana exists but is stopped - starting it..."
        docker start $GrafanaContainer | Out-Null
    } else {
        Write-Info "Grafana already running."
    }
} else {
    Write-Warn2 "Grafana container '$GrafanaContainer' not found - skipping (aegis-csv is independent)."
}

# --- 3/4/5) Ensure both containers share aegis-net; connect Grafana only if missing ---
$netMembers = @()
try { $netMembers = @((docker network inspect $Network --format '{{range .Containers}}{{.Name}} {{end}}') -split '\s+' | Where-Object { $_ }) } catch {}
if ($grafExists -and ($netMembers -notcontains $GrafanaContainer)) {
    Write-Info "Attaching Grafana to $Network (was missing)..."
    docker network connect $Network $GrafanaContainer | Out-Null
} elseif ($grafExists) {
    Write-Info "Grafana already attached to $Network."
}

# --- 6) Wait for aegis-csv health with timeout ---
Write-Info "Waiting for aegis-csv health (timeout ${HealthTimeoutSec}s)..."
$deadline = (Get-Date).AddSeconds($HealthTimeoutSec)
$csvHealthy = $false
while ((Get-Date) -lt $deadline) {
    $st = ''
    try { $st = docker inspect aegis-csv --format '{{.State.Health.Status}}' } catch {}
    if ($st -eq 'healthy') { $csvHealthy = $true; break }
    Start-Sleep -Seconds 2
}
if ($csvHealthy) { Write-Ok "aegis-csv healthy." } else { Write-Warn2 "aegis-csv not healthy within timeout (state='$st')." }

# --- 7) Check the five governed CSV endpoints from inside the Grafana container ---
$csvNames = 'signals','family_scores','event_history','runs','data_quality_checks'
$expected = @{ signals=169; family_scores=673; event_history=72; runs=2; data_quality_checks=19 }
$csvResults = @{}
if ($grafExists) {
    foreach ($n in $csvNames) {
        $lines = 0
        try { $lines = [int](docker exec $GrafanaContainer sh -c "wget -qO- http://aegis-csv/forecast_drift_$n.csv | wc -l") } catch {}
        $csvResults[$n] = $lines
    }
} else {
    Write-Warn2 "Grafana absent - checking endpoints from a throwaway alpine on $Network instead."
    foreach ($n in $csvNames) {
        $lines = 0
        try { $lines = [int](docker run --rm --network $Network alpine:3.20 sh -c "wget -qO- http://aegis-csv/forecast_drift_$n.csv | wc -l") } catch {}
        $csvResults[$n] = $lines
    }
}

# --- 8) Check Grafana UI on localhost:3000 ---
$grafHttp = 0
try { $grafHttp = [int](Invoke-WebRequest -Uri "$GrafanaUrl/api/health" -UseBasicParsing -TimeoutSec 8).StatusCode } catch {}

# --- 9) Summary ---
Write-Host ''
Write-Host '================ AEGIS Forecast Drift — local status ================'
Write-Host ("  grafana        : {0}" -f $(if ($grafExists) { (docker inspect grafana --format '{{.State.Status}}') } else { 'not present' }))
Write-Host ("  aegis-csv      : {0} (health: {1})" -f (docker inspect aegis-csv --format '{{.State.Status}}'), (docker inspect aegis-csv --format '{{.State.Health.Status}}'))
Write-Host ("  network        : {0}" -f $Network)
Write-Host   '  CSV endpoints  :'
foreach ($n in $csvNames) {
    $got = $csvResults[$n]; $exp = $expected[$n]
    $mark = if ($got -eq $exp) { 'OK ' } else { 'ERR' }
    Write-Host ("     [{0}] forecast_drift_{1}.csv  lines={2} (expected {3})" -f $mark, $n, $got, $exp)
}
Write-Host ("  Grafana HTTP   : {0} ({1})" -f $grafHttp, $(if ($grafHttp -eq 200) { 'OK' } else { 'not reachable' }))
Write-Host   '  Dashboards     : http://localhost:3000/dashboards?tag=aegis-nav'
Write-Host   '  Overview       : http://localhost:3000/d/aegis-forecast-drift-foundation'
Write-Host '===================================================================='

$allCsvOk = @($csvNames | Where-Object { $csvResults[$_] -ne $expected[$_] }).Count -eq 0
if ($csvHealthy -and $allCsvOk -and $grafHttp -eq 200) {
    Write-Ok "AEGIS stack up: aegis-csv healthy, 5 endpoints OK, Grafana reachable."
    exit 0
} else {
    Write-Warn2 "Bring-up completed with warnings (see summary above)."
    exit 1
}
