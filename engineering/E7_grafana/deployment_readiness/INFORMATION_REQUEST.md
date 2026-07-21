# Information Request — Corporate Grafana Portal Deployment

**Purpose:** collect the inputs the AEGIS Forecast Drift team needs before a future,
separately-authorized corporate portal deployment. Nothing is deployed until these
are answered and deployment is explicitly authorized.

**Owner to provide:** portal & infrastructure owners (e.g. Chinmay / platform team).

| # | Question | Why it is needed | Answer |
|---|---|---|---|
| 1 | Target corporate Grafana portal URL + organization + folder name? | Destination for the 10 dashboards | _pending_ |
| 2 | Approved endpoint/hosting for the 5 governed CSVs reachable from the portal (replacing `http://aegis-csv`)? | Local Docker alias will not resolve in the portal | _pending_ |
| 3 | Datasource authentication model (anonymous internal, token, SSO, mTLS)? | Configure Infinity datasource securely | _pending_ |
| 4 | Service account / role with permission to import dashboards and provision the datasource? | Perform the import under least privilege | _pending_ |
| 5 | Network / firewall / private-endpoint constraints for portal → CSV host? | Ensure connectivity without exposing data | _pending_ |
| 6 | Owner + cadence for the governed data refresh in the portal environment? | Keep the 18-check catalog and datasets current | _pending_ |
| 7 | Change-management / approval process for publishing dashboards? | Comply with corporate governance | _pending_ |
| 8 | Retention/rollback expectations in the portal? | Align with `ROLLBACK.md` | _pending_ |

## Fixed values the deployment must preserve
- Datasource UID: `aegis-forecast-drift-csv`
- Dashboard UIDs: see `../E7D12_dashboard_inventory.md` / release `UID_INVENTORY.md`
- Navigation tag: `aegis-nav` (10 active dashboards; Top Scenarios excluded)
- Data-quality catalog SHA256: `9E76361F23A9C74E34B32F90697499F4FB065F1E00C8E03F3A18374B88551EE1`
