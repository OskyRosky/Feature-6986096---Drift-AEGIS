# verify-grafana-mcp-token.ps1
# E7B.3 - Verify the DPAPI-encrypted token exists and is decryptable by the CURRENT user.
# Read-only: it does NOT display the token, connect to Grafana, or start any server.

[CmdletBinding()]
param(
    [string]$TokenPath = (Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $TokenPath)) {
    Write-Host "[verify-token] TOKEN_PRESENT=False"
    Write-Host "[verify-token] No encrypted token found at: $TokenPath"
    exit 1
}

try {
    $cipher = Get-Content -LiteralPath $TokenPath -Raw
    $secure = ConvertTo-SecureString -String $cipher   # DPAPI decrypt (CurrentUser)
    $ok = ($secure -and $secure.Length -gt 0)
    if ($secure) { $secure.Dispose() }
    if ($ok) {
        Write-Host "[verify-token] TOKEN_PRESENT=True"
        Write-Host "[verify-token] TOKEN_DECRYPTABLE=True (current user)"
        Write-Host "[verify-token] The token value was NOT displayed."
        exit 0
    } else {
        Write-Host "[verify-token] TOKEN_PRESENT=True"
        Write-Host "[verify-token] TOKEN_DECRYPTABLE=False (empty after decrypt)"
        exit 1
    }
}
catch {
    Write-Host "[verify-token] TOKEN_PRESENT=True"
    Write-Host "[verify-token] TOKEN_DECRYPTABLE=False (not decryptable by current user)"
    exit 1
}
