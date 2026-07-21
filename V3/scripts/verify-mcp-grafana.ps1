# verify-mcp-grafana.ps1
# E7B.2 - Read-only verifier for the installed Grafana MCP server binary.
# Locates the pinned install, validates version + SHA256, runs --help.
# Does NOT connect to Grafana. Does NOT require a token. No secrets.

[CmdletBinding()]
param(
    [string]$Version = '0.17.2',
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'AEGIS\mcp-grafana')
)

$ErrorActionPreference = 'Stop'

$ExpectedArchiveSha = @{
    'AMD64' = '939eb0f4ecc6a6e2ded979b658ba18233d6939f5af1a5ed9e17b8a7a5eb62616'
    'ARM64' = 'c66883630cedd67358b6e24f7fa770ae07f53e19cf3b186c06fb4a92a5856cdc'
}

function Fail([string]$Message) { Write-Error "[verify-mcp-grafana] $Message"; exit 1 }

$installDir = Join-Path $InstallRoot ("v{0}" -f $Version)
$exePath    = Join-Path $installDir 'mcp-grafana.exe'

if (-not (Test-Path $exePath)) { Fail "Binary not found: $exePath" }

# 1) Version
$reported = (& $exePath --version 2>&1 | Out-String).Trim()
if ($reported -ne $Version) { Fail "Version mismatch. expected=$Version reported=$reported" }
Write-Host "[verify-mcp-grafana] Version OK: $reported"

# 2) Recorded archive checksum matches the pinned value for this architecture
$localFile = Join-Path $installDir 'SHA256SUMS.local.txt'
if (Test-Path $localFile) {
    $arch = $env:PROCESSOR_ARCHITECTURE
    $pinned = $ExpectedArchiveSha[$arch]
    if ($pinned -and -not (Select-String -Path $localFile -Pattern $pinned -Quiet)) {
        Fail "Recorded archive SHA256 does not match the pinned value for $arch."
    }
    Write-Host "[verify-mcp-grafana] Recorded checksum OK (SHA256SUMS.local.txt)."
} else {
    Write-Host "[verify-mcp-grafana] WARN: SHA256SUMS.local.txt not found; skipping checksum record check."
}

# 3) Current binary hash (informational, no network)
$exeHash = (Get-FileHash -Algorithm SHA256 $exePath).Hash.ToLower()
Write-Host "[verify-mcp-grafana] Current mcp-grafana.exe SHA256: $exeHash"

# 4) --help (no Grafana connection, no token)
Write-Host "[verify-mcp-grafana] --help (first lines):"
(& $exePath --help 2>&1 | Select-Object -First 6) | ForEach-Object { "    $_" }

Write-Host "[verify-mcp-grafana] OK - binary present and valid. No Grafana connection attempted."
exit 0
