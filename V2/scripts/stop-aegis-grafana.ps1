<#
    stop-aegis-grafana.ps1  (E7D.12 — local shutdown)

    Safely stops the read-only CSV server (aegis-csv) ONLY.

    IMPORTANT — Grafana is intentionally NOT stopped by default. The local Grafana
    container may host OTHER dashboards unrelated to AEGIS Forecast Drift; stopping
    it could disrupt unrelated local work. Pass -IncludeGrafana to also stop Grafana
    (opt-in, explicit).

    This script NEVER:
      * runs `docker compose down` (which could remove containers) or `-v`;
      * deletes volumes, networks or images;
      * touches the DPAPI token, MCP, or any governed data.

    Usage:
      pwsh -File V2/scripts/stop-aegis-grafana.ps1                 # stops aegis-csv only
      pwsh -File V2/scripts/stop-aegis-grafana.ps1 -IncludeGrafana # also stops Grafana
#>
[CmdletBinding()]
param(
    [switch] $IncludeGrafana,
    [string] $GrafanaContainer = 'grafana'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Write-Info { param([string]$m) Write-Host "[stop-aegis] $m" }

# Stop aegis-csv (container stop only — no removal, volume and mounts preserved).
$csvExists = (docker ps -a --filter "name=^/aegis-csv$" --format '{{.Names}}') -eq 'aegis-csv'
if ($csvExists) {
    Write-Info 'Stopping aegis-csv (container stop only; no removal, data preserved)...'
    docker stop aegis-csv | Out-Null
    Write-Info 'aegis-csv stopped.'
} else {
    Write-Info 'aegis-csv not present — nothing to stop.'
}

if ($IncludeGrafana) {
    $grafRunning = (docker ps --filter "name=^/$GrafanaContainer$" --format '{{.Names}}') -eq $GrafanaContainer
    if ($grafRunning) {
        Write-Info "Stopping Grafana (explicit -IncludeGrafana). NOTE: this may affect unrelated local dashboards."
        docker stop $GrafanaContainer | Out-Null
        Write-Info 'Grafana stopped.'
    } else {
        Write-Info 'Grafana not running — nothing to stop.'
    }
} else {
    Write-Info 'Grafana left running (default). Use -IncludeGrafana to stop it explicitly.'
}
