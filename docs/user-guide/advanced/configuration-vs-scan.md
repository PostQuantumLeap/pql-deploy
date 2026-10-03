# Cloud configuration compared with scans

A cloud source reads what a front end is configured to present. A scan reads what the endpoint really presents. This page explains how Post Quantum Leap shows the two side by side, what each verdict means, and how to acknowledge a finding you already understand.

**Who:** Reader to view. PKI Operator or System Administrator to acknowledge a finding.

## What this comparison is, and what it never affects

The comparison appears on the certificate page, on the endpoint page, on the cloud source's card and in the Inventory. It is information only. Nothing in it enters a figure, a grade, a compliance report's verdict, the Overview or an export column.

Planning is the one place that uses it. Proposals treat Reach as a discount only, and a planning rule can select cohorts by Reach and by key custody.

## A certificate's places

The certificate page lists where PQL has seen the certificate (see [Detail pages](../05-detail-pages.md)).

| Section | What it lists |
|---|---|
| **Served at** | First, the endpoints a scan's handshake saw presenting this certificate. Then the front ends a cloud source reads that are configured with it, marked *Configured, not measured*. Then rows that are only recorded, marked *Recorded, not measured*. When nothing presented it, the section says *Not served at any endpoint PQL measured or read*. |
| **Stored in** | The stores that hold the same certificate: a Key Vault, an App Service, an Application Gateway, a Google Cloud certificate, or a host store the client scanner read. Each carries its own statement about its keys. When none holds it, the section says *No store PQL reads holds this certificate*, but only when every store answered. Otherwise it says that no store PQL could read holds it, and how many stores could not be read (see the source's card). |
| **Private key found** | Each private-key file the client scanner reported with this certificate's public key, worded as where it was found. *On this host* appears only when the file is on the certificate's own endpoint. *Encrypted* appears only when the scanner verified it. |

Two limits apply to **Private key found**. A public-key file never counts. An encrypted key file carries no hash, so "none reported" never means that no key file exists.

### The fingerprint rule

PQL matches these places by the certificate's fingerprint, but only when that fingerprint was computed from the certificate's bytes. A fingerprint that was typed, made up or read from an imported file is not matched. This includes a scanner's own fingerprint, which PQL trusts only when it arrived in a token-authenticated client-scanner submission.

Such a certificate says *This fingerprint was not computed from the certificate's bytes, so PQL does not match it with other places*. The page then lists only the row itself.

## The endpoint page's verdict

The card sits under the configuration of a service that a cloud source claims and a scan has measured. It compares the certificate the endpoint presents (its served leaf) with the certificates its declaring front ends are configured with. Only the served leaf counts, never an intermediate.

Either match outcome needs only the certificate the endpoint presents now. A finding, and every other outcome for information, needs two scans in a row after the configuration last changed, and after the platform's rollout window has passed.

The card says one of eight things:

| Outcome | What it means | Kind |
|---|---|---|
| **Matches its configuration** | The endpoint presents a certificate its outermost front end is configured with. | Match |
| **Matches an inner front end** | It presents the certificate of a front end behind the outermost one, such as an App Service behind Front Door. The scan may be reaching the origin directly. | For information |
| **Renewal not served** | The front end has a newer version than the one the endpoint still presents, seen in two scans after the platform's window. Possible causes: the front end has not picked up the new version, it reports the new version while an edge still shows the old one, it is pinned to an older version, or a newer certificate was uploaded and not attached. | Finding |
| **Same key, other certificate** | It presents another certificate over the same public key. The same key is never the same certificate. | For information |
| **Not for this name** | It presents a certificate that does not name this host. This is the platform's answer to a name it does not bind. | For information |
| **The platform's default certificate** | It presents the platform's own default certificate. | For information |
| **Certificate not in the configuration** | It presents a certificate that none of its declaring front ends is configured with, seen in two scans after the configuration last changed. Possible reasons: a CDN or DNS pointing elsewhere, a certificate bound outside what the source reads, or TLS inspection on the scanner's path. | Finding |
| **Not compared** | PQL could not compare fairly, and says why. See the list below. | Not compared |

**Not compared** gives one of these reasons:

- A front end declaring the endpoint was not read in the last sync.
- No source claims the endpoint now.
- No scan has read its own certificate.
- The first certificate it presents is a CA certificate, not its own.
- Its certificate is not known well enough to compare.
- The configuration does not name every certificate it could present.
- The vault's current version was not read this time.
- The configuration changed recently, and the platform may still be rolling it out.
- It is waiting for two scans after the platform's window.
- The platform manages the certificate and may change it at any time.

## Renewal not deployed

A **Renewal not deployed** line under the configuration card comes from the configuration alone: the store holds a newer certificate than the one the front end uses. It needs no scan, so it also shows on a declared service.

## Key custody

The endpoint page's **Key custody** card says where the served leaf's private key is held. It shows one of five values: **HSM**, **Software store**, **Held by the platform**, **Key file** or **Not known**.

The configured front end's own store speaks first. A private-key file the client scanner reported appears below it, as the scanner's report, never above a store's word.

**Not known** never says that a key file does not exist. It says why PQL cannot tell:

- The certificate is held in a store that no front end names.
- The certificate's public key was not reported.
- PQL cannot tell whether it is an end-entity or a CA certificate.
- The fingerprint is not an identity.

The Inventory's **Private key file** column says separately whether a key file was reported, so a copy in a file never hides behind a store's stronger custody.

## Reach

A certificate's page says how far it is known to be in use:

| Reach | What it means |
|---|---|
| *Served on N scanned endpoints* | A scan presented it. |
| *Declared on N front ends* | A front end a cloud source reads is configured with it. The line adds that this is declared, not measured. |
| *Configured on N front ends* | Shown instead on a claimed service PQL measured (scanned, imported or discovered) where no scan presented it. The line adds that no scan presented it. |
| *Stored only* | A store holds it, no front end PQL reads is configured with it, and no scan presents it now. The line is followed by what that store cannot show, such as app settings that PQL deliberately does not read. |
| *Not seen in use* | Every part of the strict rule below holds. |

A certificate declared by a front end whose partition has not been read completely since says *as last read on* followed by the day. A key's Reach is only ever through the certificate it is linked to.

### The strict rule behind "Not seen in use"

PQL says *Not seen in use* only when every one of these holds:

- The store's consumers are all visible to PQL. This is true only for Google load-balancer and Application Gateway certificates.
- The certificate's fingerprint and public key are both known.
- No consumer PQL read has referenced it for at least 14 days of complete reads, the latest within two sync intervals, and none failed or refused since.
- No completed scan in the last 30 days presented it, and no certificate served now shares its key.
- PQL has kept at least 30 days of scan history, and first read the certificate at least that long ago.

Any doubt, such as a host store or an older scan that may hold it, keeps the certificate at *Stored only*.

*Not seen in use* is a hint to look. It is never a reason to delete. Something PQL does not read may still use the certificate.

## Acknowledging a finding

A PKI Operator or a System Administrator can acknowledge either finding: **Renewal not served** or **Certificate not in the configuration**. Do this when the endpoint is known to sit behind a CDN, TLS inspection or another reason PQL cannot see.

1. Open the endpoint page and find the finding on the configuration card.
2. Acknowledge it and add a note. Line breaks are allowed; other control characters are not.

The card then says who acknowledged it, when and why. The source's card counts the endpoint as *acknowledged* rather than *differs*.

An acknowledgement binds to exactly what the page showed. If the endpoint or its configuration changed after the page was read, PQL refuses and asks you to reload.

It ends in one of four ways, and never applies again afterwards:

- A scan finds the endpoint presenting another certificate.
- A sync finds the configuration changed.
- 90 days pass.
- Someone withdraws it.

Either way, it stays in the history.

## On the source's card

A cloud source's card (see [Cloud discovery](../11-cloud-discovery.md)) splits what scans verified into five buckets: *match their configuration*, *differ*, *acknowledged*, *for information* and *not compared*. It also says how many certificates are **stored only**, and how many of those are *not seen in use*.

A count PQL could not read this time says *not known*, never zero.

**Show stored-only certificates** on the Inventory's Certificates view lists the stored-only certificates, each with the day PQL last read it. A store PQL has not read completely since keeps its rows as last read. They are never removed.

## In the Inventory

The Endpoints view has three columns with funnels (see [The Inventory](../03-inventory.md)):

| Column | Values |
|---|---|
| **Configuration vs scan** | The five buckets above. |
| **Key custody** | The five custody values above. |
| **Private key file** | *Reported*. |

An export made under one of these funnels (Excel, CBOM or a compliance report) covers only the rows the funnel selects. It carries no verdict of its own.

The Keys view adds a chip, **Backs a certificate no front end names**, for Key Vault keys whose certificate no front end PQL reads names.

## See also

- [Detail pages](../05-detail-pages.md)
- [Cloud discovery](../11-cloud-discovery.md)
- [The Inventory](../03-inventory.md)
- [Compliance](../09-compliance.md)
