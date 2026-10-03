# Planning in detail

This page covers the rules behind the Planning pages of Post Quantum Leap: how the Roadmap zooms, how **Let PQL draft it** builds cohorts and waves, how the Cohorts tab counts, and how services known only from cloud configuration are planned. Read it when [Planning](../10-planning.md) does not answer your question.

**Who:** PKI Operator and System Administrator plan. Readers view.

## The Roadmap view

**Planning → Roadmap** draws the waves' timeline and the *Risk against appetite* chart on one shared year axis. A year sits at the same place on both. The **Plan**, **5 years** and **10 years** buttons above the timeline zoom both at once.

- **Plan** (the default) starts at the start of this year. It ends with the year after the last wave date, or the year the plan gets inside appetite, whichever is later. With nothing to fit yet, it shows four years.
- **10 years** never runs past the exposure projection. The chart says so when it stops short.

A wave outside the view is listed as text instead of a bar: "Ended before this view" or "Starts after this view". When the plan runs past the projection, the chart says where its curves stop. The curves are drawn rounded, but they pass through every year's value and never swing past one. A plan that falls to zero never dips below it.

## Let PQL draft it

**Let PQL draft it** is on **Planning → Waves**. It works in two steps: proposed cohorts, then waves. Nothing is saved until you apply them.

### Step 1: proposed cohorts

