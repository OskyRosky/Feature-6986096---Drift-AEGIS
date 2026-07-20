# push-e7d11-settings-data-quality.ps1
# E7D.11 — Settings & Data Quality analytical content.
# Publishes ONLY the canonical Settings dashboard (uid aegis-forecast-drift-settings,
# title "AEGIS Forecast Drift — Settings & Data Quality") to the "AEGIS Forecast Drift"
# folder (uid afsjccp27s0e8d), overwriting the E7D.0 structural shell in place.
# NO other dashboard is touched. NO score/weight/threshold/validation-logic change.
# The 18-check catalog is read via Infinity URL (http://aegis-csv/forecast_drift_data_quality_checks.csv),
# byte-identical to validation/forecast_drift_data_quality_checks.csv (SHA-256 9E76361F…551EE1).
# Read-only governed V2 snapshot. UID preserved so the aegis-nav dropdown and the
# canonical URL /d/aegis-forecast-drift-settings keep working.
# The Grafana service-account token is DPAPI-decrypted in memory only and never printed.
$ErrorActionPreference = 'Stop'

$dashDir   = Join-Path $PSScriptRoot '..\grafana\dashboards'
$folderUid = 'afsjccp27s0e8d'
$base      = 'http://localhost:3000'
$file      = 'aegis-forecast-drift-settings.json'

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
    message   = 'E7D.11 Settings & Data Quality analytical content — 18 governed data-quality checks (served catalog), weights, thresholds, computability, lineage & limitations (UID preserved). No score/weight/threshold/CSV changes.'
  } | ConvertTo-Json -Depth 100
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  $resp = Invoke-RestMethod -Uri "$base/api/dashboards/db" -Headers $hdr -Method POST -ContentType 'application/json; charset=utf-8' -Body $bytes
  Write-Host ("PUBLISH: {0,-44} status={1} version={2} uid={3}" -f $file, $resp.status, $resp.version, $resp.uid)

  Write-Host ''
  Write-Host '--- LIVE audit ---'
  $live = Invoke-RestMethod -Uri "$base/api/dashboards/uid/aegis-forecast-drift-settings" -Headers $hdr -Method GET
  $d = $live.dashboard
  $ids = ($d.panels | ForEach-Object { $_.id }) -join ','
  Write-Host ("LIVE: title='{0}' tags={1} panels={2} ids={3}" -f $d.title, ($d.tags -join '|'), $d.panels.Count, $ids)
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  $sec.Dispose()
  $plain = $null
}
