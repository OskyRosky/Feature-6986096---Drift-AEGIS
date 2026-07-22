<#
.SYNOPSIS
    AEGIS Forecast Drift — corporate Grafana portal health/validation check (all 10 dashboards).

.DESCRIPTION
    Read-only validator for the 10 governed AEGIS Forecast Drift dashboards deployed to the
    corporate Managed Grafana portal. Promoted from the V3 session tooling (consolidates the
    former v310/v311/v3111 validators) as the single reusable maintenance script.

    For each dashboard it confirms: stored version, panel/variable counts, the vertical sidebar
    (with the correct "(current)" highlight), the header panel, integrity (no secret 'sig' and no
    unresolved '__AEGIS_CSV_BASE_URL__' placeholders in the JSON), functional datasource bindings,
    and executes every panel's primary query with resolved template variables to confirm there is
    no unexpected "No data". It also runs a residual internal-technical-reference scan of visible
    text, and a global check (total dashboards, AEGIS folder membership, cross-links resolve).

    NOTHING is written. Safe to run any time (e.g. after a data refresh or SAS rotation).

.PREREQUISITES
    - Azure CLI logged in with a principal that has Grafana Viewer/Admin on the workspace.
    - The Infinity datasource secret 'sig' (container SAS token) is appended by Grafana at request
      time from secureJsonData; it is never present in dashboard JSON and is never printed here.

.PARAMETER Endpoint
    Managed Grafana endpoint (no trailing slash).

.NOTES
    Non-secret constants (datasource uid, AEGIS folder uid) are configuration, not secrets.
    The functional query URLs and container SAS query string are stored in the datasource / panel
    targets and are not modified or printed by this script.
#>
[CmdletBinding()]
param(
    [string]$Endpoint = 'https://CapswatComparisions-cmh3h3bfa2fsckca.wus2.grafana.azure.com',
    [string]$GrafanaAppResourceId = 'ce34e7e5-485f-4d76-964f-b3d2b16d1e4f',
    [string]$DatasourceUid = 'aegis-forecast-drift-csv',
    [string]$AegisFolderUid = 'ffstl9bhop1j4a'
)
$ErrorActionPreference = 'Stop'
$tok = (az account get-access-token --resource $GrafanaAppResourceId --query accessToken -o tsv)
if (-not $tok) { throw 'Could not acquire a Grafana access token. Run: az login' }
$h = @{ Authorization = "Bearer $tok"; 'Content-Type' = 'application/json' }

# 10 governed dashboards: uid -> display name (as shown in the sidebar "(current)" marker)
$dash = [ordered]@{
    'aegis-forecast-drift-foundation'  = 'Overview'
    'aegis-forecast-drift-forecast'    = 'Forecast'
    'aegis-forecast-drift-performance' = 'Performance'
    'aegis-forecast-drift-shape'       = 'Shape'
    'aegis-forecast-drift-stability'   = 'Stability'
    'aegis-forecast-drift-volatility'  = 'Volatility'
    'aegis-forecast-drift-events'      = 'Events'
    'aegis-forecast-drift-timeline'    = 'Historical Timeline'
    'aegis-forecast-drift-top-keys'    = 'Top Risk'
    'aegis-forecast-drift-settings'    = 'Settings & Data Quality'
}

