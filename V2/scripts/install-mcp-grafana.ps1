# install-mcp-grafana.ps1
# E7B.2 - Reproducible, secret-free installer for the official Grafana MCP server.
# Pins mcp-grafana v0.17.2, installs OUTSIDE the repository, verifies SHA256.
# No secrets. No token. Does not modify global PATH. Does not connect to Grafana.
# Idempotent: re-running with an already-valid install is a no-op.
#
# Source (authorized only): https://github.com/grafana/mcp-grafana  (Apache-2.0)

[CmdletBinding()]
param(
    [string]$Version = '0.17.2',
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'AEGIS\mcp-grafana'),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Pinned official assets + SHA256 for supported Windows architectures (v0.17.2).
$Assets = @{
    'AMD64' = @{ File = 'mcp-grafana_Windows_x86_64.zip'; Sha256 = '939eb0f4ecc6a6e2ded979b658ba18233d6939f5af1a5ed9e17b8a7a5eb62616' }
    'ARM64' = @{ File = 'mcp-grafana_Windows_arm64.zip';  Sha256 = 'c66883630cedd67358b6e24f7fa770ae07f53e19cf3b186c06fb4a92a5856cdc' }
}

function Fail([string]$Message) { Write-Error "[install-mcp-grafana] $Message"; exit 1 }

# --- Detect architecture ---
$arch = $env:PROCESSOR_ARCHITECTURE
if (-not $Assets.ContainsKey($arch)) { Fail "Unsupported architecture: $arch (supported: $($Assets.Keys -join ', '))." }
$asset  = $Assets[$arch].File
$expect = $Assets[$arch].Sha256.ToLower()

$installDir = Join-Path $InstallRoot ("v{0}" -f $Version)
$exePath    = Join-Path $installDir 'mcp-grafana.exe'

# --- Idempotency: valid existing install ---
if ((Test-Path $exePath) -and -not $Force) {
    try {
        $reported = (& $exePath --version 2>&1 | Out-String).Trim()
        if ($reported -eq $Version) {
            Write-Host "[install-mcp-grafana] Already installed and valid: $exePath (v$Version). Nothing to do."
            exit 0
        }
    } catch { }
    Write-Host "[install-mcp-grafana] Existing install failed validation; reinstalling."
}

New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# --- Download official asset + checksums to temp ---
$base = "https://github.com/grafana/mcp-grafana/releases/download/v$Version"
$tmpZip = Join-Path $env:TEMP $asset
$tmpChk = Join-Path $env:TEMP "mcp-grafana_${Version}_checksums.txt"

Write-Host "[install-mcp-grafana] Downloading $asset from official release v$Version ..."
Invoke-WebRequest -Uri "$base/$asset" -OutFile $tmpZip -UseBasicParsing
Invoke-WebRequest -Uri "$base/mcp-grafana_${Version}_checksums.txt" -OutFile $tmpChk -UseBasicParsing

# --- Integrity: local hash vs pinned hash vs official checksums file ---
$actual = (Get-FileHash -Algorithm SHA256 $tmpZip).Hash.ToLower()
$line   = (Select-String -Path $tmpChk -Pattern ([regex]::Escape($asset))).Line
$fromFile = if ($line) { ($line -split '\s+')[0].ToLower() } else { $null }

if ($actual -ne $expect)  { Remove-Item $tmpZip,$tmpChk -Force -ErrorAction SilentlyContinue; Fail "SHA256 mismatch vs pinned value. expected=$expect actual=$actual" }
if ($actual -ne $fromFile){ Remove-Item $tmpZip,$tmpChk -Force -ErrorAction SilentlyContinue; Fail "SHA256 mismatch vs official checksums file. file=$fromFile actual=$actual" }
Write-Host "[install-mcp-grafana] SHA256 verified: $actual"

# --- Extract only required files ---
Expand-Archive -Path $tmpZip -DestinationPath $installDir -Force
Copy-Item $tmpChk (Join-Path $installDir 'checksums.official.txt') -Force

$exeHash = (Get-FileHash -Algorithm SHA256 $exePath).Hash.ToLower()
Set-Content -Path (Join-Path $installDir 'SHA256SUMS.local.txt') -Value @(
    "$expect  $asset (archive)",
    "$exeHash  mcp-grafana.exe (extracted)"
)

# Keep only the required files in the final path.
Remove-Item (Join-Path $installDir 'README.md'),(Join-Path $installDir 'CHANGELOG.md') -Force -ErrorAction SilentlyContinue
Remove-Item $tmpZip,$tmpChk -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $exePath)) { Fail "Binary not found after extraction: $exePath" }
$reported = (& $exePath --version 2>&1 | Out-String).Trim()
if ($reported -ne $Version) { Fail "Version check failed. expected=$Version reported=$reported" }

Write-Host "[install-mcp-grafana] OK - installed v$Version at: $exePath"
Write-Host "[install-mcp-grafana] Global PATH was NOT modified (by design)."
exit 0
