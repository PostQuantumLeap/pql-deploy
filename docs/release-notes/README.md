# Release notes

What changed in each release of Post Quantum Leap, and what to do before you
upgrade. One file per release, newest first.

| Release | Date | Notes |
|---|---|---|
| 3.4.1 | 29 September 2026 | [3.4.1.md](3.4.1.md) |

Release notes are public from 3.4.1 on. Earlier releases have no public notes.

## What each note covers

- **What changed**: new capabilities, changes to existing behaviour, fixes.
- **Before you upgrade**: anything that needs a decision or a step on your side, such as a setting to review or an order in which to upgrade engines.
- **Known issues** in that release, where there are any.

## Upgrading

The mechanics are the same for every release and are described once, in the
[Installation guide, section 6](../../README.md#6-upgrading): pull the new
image, start it, and the migrations run in place. If you pinned `PQL_IMAGE`,
change the tag first. Read the note for the release you are moving to before
you do.

## Where releases are published

| What | Where |
|---|---|
| Container image | `ghcr.io/postquantumleap/pql-app:<version>`, the versions listed at [packages/pql-app](https://github.com/orgs/PostQuantumLeap/packages/container/package/pql-app) |
| Offline kits, one per architecture | The [releases page](https://github.com/PostQuantumLeap/pql-deploy/releases) of this repository |
| Helm charts | `deploy/helm/pql` and `deploy/helm/pql-remote-engine` in this repository |
| The running version | The **About** page in the product |
