# push-e7d7-events.ps1
# Publishes ONLY the AEGIS Forecast Drift — Events dashboard (E7D.7) to the
# "AEGIS Forecast Drift" folder (uid afsjccp27s0e8d). Read-only governed V2 snapshot.
# The Grafana service-account token is DPAPI-decrypted in memory only and never printed.
$ErrorActionPreference = 'Stop'

$dashPath = Join-Path $PSScriptRoot '..\grafana\dashboards\aegis-forecast-drift-events.json'
$folderUid = 'afsjccp27s0e8d'
$base = 'http://localhost:3000'

# --- validate + load model ---
$model = Get-Content -LiteralPath $dashPath -Raw | ConvertFrom-Json
$model | Add-Member -NotePropertyName id -NotePropertyValue $null -Force
$model | Add-Member -NotePropertyName version -NotePropertyValue 0 -Force
$panelCount = $model.panels.Count

# --- decrypt DPAPI token in memory ---
$tokPath = Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi'
$enc = Get-Content -LiteralPath $tokPath -Raw
$sec = ConvertTo-SecureString $enc
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
$hdr = @{ Authorization = "Bearer $plain" }

try {
  $body = @{
    dashboard = $model
    folderUid = $folderUid
    overwrite = $true
    message   = 'E7D.7 Events MVP — governed read-only event log (is_event=1, 71 events)'
  } | ConvertTo-Json -Depth 60
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  $resp = Invoke-RestMethod -Uri "$base/api/dashboards/db" -Headers $hdr -Method POST -ContentType 'application/json; charset=utf-8' -Body $bytes
  Write-Host ("PUBLISH: status={0} version={1} uid={2} panels(local)={3}" -f $resp.status, $resp.version, $resp.uid, $panelCount)

  $live = Invoke-RestMethod -Uri "$base/api/dashboards/uid/aegis-forecast-drift-events" -Headers $hdr -Method GET
  $d = $live.dashboard
  $lk = $d.links[0]
  Write-Host ("LIVE: title='{0}' panels={1} folder='{2}' keepTime={3} includeVars={4} time={5}..{6}" -f `
    $d.title, $d.panels.Count, $live.meta.folderTitle, $lk.keepTime, $lk.includeVars, $d.time.from, $d.time.to)
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  $sec.Dispose()
  $plain = $null
}
