# The Overview

The home page. It answers two questions: where does our cryptography stand
today, and is it getting better?
**Who:** every signed-in role.

![The Overview](../images/overview.png)

## The tiles

| Tile | Counts |
|---|---|
| **Quantum-vulnerable** | Endpoints whose key exchange a quantum computer could break. Shows the change since the previous scan. |
| **Expiring soon** | Certificates inside the warning window set in [Policy](08-policy.md). |
| **Weak protocol** | Endpoints still offering SSL, TLS 1.0 or TLS 1.1. |
| **Quantum-ready** | Endpoints whose post-quantum status your Policy counts as compliant. Shows the change since the previous scan. |
| **Total endpoints** | Everything measured. |

Click a tile to open the Inventory already filtered to those endpoints.

## The cards

- **Migration progress.** Quantum-ready against vulnerable endpoints over time. Every scan run adds a point. The two date fields narrow the chart to any window, such as the last week of a rollout.
- **Risk against appetite.** Your exposure now, and where the plan takes it, against the risk appetite set in [Planning](10-planning.md).
- **PQC migration backlog.** A heatmap of the endpoints that are not yet quantum-ready, by criticality and migration complexity. Start at the top left.
- **Expiring soon.** The next certificates to lapse.
- **Post-quantum posture.** Vulnerable, hybrid and quantum-safe as a share of the fleet.
- **Algorithm and key strength.** Public-key algorithm, key size (labelled with its algorithm, so "RSA 2048" and "ECDSA 256" are told apart), signature hash and grade distribution. Weak values are red.
- **Protocol and cipher hygiene.** TLS versions and weak ciphers across the fleet.
- **Top offending endpoints.** The worst-graded hosts, lowest first.

Every bar and every row is a drill-down: click it and the Inventory opens with
that filter applied.

## Colours

Grades and post-quantum badges are tinted by your Policy. Anything that does
not meet it stands out in the same colour here, in the Inventory and on detail
pages. Change the Policy and the colours change with it, without a new scan.

## Scan status

A pill in the top bar shows when the last scan ran and how many endpoints it
covered. While a scan runs it reads "Scanning N/M".

## Services known only from cloud configuration

A service a cloud source has declared but no scan has measured yet is in the
inventory but in no figure here. The posture card says how many, with a link
to them. See [Cloud discovery](11-cloud-discovery.md).

## See also

- [The Inventory](03-inventory.md)
- [Policy](08-policy.md)
