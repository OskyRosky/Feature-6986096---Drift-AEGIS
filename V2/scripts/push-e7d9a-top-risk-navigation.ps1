# push-e7d9a-top-risk-navigation.ps1
# E7D.9A — Top Risk Navigation Consolidation.
# Publishes ONLY the navigation-affected dashboards to the "AEGIS Forecast Drift"
# folder (uid afsjccp27s0e8d): the 10 nav dashboards whose nav panel now points to a
# single "Top Risk" link, the canonical Top Risk shell (reused Top Forecast Keys UID),
# and the retired Top Scenarios shell (removed from the aegis-nav dropdown, preserved).
# NO analytical content, NO query/datasource/CSV changes. Read-only governed V2 snapshot.
# The Grafana service-account token is DPAPI-decrypted in memory only and never printed.
$ErrorActionPreference = 'Stop'

$dashDir   = Join-Path $PSScriptRoot '..\grafana\dashboards'
$folderUid = 'afsjccp27s0e8d'
$base      = 'http://localhost:3000'

# Dashboards touched by E7D.9A navigation consolidation (all 11 active product dashboards).
$files = @(
  'aegis-forecast-drift-foundation.json',
  'aegis-forecast-drift-forecast.json',
  'aegis-forecast-drift-performance.json',
  'aegis-forecast-drift-shape.json',
  'aegis-forecast-drift-stability.json',
  'aegis-forecast-drift-volatility.json',
  'aegis-forecast-drift-events.json',
  'aegis-forecast-drift-timeline.json',
  'aegis-forecast-drift-top-keys.json',        # canonical -> Top Risk (UID preserved)
  'aegis-forecast-drift-top-scenarios.json',   # retired from nav, preserved for rollback
  'aegis-forecast-drift-settings.json'
)

# --- decrypt DPAPI token in memory ---
$tokPath = Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi'
$enc = Get-Content -LiteralPath $tokPath -Raw
$sec = ConvertTo-SecureString $enc
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
$hdr = @{ Authorization = "Bearer $plain" }

try {
  foreach ($f in $files) {
    $path = Join-Path $dashDir $f
    $model = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $model | Add-Member -NotePropertyName id -NotePropertyValue $null -Force
    $model | Add-Member -NotePropertyName version -NotePropertyValue 0 -Force
    $body = @{
      dashboard = $model
      folderUid = $folderUid
      overwrite = $true
      message   = 'E7D.9A Top Risk navigation consolidation — single Top Risk link (canonical Top Forecast Keys UID); Top Scenarios retired from nav (preserved). No analytical content.'
    } | ConvertTo-Json -Depth 60
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $resp = Invoke-RestMethod -Uri "$base/api/dashboards/db" -Headers $hdr -Method POST -ContentType 'application/json; charset=utf-8' -Body $bytes
    Write-Host ("PUBLISH: {0,-42} status={1} version={2} uid={3}" -f $f, $resp.status, $resp.version, $resp.uid)
  }

  Write-Host ''
  Write-Host '--- LIVE nav audit (aegis-nav dropdown membership + Top Risk title) ---'
  foreach ($f in $files) {
    $uid = ($f -replace '\.json$','')
    $live = Invoke-RestMethod -Uri "$base/api/dashboards/uid/$uid" -Headers $hdr -Method GET
    $d = $live.dashboard
    $nav = ($d.panels | Where-Object { $_.id -eq 1 }).options.content
    $hasNavTag = [bool]($d.tags -contains 'aegis-nav')
    Write-Host ("LIVE: {0,-38} title='{1}' aegis-nav={2} navHasTopRisk={3} navHasTopScenarios={4}" -f `
      $uid, $d.title, $hasNavTag, [bool]($nav -match 'Top Risk'), [bool]($nav -match 'Top Scenarios'))
  }
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  $sec.Dispose()
  $plain = $null
}
