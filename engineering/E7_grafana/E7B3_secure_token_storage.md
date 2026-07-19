# E7B.3 — Secure Token Storage (DPAPI)

**Feature 6986096 — AEGIS Forecast Drift Framework**
Stage: E7B.3 — Grafana Service Account & Secure Token
Date: 2026-07-18

> Microsoft internal / confidential. **No token value, prefix, suffix, hash, or
> encrypted content is recorded here.**

## Token mechanism decision (verified against v0.17.2)

The user required that `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` support **not be assumed**
but verified against the actual `mcp-grafana` **v0.17.2** binary **and** the official
source pinned at that tag.

| Mechanism | Supported in v0.17.2 | Evidence | Decision |
| --- | --- | --- | --- |
| `GRAFANA_SERVICE_ACCOUNT_TOKEN` | Yes | Binary strings + README @ tag v0.17.2 | **Used** — injected in memory only |
| `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` | Yes | Binary strings + README @ tag v0.17.2 ("read fresh on every request; inline token takes precedence") | **Not used** — requires plaintext token on disk |
| `GRAFANA_API_KEY` | Yes (deprecated) | README deprecation note | Not used |
| username / password | Yes | README | Not used (weaker) |

**Outcome:** `GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE` **is** officially supported in
v0.17.2. It was nevertheless **rejected** because it stores the token in **plaintext
at rest**, which violates the project rule "never store the token in plaintext".
Instead the token is stored **encrypted with Windows DPAPI (CurrentUser scope)** and
decrypted **only in process memory** by the launch wrapper, which then sets
`GRAFANA_SERVICE_ACCOUNT_TOKEN` for the child process only.

## Storage location (outside the repository)

```
%LOCALAPPDATA%\AEGIS\secrets\grafana\aegis-mcp.token.dpapi
```

- Outside the Git working tree and outside the OneDrive-synced project folder.
- The repository therefore needs **no `.gitignore` change** for this secret.
- File ACL tightened to the current user only (best-effort via `icacls`).

## Scripts (secret-free, ASCII-only, in `V2/scripts/`)

| Script | Purpose |
| --- | --- |
| `store-grafana-mcp-token.ps1` | Reads token via hidden `Read-Host -AsSecureString`; encrypts with DPAPI (CurrentUser); writes only ciphertext outside the repo; never prints value/length/hash; refuses paths inside repo/OneDrive |
| `start-mcp-grafana.ps1` | Decrypts DPAPI in memory; injects `GRAFANA_URL` + `GRAFANA_SERVICE_ACCOUNT_TOKEN` process-scoped; runs `mcp-grafana -t stdio --enabled-tools search,datasource,dashboard,folder`; clears env + zeroes memory in `finally` (prepared for E7B.4 — **not run in E7B.3**) |
| `verify-grafana-mcp-token.ps1` | Confirms the ciphertext exists and is decryptable by the current user; displays nothing; no Grafana connection |
| `remove-grafana-mcp-token.ps1` | Deletes only the local ciphertext; explains remote revocation is done in the Grafana UI |

## Encryption properties

- **DPAPI CurrentUser**: only the same Windows user on the same machine can decrypt.
- Token value is **never** written to disk in plaintext, never printed, never logged,
  and never accepted as a command-line argument.
- The plaintext exists only transiently in process memory and is zeroed
  (`ZeroFreeBSTR`) after use.

## Manual action performed (Phase 5)

The user created the service account and token in the Grafana UI and ran
`store-grafana-mcp-token.ps1`, confirming `TOKEN_STORED=True`. The token value was
entered only at the hidden PowerShell prompt and was never shared in chat.
