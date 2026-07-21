# E7D.12 — Security & Secrets Validation

**Result: CLEAN — no secrets in the repository.**

## Secret scan
| Item | Value |
|---|---|
| Scope | `V2/**` config, scripts, docs, dashboards (excludes governed data CSVs) |
| Files scanned | 83 |
| Patterns | Grafana service-account tokens (`glsa_…`), JWT (`eyJ…`), `Authorization: Bearer …`, private-key headers, `password=`, `secret=`, `api_key`, connection-string secrets |
| Matches | **0** |

The only earlier match was the throwaway scan script itself (pattern text, not a
secret); all three E7D.12 temp scripts were removed after the precheck.

## Token handling
- The Grafana service-account (MCP) token is stored **DPAPI-encrypted** at
  `%LOCALAPPDATA%\AEGIS\secrets\grafana\aegis-mcp.token.dpapi` — **outside** the
  repository and **not** git-tracked.
- No script prints or persists the decrypted token. Decryption is in-memory only and
  the buffer is zeroed/freed in a `finally` block.
- No token, credential, or connection string appears in any dashboard JSON,
  provisioning YAML, compose file, or documentation.

## Datasource / network posture
- Infinity datasource `aegis-forecast-drift-csv` targets `http://aegis-csv`
  (internal Docker network only) and restricts `allowedHosts` to that host. No auth
  material embedded.
- `aegis-csv` (nginx) is read-only: `autoindex off`, `server_tokens off`, GET/HEAD
  only (405 otherwise), an explicit allowlist of the five governed CSVs plus
  `/healthz`, and `location / { return 404; }`. No host ports are published.

## Validator posture
All four E7D.12 validators are strictly read-only, print no secrets, and exit 0/1.

**Result: security & secrets — PASS (clean).**
