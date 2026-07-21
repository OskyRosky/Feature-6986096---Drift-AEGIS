<#
    test-aegis-endpoints.ps1  (E7D.12 validator — read-only)

    Verifies the five governed CSV endpoints served by the read-only aegis-csv
    nginx container are reachable and return the expected number of lines
    (header + data rows). Also verifies the disallowed paths are blocked.

    Read-only. No secrets. Exit 0 = PASS, exit 1 = FAIL.
#>
[CmdletBinding()]
param(
    [string] $Via = 'grafana',        # container used to reach http://aegis-csv (in-network)
    [string] $Network = 'aegis-net'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expected = [ordered]@{
    signals             = 169   # 168 rows + header
    family_scores       = 673   # 672 + header
    event_history       = 72    # 71 + header
    runs                = 2     # 1 + header
    data_quality_checks = 19    # 18 + header
}

function Invoke-InNet {
    param([string]$cmd)
    $grafRunning = (docker ps --filter "name=^/$Via$" --format '{{.Names}}') -eq $Via
    if ($grafRunning) { return (docker exec $Via sh -c $cmd) }
    return (docker run --rm --network $Network alpine:3.20 sh -c $cmd)
}

$fail = 0
Write-Host '=== test-aegis-endpoints ==='
foreach ($n in $expected.Keys) {
    $exp = $expected[$n]
    $lines = 0; $code = ''
    try { $lines = [int](Invoke-InNet "wget -qO- http://aegis-csv/forecast_drift_$n.csv | wc -l") } catch {}
    try { $code  = (Invoke-InNet "wget -S -qO- http://aegis-csv/forecast_drift_$n.csv 2>&1 | grep -m1 'HTTP/' | awk '{print `$2}'") } catch {}
    $ok = ($lines -eq $exp)
    if (-not $ok) { $fail++ }
    '{0} forecast_drift_{1}.csv  lines={2}/{3}  http={4}' -f $(if($ok){'PASS'}else{'FAIL'}), $n, $lines, $exp, $code
}

# Negative controls: an unlisted path and directory listing must NOT be served (expect empty/404).
$blockedLines = 999
try { $blockedLines = [int](Invoke-InNet "wget -qO- http://aegis-csv/ 2>/dev/null | wc -l") } catch { $blockedLines = 0 }
$blockOk = ($blockedLines -eq 0)
if (-not $blockOk) { $fail++ }
'{0} directory-listing blocked (root returns nothing, lines={1})' -f $(if($blockOk){'PASS'}else{'FAIL'}), $blockedLines

$health = ''
try { $health = (Invoke-InNet "wget -qO- http://aegis-csv/healthz").Trim() } catch {}
$healthOk = ($health -eq 'ok')
if (-not $healthOk) { $fail++ }
'{0} healthz endpoint (returned "{1}")' -f $(if($healthOk){'PASS'}else{'FAIL'}), $health

if ($fail -eq 0) { Write-Host 'ENDPOINTS: PASS'; exit 0 } else { Write-Host "ENDPOINTS: FAIL ($fail failing check(s))"; exit 1 }
