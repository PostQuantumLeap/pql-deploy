# The DORA report

This page explains what the DORA report in Post Quantum Leap measures, which findings can fail, and which parts of the regulation it does not assess. Read it before you quote one of its figures to an auditor or a competent authority.

**Who:** every signed-in role (Reader, PKI Operator, System Administrator) can view it.

## Where to find it

Open **Compliance** and find the DORA card. The card shows the headline figure and a short explanation of what the report measures. **Open report** opens the per-endpoint breakdown, and **Excel** exports it. See [Compliance](../09-compliance.md) for how every report is laid out.

## What it is

DORA, Regulation (EU) 2022/2554, is binding. It has applied directly in every Member State since 17 January 2025, with no national transposition. The RTS that carries its cryptographic content, Commission Delegated Regulation (EU) 2024/1774, is equally binding.

That is the difference from the [FINMA report](finma-05-2026.md), and the reason this report has rules that can fail.

DORA itself names no algorithm, key size, protocol, interval or deadline. It states principles:

- high standards of confidentiality at rest, in use and in transit (Article 9(2));
- the security of the means of data transfer (Article 9(3)(a));
- encryption based on an approved data classification (Article 9(4)(d)).

Everything concrete is in Articles 6, 7 and 14 of the RTS.

The card's edition line names both instruments. The RTS alone would be a supplement without its parent. DORA alone contains none of the rules.

## What can fail

Only classical defects can fail. Each rests on an article of the RTS:

| Rule that can fail | Rests on |
|---|---|
| SSL, TLS 1.0 or TLS 1.1 offered | Article 14(1)(a). It obliges you to ensure the confidentiality, authenticity and integrity of data in transit, and to have procedures that assess this. That is an outcome, not a policy. |
| NULL, anonymous, export, RC4, DES or 3DES cipher accepted | Article 14(1)(a), read with the leading practices and standards that Article 6(3) calls for. |
| SHA-1 or MD5 certificate signature | Article 14(1)(a). A signature is about authenticity and integrity, and the article names both. |
| No forward secrecy | Article 14(1)(a). Without forward secrecy, a session's confidentiality ends the day the long-term key does. |
| RSA below 2048 bits, or EC below 256 bits | Article 6(3), which requires selection criteria that take leading practices into account. The RTS states no key length anywhere. The numbers are PQL's own reading, and they are deliberately the same floors the NIST, PCI, FIPS and MAS reports use. |
| An expired certificate in use | Article 7(5), which requires the prompt renewal of certificates before they expire. No other report carries this check. It is the one rule with no inference step at all. |

So the headline reads **Endpoints free of classical crypto defects**, not "endpoints conforming". The wording is deliberate. Three of DORA's five chapters yield no rule at all, so the report does not produce a DORA compliance rate, and cannot.

## The quantum rules only warn

Every quantum rule warns. None can fail.

The crypto-agility duty is Article 6(4) of the RTS. It obliges a provision in your policy for updating or changing cryptographic technology as cryptanalysis develops. It names no algorithm. Neither DORA nor the RTS names a post-quantum algorithm, date or deadline anywhere. The word "quantum" appears once across both texts, in Recital 9 of the RTS, which asks for a flexible approach based on risk mitigation and monitoring. That is the opposite of a deadline.

An entity with an approved agility provision and a wholly classical estate satisfies Article 6(4) completely. Grading it non-compliant against binding EU law would mean PQL inventing an obligation.

Expect the certificate-key rule to fire on nearly every endpoint. No public CA issues ML-DSA certificates yet, so "certificate chain carries quantum-vulnerable public keys" is true of virtually everything you own. That is not a defect list. It is the population that the mitigation-and-monitoring duty in Article 6(4) attaches to, which is exactly why it warns.

## The two label rules

Article 6(3) of the RTS requires your selection criteria to take into account the classification of ICT assets under Article 8(1) of DORA. Article 6(2) rests the whole encryption policy on an approved data classification. So two rules read your own governance labels (see [Governance attributes](../12-governance.md)):

| Rule reads | Fires on the values |
|---|---|
| The criticality attribute | Critical or High |
| The data sensitivity attribute | Confidential or Strictly confidential |

Each rule names the label it read. Neither claims to have found a "critical or important function". That is a legal term defined in Article 3(22) of DORA, and a dropdown value is not one.

An endpoint with neither label is reported as *not measured* on these two rules, not as passing them. Its row in the per-endpoint evidence says which label is missing. On an estate with no labels, both rules fire on nothing.

## The 90-day refresh finding and the register

Article 7(4) of the RTS requires a register of all certificates and certificate-storing devices. It covers at least the ICT assets that support critical or important functions, and you must keep it up to date. The PQL inventory is that register.

"Record not refreshed for over 90 days" is therefore a defect in the inventory, not in the endpoint. You clear it with a rescan, not a fix.

The 90 days is PQL's own figure. The RTS states no interval. It matches the FINMA report's figure, so one record can never be fresh in one report and stale in the other.

## What is not assessed

Three of DORA's five chapters are not assessed at all. The report says so. It does not score them green.

| Chapter | Why a scan cannot assess it |
|---|---|
| Chapter III, ICT-related incident management and reporting (Articles 17 to 23) | Classification thresholds, report timelines and supervisory notifications. Nothing a scan can see. |
| Chapter IV, digital operational resilience testing (Articles 24 to 27), including threat-led penetration testing | A test programme with a scope, a frequency and an accredited external tester. A handshake is not a test programme. |
| Chapter V, ICT third-party risk (Articles 28 to 44) and the register of information | Contractual and organisational: mandatory contract clauses, exit strategies, and a register filed with your competent authority. Beyond the documents, the subject itself is missing, not only the measurement. A scan cannot tell an outsourced endpoint from an in-house one. Your own data centre and your cloud provider present the same handshake. An imported asset is most often your own key store, not a supplier's. A CA in the trust path is a trust anchor, not an outsourcing arrangement. |

Most of Chapter II is out of scope for the same reason. These articles are documents, committees and board approvals:

- Articles 5 and 6, governance and the risk management framework.
- Articles 10 to 14, detection, response, recovery, backup, learning and communication.
- Article 16, the simplified framework, which depends on your size and risk profile.

From the RTS, Article 7(1) to 7(3) cover the key lifecycle, the controls that protect keys, and how a compromised key is replaced. These are procedures over private key material that PQL never sees. Only Article 7(4) and 7(5) reach an inventory, and both have rules.

## The completeness caveat

No scanner can measure the completeness of its own inventory. "No classical defects: 100%" over a partially discovered estate is true and worthless at the same time. The same caveat applies to every other report on the Compliance page.

## See also

- [Compliance](../09-compliance.md)
- [Governance attributes](../12-governance.md)
- [The FINMA Guidance 05/2026 report](finma-05-2026.md)