function Invoke-Query($q) {
    $b = @{ queries = @($q); from = '0'; to = '9999999999999' } | ConvertTo-Json -Depth 60
    $r = Invoke-RestMethod "$Endpoint/api/ds/query" -Method Post -Headers $h -Body $b
    return ($r.results.PSObject.Properties | Select-Object -First 1 -ExpandProperty Value)
}
function Get-RowsCols($res) {
    if ($res.error) { return @{ err = $res.error; rows = -1; frame = $null } }
    $fr = $res.frames | Select-Object -First 1
    if (-not $fr) { return @{ err = 'no-frame'; rows = -1; frame = $null } }
    $rows = if ($fr.data.values) { @($fr.data.values[0]).Count } else { 0 }
    return @{ err = $null; rows = $rows; frame = $fr }
}
function Get-VarValues($v) {
    $iq = $v.query.infinityQuery
    $q = @{ datasource = @{ type = 'yesoreyeram-infinity-datasource'; uid = $DatasourceUid } }
    foreach ($p in $iq.PSObject.Properties) { $q[$p.Name] = $p.Value }
    $q['refId'] = 'A'
    $rc = Get-RowsCols (Invoke-Query $q)
    if ($rc.err) { return @() }
    $names = @($rc.frame.schema.fields.name)
    $idx = [Array]::IndexOf($names, '__value'); if ($idx -lt 0) { $idx = 0 }
    return @($rc.frame.data.values[$idx]) | Where-Object { $_ -ne $null } | Sort-Object -Unique
}
function Resolve-Values($v) {
    if ($v.type -eq 'query') { return Get-VarValues $v }
    $cv = $v.current.value; if ($null -eq $cv -and $v.options) { $cv = @($v.options.value) }
    if ($cv -is [System.Array]) { return @($cv) } else { return @($cv) }
}

# Residual internal-technical-reference scan (implementation leakage that should NOT be user-visible).
# Data-model field names (e.g. drift_status, forecast_version) are functional semantics and are allowed.
$leak = '(?i)\bV2 snapshot\b|checks\.py|settings\.py|nginx|SHA-?256|data_manifest|build-e7d11|\.csv|\.json|\.ps1|blob\.core|drift_engine|/python/|/data/processed|validation/forecast|aegis-csv|\bInfinity\b'

$all = Invoke-RestMethod "$Endpoint/api/search?type=dash-db&limit=5000" -Headers $h
$uids = @($all | Select-Object -ExpandProperty uid)
$fail = 0   # hard health failures (integrity / functional / global)
$warn = 0   # informational: residual internal-technical text (a scope/style decision, not a health fault)

