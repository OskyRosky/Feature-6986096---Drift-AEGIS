# remove-grafana-mcp-token.ps1
# E7B.3 - Delete ONLY the local DPAPI-encrypted token file.
# This does NOT revoke the remote Grafana service account token.
# Remote revocation must be done in the Grafana UI:
#   Administration > Users and access > Service accounts > aegis-mcp > Tokens > (delete)

[CmdletBinding()]
param(
    [string]$TokenPath = (Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $TokenPath)) {
    Write-Host "[remove-token] LOCAL_TOKEN_REMOVED=NotFound (nothing to delete)"
} else {
    Remove-Item -LiteralPath $TokenPath -Force
    Write-Host "[remove-token] LOCAL_TOKEN_REMOVED=True"
    Write-Host "[remove-token]   Deleted: $TokenPath"
}

Write-Host "[remove-token] NOTE: the REMOTE Grafana token is still valid until revoked."
Write-Host "[remove-token] Revoke it in Grafana: Administration > Users and access > Service accounts > aegis-mcp > Tokens."
exit 0
