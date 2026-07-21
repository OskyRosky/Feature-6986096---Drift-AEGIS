# push-e7d2-forecast.ps1
# E7D.2 - Publish ONLY the AEGIS Forecast Drift "Forecast" dashboard
# (uid aegis-forecast-drift-forecast) into the governed Grafana folder via HTTP API.
#
# SECURITY:
#   - The service-account token is DPAPI-decrypted ONLY in process memory, never
#     printed, logged, or written to disk. It is zeroed/removed in the finally block.
#   - The dashboard JSON is secret-free and references the datasource by UID.
#
# SAFETY:
#   - Verifies the target folder exists.
#   - Refuses to publish if the Forecast UID currently lives OUTSIDE the AEGIS folder.
#   - Idempotent: updates the same UID in place (no duplicate, no new dashboard).
#   - Touches ONLY the Forecast dashboard. Does not modify the Overview, the other
#     9 section shells, datasources, nginx, Docker, CSVs, Python, Power BI, alerts,
#     or the token.

[CmdletBinding()]
param(
    [string]$DashboardsDir = (Join-Path $PSScriptRoot '..\grafana\dashboards'),
    [string]$Uid           = 'aegis-forecast-drift-forecast',
    [string]$FolderUid     = 'afsjccp27s0e8d',
    [string]$GrafanaUrl    = 'http://localhost:3000',
    [string]$TokenPath     = (Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi'),
    [string]$Message       = 'E7D.2 Forecast MVP — analytical dashboard (overall score, family, status, trend, key risk, drift heatmap, run, DQ)'
)

$ErrorActionPreference = 'Stop'
function Info([string]$m) { Write-Host "[push-e7d2] $m" }
function Die([string]$m)  { Write-Host "[push-e7d2] ERROR: $m" -ForegroundColor Red; exit 1 }

if (-not (Test-Path -LiteralPath $TokenPath)) { Die "Encrypted token not found at $TokenPath." }
$file = Join-Path $DashboardsDir "$Uid.json"
if (-not (Test-Path -LiteralPath $file)) { Die "Forecast dashboard file not found: $file" }

$bstr = [IntPtr]::Zero
$secure = $null
try {
    $cipher = Get-Content -LiteralPath $TokenPath -Raw
    $secure = ConvertTo-SecureString -String $cipher   # DPAPI (CurrentUser)
    $bstr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $plain  = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    $headers = @{ Authorization = "Bearer $plain" }

    # --- 0. Confirm target folder exists ---
    $folder = Invoke-RestMethod -Method Get -Uri "$GrafanaUrl/api/folders/$FolderUid" -Headers $headers
    Info ("Folder OK: '{0}' (uid={1})" -f $folder.title, $folder.uid)

    # --- 1. Conflict guard: Forecast UID must not live in a foreign folder ---
    $existing = Invoke-RestMethod -Method Get -Uri "$GrafanaUrl/api/search?type=dash-db&limit=5000" -Headers $headers
    $cur = $existing | Where-Object { $_.uid -eq $Uid } | Select-Object -First 1
    if ($cur -and $cur.folderUid -and $cur.folderUid -ne $FolderUid) {
        Die "UID '$Uid' already exists in a DIFFERENT folder ('$($cur.folderTitle)'). Aborting."
    }

    # --- 2. Publish (update in place) ---
    $model = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
    $payload = @{ dashboard = $model; folderUid = $FolderUid; overwrite = $true; message = $Message }
    $body  = ($payload | ConvertTo-Json -Depth 100)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $resp  = Invoke-RestMethod -Method Post -Uri "$GrafanaUrl/api/dashboards/db" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $bytes
    Info ("published uid={0} v={1} status={2}" -f $resp.uid, $resp.version, $resp.status)

    # --- 3. Verify it exists in the AEGIS folder ---
    $dash = Invoke-RestMethod -Method Get -Uri "$GrafanaUrl/api/dashboards/uid/$Uid" -Headers $headers
    $inFolder = ($dash.meta.folderUid -eq $FolderUid)
    Info ("verify uid={0} title='{1}' folderUid={2} inFolder={3} panels={4}" -f `
        $dash.dashboard.uid, $dash.dashboard.title, $dash.meta.folderUid, $inFolder, $dash.dashboard.panels.Count)
    Write-Host ("  URL  ->  {0}/d/{1}" -f $GrafanaUrl, $Uid)
    Info "DONE."
}
finally {
    if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if ($secure) { $secure.Dispose() }
    $plain = $null; $headers = $null
    [System.GC]::Collect()
    Info "Token cleared from memory."
}