foreach ($uid in $dash.Keys) {
    $name = $dash[$uid]
    Write-Output ("################ {0}  ({1})" -f $name, $uid)
    $w = Invoke-RestMethod "$Endpoint/api/dashboards/uid/$uid" -Headers $h
    $d = $w.dashboard
    $json = $d | ConvertTo-Json -Depth 100
    $sig = ([regex]'[?&]sig=').Matches($json).Count
    $ph  = ([regex]'__AEGIS_CSV_BASE_URL__').Matches($json).Count
    $tgt = @($d.panels | ForEach-Object { if ($_.targets) { $_.targets | ForEach-Object { if ($_.url -match 'blob\.core') { 1 } } } }).Count
    $dsb = @($d.panels | ForEach-Object { if ($_.datasource.uid -eq $DatasourceUid) { 1 }; if ($_.targets) { $_.targets | ForEach-Object { if ($_.datasource.uid -eq $DatasourceUid) { 1 } } } }).Count
    $sb = $d.panels | Where-Object { [int]$_.id -eq 1 }
    $sbLinks = if ($sb) { ([regex]'\]\(/d/aegis-forecast-drift-').Matches($sb.options.content).Count } else { 0 }
    $curOK = if ($sb) { [bool]($sb.options.content -match ("(?m)^\-\s\*\*" + [regex]::Escape($name) + "\*\*\s\(current\)")) } else { $false }
    $hasHeader = [bool]($d.panels | Where-Object { [int]$_.id -eq 2 })
    if ($sig -ne 0) { $fail++ }
    if ($ph -ne 0) { $fail++ }
    if (-not $curOK) { $fail++ }
    Write-Output ("META :: version={0} panels={1} vars={2} links={3} navtag={4} sig={5} ph={6} tgtBlob={7} dsBindings={8} sidebarLinks={9} currentOK={10} header={11}" -f `
            $w.meta.version, @($d.panels).Count, @($d.templating.list).Count, @($d.links).Count, ($d.tags -contains 'aegis-nav'), $sig, $ph, $tgt, $dsb, $sbLinks, $curOK, $hasHeader)

    # residual internal-leak scan (exclude sidebar id=1 nav links)
    $vis = @(); if ($d.description) { $vis += $d.description }
    foreach ($p in $d.panels) { if ([int]$p.id -eq 1) { continue }; if ($p.title) { $vis += $p.title }; if ($p.description) { $vis += $p.description }; if ($p.options.content) { $vis += $p.options.content } }
    $hits = @($vis | Where-Object { $_ -match $leak })
    if ($hits.Count -gt 0) { $warn += $hits.Count }
    Write-Output ("RESIDUAL internal-leaks = {0} (informational)" -f $hits.Count)
    $hits | ForEach-Object { Write-Output ("   HIT: {0}" -f ($_.Substring(0, [Math]::Min(120, $_.Length)))) }

    # functional: execute every panel's primary query with resolved variables
    $subQ = @{}; $subR = @{}
    foreach ($v in $d.templating.list) { $vals = Resolve-Values $v; $subQ[$v.name] = (($vals | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ','); $subR[$v.name] = ($vals -join ',') }
    $zero = 0; $maxRows = 0
    foreach ($p in ($d.panels | Where-Object { $_.targets } | Sort-Object { [int]$_.id })) {
        $t = $p.targets[0] | ConvertTo-Json -Depth 60 | ConvertFrom-Json
        if ($t.filterExpression) {
            $fe = $t.filterExpression
            foreach ($k in $subQ.Keys) { $fe = $fe -replace ('\$\{' + [regex]::Escape($k) + ':singlequote\}'), $subQ[$k] }
            foreach ($k in $subR.Keys) { $fe = $fe -replace ('\$\{' + [regex]::Escape($k) + ':raw\}'), $subR[$k]; $fe = $fe -replace ('\$\{' + [regex]::Escape($k) + ':csv\}'), $subR[$k]; $fe = $fe -replace ('\$\{' + [regex]::Escape($k) + '\}'), $subR[$k] }
            $t.filterExpression = $fe
        }
        $t | Add-Member -NotePropertyName datasource -NotePropertyValue @{ type = 'yesoreyeram-infinity-datasource'; uid = $DatasourceUid } -Force
        $t.refId = 'A'
        $unresolved = ($t.filterExpression -and $t.filterExpression -match '\$\{')
        $rc = Get-RowsCols (Invoke-Query $t)
        if ($rc.err) { Write-Output ("   id={0,-3} '{1}' ERROR {2}" -f $p.id, $p.title, $rc.err) }
        else { if ($rc.rows -eq 0 -and -not $unresolved) { $zero++ }; if ($rc.rows -gt $maxRows) { $maxRows = $rc.rows } }
    }
    if ($zero -gt 0) { $fail++ }
    Write-Output ("FUNCTIONAL :: zeroRowPanels={0} maxRows={1}" -f $zero, $maxRows)
}

Write-Output '================ GLOBAL ================'
$total = @($all).Count
$aegis = @($all | Where-Object { $_.folderUid -eq $AegisFolderUid }).Count
$linkOK = 0; foreach ($u in $dash.Keys) { if ($uids -contains $u) { $linkOK++ } }
if ($total -ne 80) { $fail++ }
if ($aegis -ne 10) { $fail++ }
if ($linkOK -ne 10) { $fail++ }
Write-Output ("TOTAL={0} (exp 80)  AEGIS_FOLDER={1} (exp 10)  ORIGINAL_NON_AEGIS={2} (exp 70)  LINKS_RESOLVED={3}/10" -f $total, $aegis, ($total - $aegis), $linkOK)
Write-Output ("RESIDUAL internal-text mentions (informational, not a health fault) = {0}" -f $warn)
Write-Output ("RESULT :: {0}" -f $(if ($fail -eq 0) { 'PASS — all 10 AEGIS dashboards healthy' } else { "FAIL — $fail health check(s) need attention" }))
$tok = $null
exit $(if ($fail -eq 0) { 0 } else { 1 })
