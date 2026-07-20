# push-e7d9b-top-risk.ps1
# E7D.9B — Top Risk analytical content.
# Publishes ONLY the canonical Top Risk dashboard (uid aegis-forecast-drift-top-keys,
# title "AEGIS Forecast Drift — Top Risk") to the "AEGIS Forecast Drift" folder
# (uid afsjccp27s0e8d), overwriting the E7D.9A navigation shell in place.
# NO other dashboard is touched. NO query/datasource/CSV/nginx/Docker changes.
# Read-only governed V2 snapshot. UID preserved so the aegis-nav dropdown and the
# canonical URL /d/aegis-forecast-drift-top-keys keep working.
# The Grafana service-account token is DPAPI-decrypted in memory only and never printed.
$ErrorActionPreference = 'Stop'

$dashDir   = Join-Path $PSScriptRoot '..\grafana\dashboards'
$folderUid = 'afsjccp27s0e8d'
$base      = 'http://localhost:3000'
$file      = 'aegis-forecast-drift-top-keys.json'

# --- decrypt DPAPI token in memory ---
$tokPath = Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi'
$enc = Get-Content -LiteralPath $tokPath -Raw
$sec = ConvertTo-SecureString $enc
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
$hdr = @{ Authorization = "Bearer $plain" }

try {
  $path = Join-Path $dashDir $file
  $model = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  $model | Add-Member -NotePropertyName id -NotePropertyValue $null -Force
  $model | Add-Member -NotePropertyName version -NotePropertyValue 0 -Force
  $body = @{
    dashboard = $model
    folderUid = $folderUid
    overwrite = $true
    message   = 'E7D.9B Top Risk analytical content — governed forecast_drift_score rankings, concentration and risk details (UID preserved). No score/weight/CSV changes.'
  } | ConvertTo-Json -Depth 100
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  $resp = Invoke-RestMethod -Uri "$base/api/dashboards/db" -Headers $hdr -Method POST -ContentType 'application/json; charset=utf-8' -Body $bytes
  Write-Host ("PUBLISH: {0,-42} status={1} version={2} uid={3}" -f $file, $resp.status, $resp.version, $resp.uid)

  Write-Host ''
  Write-Host '--- LIVE audit ---'
  $live = Invoke-RestMethod -Uri "$base/api/dashboards/uid/aegis-forecast-drift-top-keys" -Headers $hdr -Method GET
  $d = $live.dashboard
  $ids = ($d.panels | ForEach-Object { $_.id }) -join ','
  Write-Host ("LIVE: title='{0}' tags={1} panels={2} ids={3}" -f $d.title, ($d.tags -join '|'), $d.panels.Count, $ids)
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  $sec.Dispose()
  $plain = $null
}
