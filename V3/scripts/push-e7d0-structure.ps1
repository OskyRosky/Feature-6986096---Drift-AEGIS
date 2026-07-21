# push-e7d0-structure.ps1
# E7D.0 - Publish the AEGIS Forecast Drift dashboard structure (Overview + 10 shells)
# into the governed Grafana folder via the HTTP API.
#
# SECURITY:
#   - The service-account token is DPAPI-decrypted ONLY in process memory, never
#     printed, logged, or written to disk. It is zeroed/removed in the finally block.
#   - The dashboard JSON files are secret-free and reference the datasource by UID.
#
# SAFETY:
#   - Verifies the target folder exists.
#   - Refuses to overwrite any dashboard whose UID lives OUTSIDE the AEGIS folder
#     (protects the pre-existing foreign dashboard, e.g. 'advs2xz').
#   - Idempotent: re-running updates the same UIDs in place (no duplicates).
#
# This script only CREATES/UPDATES dashboards inside the authorized folder. It does
# not touch datasources, nginx, Docker, CSVs, Python, Power BI, alerts, or the token.

[CmdletBinding()]
param(
    [string]$DashboardsDir = (Join-Path $PSScriptRoot '..\grafana\dashboards'),
    [string]$FolderUid     = 'afsjccp27s0e8d',
    [string]$GrafanaUrl    = 'http://localhost:3000',
    [string]$TokenPath     = (Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi'),
    [string]$Message       = 'E7D.0 Information Architecture & Shared Navigation (structure only)'
)

$ErrorActionPreference = 'Stop'
function Info([string]$m) { Write-Host "[push-e7d0] $m" }
function Die([string]$m)  { Write-Host "[push-e7d0] ERROR: $m" -ForegroundColor Red; exit 1 }

# Ordered list = product navigation order. Overview keeps the E7C UID.
$order = @(
    'aegis-forecast-drift-foundation',
    'aegis-forecast-drift-forecast',
    'aegis-forecast-drift-performance',
    'aegis-forecast-drift-shape',
    'aegis-forecast-drift-stability',
    'aegis-forecast-drift-volatility',
    'aegis-forecast-drift-events',
    'aegis-forecast-drift-timeline',
    'aegis-forecast-drift-top-keys',
    'aegis-forecast-drift-top-scenarios',
    'aegis-forecast-drift-settings'
)

if (-not (Test-Path -LiteralPath $TokenPath)) { Die "Encrypted token not found at $TokenPath." }
if (-not (Test-Path -LiteralPath $DashboardsDir)) { Die "Dashboards dir not found at $DashboardsDir." }

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

    # --- 1. Inventory existing dashboards (conflict guard) ---
    $existing = Invoke-RestMethod -Method Get -Uri "$GrafanaUrl/api/search?type=dash-db&limit=5000" -Headers $headers
    $byUid = @{}
    foreach ($d in $existing) { $byUid[$d.uid] = $d }
    $targetSet = @{}; $order | ForEach-Object { $targetSet[$_] = $true }
    $foreign = @($existing | Where-Object { -not $targetSet.ContainsKey($_.uid) })
    Info ("Existing dashboards: {0} total; {1} foreign (untouched)." -f $existing.Count, $foreign.Count)
    foreach ($f in $foreign) { Info ("  foreign: uid={0} title='{1}' folder='{2}'" -f $f.uid, $f.title, $f.folderTitle) }

    foreach ($uid in $order) {
        if ($byUid.ContainsKey($uid)) {
            $cur = $byUid[$uid]
            if ($cur.folderUid -and $cur.folderUid -ne $FolderUid) {
                Die "UID '$uid' already exists in a DIFFERENT folder ('$($cur.folderTitle)'). Aborting to avoid touching foreign content."
            }
        }
    }

    # --- 2. Publish each dashboard (create or update in place) ---
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($uid in $order) {
        $file = Join-Path $DashboardsDir "$uid.json"
        if (-not (Test-Path -LiteralPath $file)) { Die "Missing dashboard file: $file" }
        $model = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
        $payload = @{ dashboard = $model; folderUid = $FolderUid; overwrite = $true; message = $Message }
        $body = ($payload | ConvertTo-Json -Depth 100)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $resp = Invoke-RestMethod -Method Post -Uri "$GrafanaUrl/api/dashboards/db" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $bytes
        $results.Add([pscustomobject]@{ uid = $resp.uid; version = $resp.version; status = $resp.status; url = "$GrafanaUrl$($resp.url)" })
        Info ("published uid={0} v={1} status={2}" -f $resp.uid, $resp.version, $resp.status)
    }

    # --- 3. Verify each exists in the AEGIS folder ---
    Info "--- verification ---"
    foreach ($uid in $order) {
        $dash = Invoke-RestMethod -Method Get -Uri "$GrafanaUrl/api/dashboards/uid/$uid" -Headers $headers
        $inFolder = ($dash.meta.folderUid -eq $FolderUid)
        Info ("verify uid={0} title='{1}' folderUid={2} inFolder={3}" -f $dash.dashboard.uid, $dash.dashboard.title, $dash.meta.folderUid, $inFolder)
    }

    # --- 4. Datasource health (read-only, unchanged) ---
    try {
        $ds = Invoke-RestMethod -Method Get -Uri "$GrafanaUrl/api/datasources/uid/aegis-forecast-drift-csv" -Headers $headers
        Info ("datasource OK: name='{0}' type='{1}' uid={2}" -f $ds.name, $ds.type, $ds.uid)
    } catch { Info "datasource lookup skipped: $($_.Exception.Message)" }

    Info "--- URLs ---"
    $results | ForEach-Object { Write-Host ("  {0}  ->  {1}" -f $_.uid, $_.url) }
    Info "DONE."
}
finally {
    if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if ($secure) { $secure.Dispose() }
    $plain = $null; $headers = $null
    [System.GC]::Collect()
    Info "Token cleared from memory."
}