PQL proposes cohorts from the measured services that are not ready under your policy and are in no cohort with rules yet. Services waiting in **Everything else** are included. A declared service does not shape a group, but a proposed rule may still match one (see [Services known only from cloud configuration](#services-known-only-from-cloud-configuration)).

PQL groups the services in this order:

1. **Self-signed certificates first.** All of them are one proposal, **Self-signed certificates**. It is split by key type when it holds more than a quarter of these services. While there are fewer self-signed services than the smallest group, they wait in **Everything else** instead.
2. **Issuing CA and key type.** The rest is grouped by issuing CA and key type, the CA by its own name: "RSA-2048 certificates from Corp Issuing CA 2019".
3. **Large groups are split.** A group holding more than a quarter of these services is split once more. PQL splits it by the domain or another fact a service has one of, whichever cuts it most evenly.
4. **Small groups are merged.** Smaller groups that share a CA or a key are merged, a CA's first. The merged group is named for the CA and its other keys.
5. **Everything else.** The rest goes to **Everything else**. It is ticked when a service not yet ready would wait there. A declared service counts. With nothing to propose and no such service waiting, applying creates nothing.

The proposals never overlap each other.

Four settings are on screen:

| Setting | Default | What it does |
|---|---|---|
| The smallest group | 3% of these services, at least 3 | The smallest group PQL proposes. |
| Cohorts | at most 10 | The most cohorts PQL proposes. |
| Overlap guard | 10% | When more than this share of a proposal's services is already in your cohorts (all of them together; Everything else does not count), the proposal starts unticked. It says how many, and which cohort holds the most of them. |
| What to split on first | | The fact the first groups are made on. Choose **Issuing CA group** to plan a public CA as one group (see [Issuing CA groups](#issuing-ca-groups)). |

Untick **Split a group over a quarter of these services once more** to keep every group whole.

With each proposal you can:

- tick or untick it;
- rename it;
- **Split by …** to split it on a fact;
- **Undo split** on any part, PQL's split or yours;
- **Merge into Everything else**.

A service whose certificate key could not be read, or a client scanner's key store, is listed as *could not be judged*.

### Step 2: waves

PQL puts your cohorts, and the proposals you kept, in order:

1. the highest risk first;
2. then the earliest break;
3. then the most services still to migrate.

Three rules apply:

- A cohort whose every service is already ready is left out as already migrated.
- A wave takes no new cohort from its end date on. The board says "Ends today" on that day and "Ended" after it.
- No wave is dated before this month.

### Apply and Undo

Applying creates the ticked cohorts, then places them in waves. **Undo** on the Waves board removes both.

## Issuing CA groups

Each issuing CA is its own group, by name. Let's Encrypt's R10 and R11 are two groups ("RSA-2048 certificates from Let's Encrypt R10").

To plan a public CA as one group, whichever of its intermediates signed, choose **Issuing CA group** as what to split on first. The group is then "EC P-256 certificates from Let's Encrypt", however often the CA rotates E5, E6, R10 and R11. **Issuing CA group** is in the cohort builder as well, and a cohort made with it keeps working.

What counts as public: PQL knows a CA is public when the certificate's chain ends on a root in the Mozilla trust store. The scanner completes a chain with that root.

- A CA of your own stays its own group, even beside another CA of the same organisation.
- A public CA whose chain PQL cannot follow that far yet is grouped by its intermediate until a later scan does. The same holds for a leaf served alone, and for a PEM import, which stores only the one certificate given.

A client scanner or CBOM submission is a key store: many certificates, none of them one a service presents. PQL proposes no rule for it. It is listed as *could not be judged* and waits in **Everything else**. A host whose issuer was never captured is proposed *with no issuing CA recorded*.

## Self-signed certificates

A self-signed certificate has no CA to re-issue it. PQL proposes one cohort of self-signed certificates once there are enough of them, as many as the smallest group. Its rule is "Self-signed is Yes". No other proposal ever holds one.

- An issuing CA group's rule ends with "Self-signed is not Yes" only while the estate holds a self-signed certificate.
- A merged group's rule (a CA's other keys, and its like) always ends with it, even before the estate holds one. A certificate scanned later can then never slip into the group.
- Groups split first on a domain, protocol, business service or label always carry it too, for the same reason.

Self-signed means the certificate a service presents is signed by its own key. PQL checked this when it read the certificate. It is never guessed from the name. **Self-signed** is a cohort attribute too: Yes or No.

## The Cohorts tab counts

**Planning → Cohorts** counts the services three ways above its cards. Declared services are included.

| Count | What it means |
|---|---|
| **In a cohort** | At least one cohort holds the service, *Everything else* included. A service in two cohorts counts once. |
| **In a dated wave** | A cohort holding the service sits in a wave whose end date is still ahead. The exposure curve on the Roadmap credits such a wave. A wave with no end date, or one that has ended, adds nothing here, as it adds nothing to the curve. |
| **In none** | No cohort holds the service, so no wave can cover it. The Roadmap's *Needs attention* counts the same services. |

A service in more than one cohort is counted once on the curve and once per cohort on the Waves board.

*Suggested by PQL*, on the Cohorts tab, lists first the suggestions that cover the most services no cohort with rules holds, those waiting in **Everything else** among them. It offers no key-exchange groups: nearly every host offers several, so a cohort of one would overlap most of your estate.

## The "In no cohort" panel

When any service is in none, the **In no cohort** panel lists them: the first 500, as many as one pick can hold, the services not yet ready under your policy first. Beside them are up to three cohorts PQL would make for them, its proposals one level deep (see [Let PQL draft it](#let-pql-draft-it)). A proposal is not offered when more than the overlap guard's share (10%) of its services is in your cohorts already. Everything else does not count.

| Button | What it does |
|---|---|
| **Create this cohort** | Opens the cohort builder filled in with the proposal. |
| **Pick selected as a cohort** | Tick services in the list first. Opens the builder with them as *Selected services*. |
| **Sweep the rest into “Everything else”** | Creates *Everything else* from the remainder at once. |

A service on port 0 (a client scanner's key store or an imported file, where nothing was dialled) has no port to pick it by. It is listed but cannot be ticked. A rule on its host catches it. A key store has no key type and no issuing CA, so no rule that asks for either selects it.

A service only *Everything else* holds is in a cohort. Once *Everything else* exists, nothing is in none. The panel then lists what only *Everything else* holds instead, as **Only in “Everything else”** (under whatever name you gave it). It offers the cohorts PQL would make for them and **Pick selected as a cohort**, but no sweep. The panel goes away when *Everything else* holds nothing.

## Everything else

*Everything else* holds the services that no cohort with rules holds. Services a later scan finds land there, and you can keep giving them cohorts with rules. **Let PQL draft it** proposes cohorts for the same services and places them in waves.

In the plan, *Everything else* moves whenever another cohort is created, changed or deleted. PQL dates each such move as it dates a rule edit: the cohort's page compares today's count with the last move, not with the day it was tracked.

An *Everything else* that holds nothing is the goal: every service has a cohort of its own. The Roadmap's chart does not count it as a plan item that matched nothing.

## Services known only from cloud configuration

A Google Cloud (beta) or Microsoft Azure (beta) source reads the TLS configuration of your load balancers or TLS front ends, as well as your keys. Each host and port they serve is listed in the Inventory as **Declared (cloud)** until a scan completes a handshake with it. See [Cloud discovery](../11-cloud-discovery.md) and [Configuration versus scan](configuration-vs-scan.md).

Such a service is in no figure. The Overview, grades, compliance packs, scan history and the board deck's figure slides count only what was measured. It is in your plan, marked **Declared, not measured**.

- **Clusters, cohorts and Everything else include it.** A cluster or cohort that holds declared services says how many ("includes 3 declared, not measured"). In its member list each one wears the mark and says what it is planned from: the minimum TLS version its configuration allows, and the key of the certificate it is configured with. The TLS version comes from the load balancer's SSL policy or the front end's configuration. It is flagged when it is a default nobody chose. A service whose certificate PQL could not read (a Google-managed certificate, or an Azure certificate its vault did not hand out) is planned without one.
- **Every ready figure counts measured services only.** A declared service is never in "3 of 6 ready" or "55% complete". Its count stands beside the figure ("· 4 declared, not measured"). A wave or cohort of declared services alone has no Complete figure. Its badge reads the item statuses instead ("no measurement").
- **In no cohort lists declared services too**, marked. You can pick them by host and port like any other service.
- **Lowest TLS version** is a cohort attribute for every service: the oldest version a scan saw a service accept, or a declared service's configured minimum. The example cohort *Still accepting TLS 1.0 or 1.1* selects both.
- **Let PQL draft it** proposes its cohorts from what was measured. A proposed cohort's rule still selects every declared service it matches. Once Everything else is ticked, or the tenant already has it, the rest wait there. Otherwise they stay in no cohort until it exists. The draft counts them as work still to do either way.
- **Risk against appetite** counts declared services and lists them apart. Their configuration states no key exchange, so the exposure curves do not score them until a scan measures them.
- **The wave workbook** lists them on its Tracking sheet, where their Ready cell says "Declared, not measured". It counts them on its Wave sheet. On its Cohorts sheet, each rule's own declared count sits in a "Services declared, not measured" column beside its ready count.

When a scan completes a handshake with a declared service, it becomes measured. The mark goes, and it is planned from what the scan found. A failed scan leaves it declared. A plan item tracked before a declared service joined it says so: the cluster or cohort page's drift sentence adds "(includes N declared, not measured)" after whichever count has any, the one when it was tracked or the one now.

## See also

- [Planning](../10-planning.md): cohorts, waves and the Roadmap.
- [Cloud discovery](../11-cloud-discovery.md): connecting Google Cloud and Microsoft Azure.
- [Configuration versus scan](configuration-vs-scan.md): what a declared service tells you.
- [Microsoft Azure sources in detail](azure-sync-details.md): how TLS front ends become declared services.
- [Inventory](../03-inventory.md): where declared services are listed.
