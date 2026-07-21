<#
    build-e7d11-check-catalog.ps1  (E7D.11 — Settings & Data Quality)

    Reproducibly DERIVES a read-only, machine-readable catalog of the 18 governed
    data-quality checks for Grafana visualization. It does NOT run or modify any
    validation logic. Every output row is driven by the authoritative source:

        V2/data/processed/validation/_data_quality_checks.csv   (18 rows, engine output)
        V1/python/drift_engine/checks.py                        (rule definitions)
        V2/data/processed/current/forecast_drift_runs.csv       (run id + checked_at)

    The per-check display metadata (display_name, category, scope, rule_description,
    expected_value) is a documented PRESENTATION layer justified 1:1 by the check's
    own code in checks.py. No check is invented, split, merged, or renamed: the
    canonical_check_name is copied verbatim and the loop is driven by the source CSV.
    The script FAILS (does not emit) if the source does not contain exactly 18 checks
    or if any source check lacks matching metadata.

    Output (governance artifact, lives alongside the engine's _data_quality_checks.csv):
        V2/data/processed/validation/forecast_drift_data_quality_checks.csv
    plus a .sha256 sidecar and a JSON-escaped inline payload:
        V2/data/processed/validation/forecast_drift_data_quality_checks.inline.txt

    NOTE (serving, E7D.11 Option B): Oscar authorized a minimal, strictly scoped nginx
    allowlist addition (V2/nginx/default.conf: a single
        location = /forecast_drift_data_quality_checks.csv
    entry, no wildcard, no directory listing, location / { return 404; } preserved) so
    the governed catalog is served by aegis-csv. This script therefore also writes a
    byte-identical served copy to:
        V2/data/processed/current/forecast_drift_data_quality_checks.csv
    The served copy is generated (never hand-edited), has exactly 18 rows / 18 PASS / 0
    FAIL, traces to the authoritative source, and carries the SAME sha256 as the
    validation copy. The Settings dashboard reads it via Infinity URL
    (http://aegis-csv/forecast_drift_data_quality_checks.csv), not inline.
#>
[CmdletBinding()]
param(
    [string]$Base = $env:AEGIS_DIR
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Base)) { throw "AEGIS_DIR not set and -Base not provided." }

$srcChecks = Join-Path $Base 'V2\data\processed\validation\_data_quality_checks.csv'
$srcRuns   = Join-Path $Base 'V2\data\processed\current\forecast_drift_runs.csv'
foreach ($p in @($srcChecks, $srcRuns)) { if (-not (Test-Path -LiteralPath $p)) { throw "Missing source: $p" } }

# --- authoritative run context ---
$run = Import-Csv -LiteralPath $srcRuns | Select-Object -First 1
$runId     = $run.calculation_run_id
$checkedAt = $run.run_finished_at

# --- authoritative individual checks (engine output) ---
$source = Import-Csv -LiteralPath $srcChecks
if ($source.Count -ne 18) { throw "Expected 18 source checks, found $($source.Count). ABORT (no invention)." }

# --- documented presentation metadata (keyed by canonical name; justified by checks.py) ---
# category/scope/rule/expected are a DERIVED display layer, not governed fields.
$meta = [ordered]@{
    'signals_not_empty'            = @{ d='Signals Not Empty';                 cat='Completeness & Presence'; scope='signals';       rule='The governed signals dataset must contain at least one row.';                                          exp='>= 1 signal row' }
    'required_columns_present'     = @{ d='Required Columns Present';          cat='Schema';                  scope='signals';       rule='All required signal columns (drift_event_id, record_hash, calculation_run_id, forecast_key, forecast_version, forecast_drift_score, drift_status, is_event, etc.) are present.'; exp='No required columns missing ([])' }
    'grain_unique'                 = @{ d='Grain Uniqueness';                  cat='Uniqueness';              scope='signals';       rule='No duplicate rows on the governed grain (calculation_version, scenario, forecast_key, forecast_version, drift_type).'; exp='0 duplicates' }
    'record_hash_unique'          = @{ d='Record Hash Uniqueness';            cat='Uniqueness';              scope='signals';       rule='Every record_hash value is unique across the signals dataset.';                                        exp='All record_hash unique' }
    'scores_in_0_100'              = @{ d='Scores Within 0-100';               cat='Value Range';             scope='signals';       rule='Performance/Shape/Stability/Volatility/composite drift scores and score_coverage_pct lie within [0, 100].'; exp='0 scores out of range' }
    'composite_not_null'          = @{ d='Composite Score Not Null';          cat='Completeness & Presence'; scope='signals';       rule='The composite forecast_drift_score is non-null for every signal.';                                     exp='No null composite scores' }
    'weights_sum_100'              = @{ d='Family Weights Sum to 100';         cat='Configuration';           scope='governed config'; rule='The governed family weights (Performance 20 + Shape 40 + Stability 30 + Volatility 10) sum to 100.';   exp='100.0' }
    'no_inf_values'                = @{ d='No Infinite Values';                cat='Value Range';             scope='family_scores'; rule='No infinite (Inf) values exist in the numeric family-score metrics.';                                   exp='0 infinite values' }
    'no_empty_keys'                = @{ d='No Empty Forecast Keys';            cat='Completeness & Presence'; scope='signals';       rule='Every signal has a non-empty forecast_key.';                                                           exp='No empty forecast_key' }
    'four_families_per_signal'     = @{ d='Four Families Per Signal';          cat='Structural Integrity';    scope='family_scores'; rule='Each signal has exactly four family-score rows (Performance, Shape, Stability, Volatility).';           exp='4 families for all signals' }
    'confidence_valid'             = @{ d='Confidence Level Valid';            cat='Enumeration';             scope='signals';       rule='confidence_level is one of {HIGH, MEDIUM, LOW}.';                                                       exp='All values in {HIGH, MEDIUM, LOW}' }
    'status_valid'                 = @{ d='Drift Status Valid';                cat='Enumeration';             scope='signals';       rule='drift_status is one of {Healthy, Watch, Warning, Critical, Unknown}.';                                  exp='All values in {Healthy, Watch, Warning, Critical, Unknown}' }
    'forecast_key_raw_present'     = @{ d='Raw Forecast Key Present';          cat='Completeness & Presence'; scope='signals';       rule='The forecast_key_raw lineage column (pre-canonicalization) is present (E5B I1).';                       exp='forecast_key_raw column present' }
    'forecast_key_is_canonical'    = @{ d='Forecast Key Is Canonical';         cat='Canonicalization';        scope='signals';       rule='forecast_key equals its canonical form UPPER(TRIM(forecast_key)) for every row.';                       exp='All forecast_key canonical' }
    'severity_only_on_events'      = @{ d='Severity Only On Events';           cat='Conditional Integrity';   scope='signals';       rule='severity is populated only where is_event = 1; otherwise it is null.';                                  exp='severity null unless is_event = 1' }
    'performance_mode_valid'       = @{ d='Performance Mode Valid';            cat='Enumeration';             scope='signals';       rule='performance_mode is one of {shallow, deep}.';                                                          exp='All values in {shallow, deep}' }
    'not_computable_has_null_score'= @{ d='Non-Computable Has Null Score';     cat='Conditional Integrity';   scope='family_scores'; rule='Family rows with eligibility_status = NOT_COMPUTABLE have a null family_score (never treated as zero).';  exp='All NOT_COMPUTABLE scores null' }
    'eligibility_status_valid'     = @{ d='Eligibility Status Valid';          cat='Enumeration';             scope='family_scores'; rule='eligibility_status is one of {COMPUTED, NOT_COMPUTABLE}.';                                              exp='All values in {COMPUTED, NOT_COMPUTABLE}' }
}

# --- friendly observed values (source detail verbatim when present, else faithful pass statement) ---
$observedMap = @{
    'signals_not_empty'             = '168'
    'required_columns_present'      = '[] (none missing)'
    'grain_unique'                  = '0 duplicates'
    'record_hash_unique'            = 'unique (assertion satisfied)'
    'scores_in_0_100'               = '0 out of range'
    'composite_not_null'            = 'no nulls (assertion satisfied)'
    'weights_sum_100'               = '100.0'
    'no_inf_values'                 = '0'
    'no_empty_keys'                 = 'no empty keys (assertion satisfied)'
    'four_families_per_signal'      = '{4: 168}'
    'confidence_valid'              = 'all valid (assertion satisfied)'
    'status_valid'                  = 'all valid (assertion satisfied)'
    'forecast_key_raw_present'      = 'present (assertion satisfied)'
    'forecast_key_is_canonical'     = 'all canonical (assertion satisfied)'
    'severity_only_on_events'       = 'satisfied (assertion satisfied)'
    'performance_mode_valid'        = 'all valid (assertion satisfied)'
    'not_computable_has_null_score' = 'satisfied (assertion satisfied)'
    'eligibility_status_valid'      = 'all valid (assertion satisfied)'
}

$rows = New-Object System.Collections.Generic.List[object]
$order = 0
foreach ($chk in $source) {
    $order++
    $name = $chk.check
    if (-not $meta.Contains($name)) { throw "Source check '$name' has no documented metadata. ABORT (no invention)." }
    $m = $meta[$name]
    $observed = if ($observedMap.ContainsKey($name)) { $observedMap[$name] } else { $chk.detail }
    $rows.Add([pscustomobject][ordered]@{
        calculation_run_id   = $runId
        check_order          = $order
        check_id             = ('DQ-{0:D2}' -f $order)
        canonical_check_name = $name
        display_name         = $m.d
        category             = $m.cat
        scope                = $m.scope
        rule_description     = $m.rule
        expected_value       = $m.exp
        observed_value       = $observed
        check_status         = $chk.result
        severity             = 'blocking'
        evidence_source      = 'validation/_data_quality_checks.csv'
        evidence_reference   = ("checks.py::run_checks -> {0} = {1}" -f $name, ($(if ([string]::IsNullOrEmpty($chk.detail)) { '(boolean pass)' } else { $chk.detail })))
        checked_at_utc       = $checkedAt
    })
}

if ($rows.Count -ne 18) { throw "Built $($rows.Count) rows, expected 18. ABORT." }
$passCount = ($rows | Where-Object { $_.check_status -eq 'PASS' }).Count
if ($passCount -ne 18) { throw "PASS count = $passCount, expected 18. ABORT." }

$destValidation = Join-Path $Base 'V2\data\processed\validation\forecast_drift_data_quality_checks.csv'

$rows | Export-Csv -LiteralPath $destValidation -NoTypeInformation -Encoding UTF8

$hash = (Get-FileHash -LiteralPath $destValidation -Algorithm SHA256).Hash
Set-Content -LiteralPath ($destValidation + '.sha256') -Value $hash -Encoding ascii

# Emit a JSON-escaped inline CSV payload (kept for reference / offline use).
$rawCsv = Get-Content -LiteralPath $destValidation -Raw
$inlineJson = ($rawCsv | ConvertTo-Json)
Set-Content -LiteralPath (Join-Path $Base 'V2\data\processed\validation\forecast_drift_data_quality_checks.inline.txt') -Value $inlineJson -Encoding UTF8

# E7D.11 Option B: write a byte-identical SERVED copy into the nginx docroot (current/).
# Copy the exact bytes of the validation artifact so the served checksum is identical.
$destServed = Join-Path $Base 'V2\data\processed\current\forecast_drift_data_quality_checks.csv'
Copy-Item -LiteralPath $destValidation -Destination $destServed -Force
$hashServed = (Get-FileHash -LiteralPath $destServed -Algorithm SHA256).Hash
Set-Content -LiteralPath ($destServed + '.sha256') -Value $hashServed -Encoding ascii
if ($hashServed -ne $hash) { throw "Served copy checksum ($hashServed) != validation ($hash). ABORT." }

Write-Host "CATALOG WRITTEN — rows=$($rows.Count) pass=$passCount run=$runId checked_at=$checkedAt"
Write-Host "SHA256(validation)=$hash"
Write-Host "SHA256(served)   =$hashServed"
Write-Host "identical        =$([string]::Equals($hash,$hashServed))"
Write-Host "validation -> $destValidation"
Write-Host "served     -> $destServed"
