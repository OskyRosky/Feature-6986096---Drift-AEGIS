# start-mcp-grafana.ps1
# E7B.4 - Launch mcp-grafana (stdio) with the DPAPI-encrypted token decrypted ONLY in memory.
# The token is NEVER written to disk in plaintext, printed, or logged.
# Tool allow-list is restricted to: search, datasource, dashboard, folder.
#
# STDIO-CLEAN: stdout carries ONLY the MCP JSON-RPC stream produced by mcp-grafana.
# All wrapper diagnostics go to stderr so they cannot corrupt the protocol. This
# script is the command registered as the Claude Code MCP server 'grafana'.

[CmdletBinding()]
param(
    [string]$TokenPath = (Join-Path $env:LOCALAPPDATA 'AEGIS\secrets\grafana\aegis-mcp.token.dpapi'),
    [string]$GrafanaUrl = 'http://localhost:3000',
    [string]$ExePath = (Join-Path $env:LOCALAPPDATA 'AEGIS\mcp-grafana\v0.17.2\mcp-grafana.exe'),
    [string]$EnabledTools = 'search,datasource,dashboard,folder'
)

$ErrorActionPreference = 'Stop'

# Keep stdout as raw UTF-8 (MCP framing). Diagnostics -> stderr only.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$OutputEncoding = [System.Text.Encoding]::UTF8
function Note([string]$Message) { [Console]::Error.WriteLine("[start-mcp] $Message") }
function Fail([string]$Message) { [Console]::Error.WriteLine("[start-mcp] ERROR: $Message"); exit 1 }

if (-not (Test-Path -LiteralPath $TokenPath)) { Fail "Encrypted token not found. Run store-grafana-mcp-token.ps1 first." }
if (-not (Test-Path -LiteralPath $ExePath))   { Fail "mcp-grafana.exe not found at $ExePath." }

$bstr = [IntPtr]::Zero
try {
    # --- Decrypt DPAPI ciphertext into a SecureString (CurrentUser) ---
    $cipher = Get-Content -LiteralPath $TokenPath -Raw
    $secure = ConvertTo-SecureString -String $cipher   # DPAPI decrypt; fails if not current user

    # --- Marshal to plaintext ONLY in process memory (no disk) ---
    $bstr  = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

    # --- Inject process-scoped env vars for the child process ---
    $env:GRAFANA_URL = $GrafanaUrl
    $env:GRAFANA_SERVICE_ACCOUNT_TOKEN = $plain

    Note "Launching mcp-grafana (stdio) with tools: $EnabledTools"
    Note "GRAFANA_URL=$GrafanaUrl (token injected in memory only)"

    # --- Run the server (stdio). Only the 4 allow-listed tool categories are enabled. ---
    & $ExePath -t stdio --enabled-tools $EnabledTools
}
finally {
    # --- Clean up secret material from memory and environment ---
    if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    Remove-Item Env:GRAFANA_SERVICE_ACCOUNT_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:GRAFANA_URL -ErrorAction SilentlyContinue
    if ($secure) { $secure.Dispose() }
    Note "Token cleared from environment and memory."
}
