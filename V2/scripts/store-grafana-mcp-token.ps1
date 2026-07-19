# store-grafana-mcp-token.ps1
# E7B.3 - Securely store the Grafana service account token using Windows DPAPI.
# The token is encrypted at rest (CurrentUser scope) OUTSIDE the repository.
# It is NEVER printed, logged, committed, or accepted as a command-line argument.
#
# Usage: run interactively, paste the token ONLY at the hidden prompt.
#   V2\scripts\store-grafana-mcp-token.ps1

[CmdletBinding()]
param(
    [string]$TokenPath = (Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi')
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) { Write-Error "[store-token] $Message"; exit 1 }

# --- Safety: refuse to write inside a repository / synced folder ---
$full = [System.IO.Path]::GetFullPath($TokenPath)
if ($full -notlike (Join-Path $env:LOCALAPPDATA '*')) { Fail "Refusing: token path must be under %LOCALAPPDATA%." }
if ($full -match 'OneDrive' -or $full -match 'Feature 6986096' -or $full -match '\\\.git\\') {
    Fail "Refusing: token path appears to be inside a repository or synced folder."
}

$dir = Split-Path -Parent $full
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# --- Read token (hidden) - never as an argument ---
$secure = Read-Host -AsSecureString "Paste the Grafana service account token (input hidden)"
if (-not $secure -or $secure.Length -eq 0) { Fail "No token entered." }

# --- Encrypt with DPAPI (CurrentUser) and write ONLY the ciphertext ---
# ConvertFrom-SecureString without -Key uses DPAPI bound to the current user + machine.
$cipher = ConvertFrom-SecureString -SecureString $secure
Set-Content -Path $full -Value $cipher -Encoding ASCII -NoNewline

# --- Restrict ACL to the current user only (best effort) ---
try {
    icacls $full /inheritance:r /grant:r "$($env:USERDOMAIN)\$($env:USERNAME):F" | Out-Null
} catch { Write-Host "[store-token] WARN: could not tighten ACL automatically." }

# --- Zero the secure string from memory ---
$secure.Dispose()

Write-Host "[store-token] OK - token stored ENCRYPTED (DPAPI, CurrentUser) at:"
Write-Host "[store-token]   $full"
Write-Host "[store-token] The token value was never displayed, logged, or written in plaintext."
Write-Host "TOKEN_STORED=True"
exit 0
