# User guide

One page per topic. Each page says who can do what, where to click, and what
happens. The [advanced section](advanced/README.md) carries the detail you need
less often.

If you are new, start with the [Quick start](../quick-start.md).

## Pages

| | Page | What it covers |
|---|---|---|
| 1 | [Signing in and roles](01-signing-in.md) | Tenants, the three roles, passkeys in brief, the welcome wizard |
| 2 | [The Overview](02-overview.md) | The home page: tiles, trend, heatmap, drill-downs |
| 3 | [The Inventory](03-inventory.md) | Endpoints, certificates and keys; search, filters, columns, export |
| 4 | [Sources](04-sources.md) | Adding targets, scheduling, scan history, imports, manual entries |
| 5 | [Endpoint and certificate pages](05-detail-pages.md) | What a detail page shows, trust chains, acknowledging findings |
| 6 | [Client scanners](06-host-scanners.md) | Scanning a host from the inside on Linux, Windows and macOS |
| 7 | [Bifröst remote engines](07-remote-engines.md) | Scanning networks the server cannot reach |
| 8 | [Policy](08-policy.md) | Grading presets, algorithm rules, weights and expiry thresholds |
| 9 | [Compliance](09-compliance.md) | The framework reports and how to read them |
| 10 | [Planning](10-planning.md) | Cohorts, waves, owners, the Roadmap, the board deck |
| 11 | [Cloud discovery (beta)](11-cloud-discovery.md) | Keys and TLS front ends from Google Cloud and Azure |
| 12 | [Governance attributes](12-governance.md) | Owner, criticality and your own fields |
| 13 | [Admin](13-admin.md) | Your tenant: users, teams, proxies, audit trail, import and export |
| 14 | [Platform console](14-platform-console.md) | The installation: tenants, administrators, TLS, licence, SSO |
| 15 | [Your account](15-your-account.md) | Security page, password, passkeys, Confirm it's you |

## By task

| I want to | Go to |
|---|---|
| Find every TLS endpoint on a subnet | [Sources](04-sources.md), Network range |
| See which endpoints share one certificate | [Inventory](03-inventory.md), Certificates view |
| Know what is on a server, not only what it presents | [Client scanners](06-host-scanners.md) |
| Scan a DMZ or an OT network | [Bifröst remote engines](07-remote-engines.md) |
| Record an HSM or a mainframe nothing can scan | [Sources](04-sources.md), Manual entries |
| Export to Excel or a CycloneDX CBOM | [Inventory](03-inventory.md), Export |
| Decide what counts as a good grade | [Policy](08-policy.md) |
| Produce evidence for an auditor | [Compliance](09-compliance.md) |
| Prepare for DORA or FINMA | [DORA](advanced/dora.md), [FINMA 05/2026](advanced/finma-05-2026.md) |
| Put owners and criticality on endpoints | [Governance attributes](12-governance.md) |
| Draft a migration plan | [Planning](10-planning.md) |
| Take the plan to the board | [Planning](10-planning.md), Board deck |
| Read keys in Azure Key Vault or Google Cloud KMS | [Cloud discovery](11-cloud-discovery.md) |
| Add a colleague | [Admin](13-admin.md) |
| Turn on single sign-on | [Platform console](14-platform-console.md) |
| Replace the server's certificate | [Platform console](14-platform-console.md), TLS |
| Enter or renew the licence | [Platform console](14-platform-console.md), Licence |
| Recover a lost passkey | [Passkeys and recovery codes](advanced/passkeys-and-recovery.md) |

## Advanced

Detail for the people who need it: [advanced/README.md](advanced/README.md).
