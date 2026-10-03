# Bifröst remote engines in detail

This page covers the day-to-day running of a Bifröst remote engine once it is deployed and connected to Post Quantum Leap (PQL). It explains how to read the engine's row in the table, give it work, diagnose problems, keep it up to date, and re-issue or delete it. What an engine is and the eight-step setup are in [Remote engines](../07-remote-engines.md).

**Who:** PKI Operator to set up an engine and assign it work. Re-issuing the credential, revoking, deleting, and pushing TLS material to an engine are a System Administrator's job.

## The relay option

Step 4 of the setup, **Relay**, stays off unless client scanners in that network segment are to report through the engine. With it on, you set the port, the address those hosts dial, the interface to publish it on, and how its TLS is terminated.

## Re-issue and Rename

Both sit in a row's ⋯ menu.

**Re-issue** runs the same wizard for an engine that already exists. The name is locked, and the recorded runtime and relay address are filled in. For Kubernetes, the Helm release and namespace it was installed as are filled in too, and the **Update** dialog's commands use the same values. Re-issue replaces the credential, so it strands the running container until you deploy what it gives you.

**Rename** changes only what the row is called. Anything already deployed keeps the names it was deployed with.

## Reading the table

| Column | What it tells you |
| --- | --- |
| **Status** | Connected, not connected, never connected, revoked or expired. Liveness comes from the engine's own connection. PQL never probes it. |
| **Link** | `stream` is normal. `polling fallback` means something between the engine and PQL is interfering with its connection, usually a proxy. Scanning still works, dispatch is slower. This is not an engine fault, and it is the most useful thing the table can tell you. |
| **Version** | The engine's build, and the fingerprint of the scanning code its image carries. The fingerprint is what matters: if it differs from this server's, the engine is measuring with older code. |
| **Targets** | How many services this engine is responsible for. Look at it before you delete an engine. |

Under the version sits the engine's update situation:

- whether it is current,
- whether a newer build exists, and which one,
- what the engine does about updates on its own,
- and, if it has failed on a build, which one and why.

The state to act on is *Too old* (receiving no work). It reads differently from *Update available* because the consequence is different: that engine is being handed nothing at all, rather than doing work with older code. It stays connected and keeps shipping its log, so you can still see why.

## Giving it work

| Scope | How |
| --- | --- |
| One target | Set the *Remote engine* field in the target editor, beside *HTTP proxy*. Leave it empty and PQL scans the target itself, which is the default and what every existing target does. |
| Several targets | Tick them in the inventory and use the bulk action. |
| A whole subnet | Point **Network range** (on Sources → Direct scanning → Add) at the engine. This is often the real reason to deploy one: PQL cannot map a range it cannot reach. |

## When something goes wrong

### Logs

Every engine's log is one click away from its row. Filter it by level, and by job, scan or host. This is how you diagnose a failed scan on a machine you have no shell access to. Credentials are masked before anything is stored.

### An engine that stops answering

Its queued work waits. After an hour PQL gives up and records those targets as *remote engine did not respond*. That is accurate: a target only reachable through a dead engine is not reachable. PQL never guesses, and it never scans those targets from this server instead.

## Keeping engines up to date

The **Update** button asks; it does not command. Whether an engine acts is decided on the engine, by a setting in its own `.env` file. The table shows that setting beside the version, and PQL cannot change it. This is deliberate: a server that could make a container in your network replace its own code would hold a lot of power over your network.

There are two cases, and the table tells you which one you are in:

| Setting shown in the table | What **Update** does |
| --- | --- |
| `drains and restarts itself` | Clicking **Update** is enough. The engine finishes the work it is holding, exits, and its container platform brings it back on the new build. It waits a random few minutes first, so a fleet does not all restart at once. |
| `reports updates, applies nothing` (the default) or `never updates itself` | Clicking **Update** records the intent and tells the engine. Then you redeploy the container yourself. The confirmation says so. |

### Failed builds

An engine that fails to come up on a build reports that, and PQL stops offering that build to it. Otherwise it would restart into the same failure forever. The table shows the version and the reason. Once you have fixed the cause, click **Update** to clear it.

## Re-issuing the credential

Re-issuing stops the running engine immediately. It is the only way to produce a new deployment package, so plan to deploy the new one straight away. The wizard's **Review** step says so before it acts.

## Deleting an engine

Its targets go back to being scanned by this server. If the engine existed because this server cannot reach them, they become unreachable. The confirmation says that too.

## The two kinds of proxy

They are easy to confuse, and the failure looks identical to a broken credential:

| Proxy | What it is for |
| --- | --- |
| An **HTTP proxy** on a target | How a scanner reaches that target |
| An engine's **uplink proxy** | How the engine reaches PQL |

One engine can have both, pointing at different machines.

## See also

- [Remote engines](../07-remote-engines.md): what an engine is and the eight-step setup.
- [Client scanners in detail](host-scanner-details.md): schedules and trust flags for scanners that report through an engine's relay.
