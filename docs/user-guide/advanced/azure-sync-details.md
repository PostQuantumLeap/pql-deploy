# Microsoft Azure sources in detail

This page covers a Microsoft Azure (beta) source of Post Quantum Leap in depth: what the setup script creates in your directory, how its certificate is renewed, and what each sync reads and reports. It also explains how Azure's TLS front ends become declared services. Read it after connecting the source as described in [Cloud discovery](../11-cloud-discovery.md).

**Who:** System Administrator to connect and change a source. PKI Operator to watch it and press **Sync now**.

## What the setup script creates

The setup script runs in Azure Cloud Shell (Bash), as somebody who may create app registrations and assign roles on the scope. Run it as a file, `bash pql-azure.sh`, never pasted into the prompt. The script stops at its first error, and pasted line by line that closes Cloud Shell. It needs `jq`, which Cloud Shell has. It never writes to a vault, and in certificate mode it never creates a client secret.

### The app registration

The script creates an app registration for accounts in this organizational directory only. It is named *Post Quantum Leap key reader*, with the scope and a token unique to this source, so nobody can register that name first. The custom role gets the same name.

A later run reuses the app registration only while all of these hold:

- you are its only owner;
- it is limited to your directory;
- every credential on it is this source's own. PQL recognises its certificate by its bytes, never by a name.

Otherwise the script stops before assigning anything, and says why and what to do. For a credential that is not this source's, it prints the command that deletes it.

### Certificate or client secret

| Sign-in | What it means |
|---|---|
| **Certificate (recommended)** | PQL makes its own certificate for this source. Its private key never leaves the server. Only the public half goes to your directory, and no client secret is created. The script adds the certificate without replacing anything already on the app registration. |
| **Client secret (discouraged)** | For a directory whose app management policy refuses a self-signed certificate. The script makes the secret, valid for one year, and prints it once. PQL stores it encrypted and never shows it again. |

### The read-only role

The script assigns a custom **read-only role of twenty-two read actions** on the scope, and no data actions:

- nine for keys: management groups, subscriptions, resource groups, vaults, vault keys and their versions, Managed HSMs and their keys and key versions;
- thirteen for the TLS front ends: App Service's apps, slots, their settings and certificates; Front Door's profiles, endpoints, routes, domains and secrets (a certificate's reference, never a key's value); Application Gateways and public addresses; and API Management services.

None of them reads an app setting, a connection string, publishing credentials or a key. The script says what else the role reads.

If you may not create roles, the script assigns the built-in **Reader** instead and says so. Reader also reads every other resource's settings in the scope, and the name of every secret in every vault (never a value). A later run that can create the custom role removes that Reader assignment again.

### The data-plane role at a subscription

At a subscription, the script assigns a second custom role for the vaults' own endpoint (their data plane). It has two data actions:

- `Microsoft.KeyVault/vaults/keys/read`, so that the keys that back a certificate can be marked;
- `Microsoft.KeyVault/vaults/certificates/read`, so that the public part of a Key Vault certificate a TLS front end names can be read.

The role lists keys and certificates, never a secret. It would also let the app read each key's public half, and each certificate's public part and policy. It would let the app use an asymmetric key's public half in the vault's encrypt, wrap and verify operations, which is only what the public key allows anyway. PQL reads only the certificates a front end names.

The role is named *Post Quantum Leap Key Vault Reader (subscription …, source …)*. Despite its name, it is PQL's own role. The script never assigns Azure's built-in **Key Vault Reader**, which allows far more. Where it may not create this role, the script prints the optional command described next instead.

### Nothing for the data plane at a management group

At a management group, the script assigns nothing for the data plane, because Azure does not allow a custom role with data actions there. Two things then stay unknown: which keys back a certificate, and the public part of a Key Vault certificate a front end names. Both are neutral notes on the source, not errors.

The script prints one **optional** command an administrator may run to grant the built-in **Key Vault Reader** there instead. That role reaches far more:

- in every vault in scope, every certificate (never its private key), every key's public half, and every secret's name and attributes (never a value);
- every role assignment and definition in scope;
- it may create and update support tickets, and create and manage classic metric alerts.

Assigned at a management group, it can take hours to apply. Until it does, those vaults are read without the certificate mark.

### Access-policy vaults

Vaults still on the older **access-policy** model ignore data-plane roles. The script lists them and prints, for each, the one optional command an administrator may run (`az keyvault set-policy … --key-permissions list`). A TLS front end's certificate in such a vault needs `--certificate-permissions get` as well. The source's note prints that command, with the vault and its subscription filled in, once a front end needs it.

### Running the script again

For a certificate source, running the script again is harmless. It reuses what it made, and widens a role it made earlier (one with only the nine key actions) in place to the full set.

For a client-secret source, first delete the secret the earlier run made. A secret's value can never be read back, so the script cannot tell its own from anybody else's. It refuses the app registration and prints the command that deletes the secret.

A role you narrowed on purpose stops the script on the difference. To keep the role, run `PQL_SKIP_ROLES=1 bash pql-azure.sh`. This leaves both roles and their assignments exactly as they are.

A role assignment takes up to ten minutes to apply. A sync straight after the script may read nothing: Azure shows the source an empty scope until the role applies. The source says so in a note. Sync again shortly.

## Renewing the certificate

The certificate is valid for one year. Its thumbprint and expiry are under **Azure setup**. From 30 days before it expires, the source warns on its card and in Azure setup. To renew:

1. Press **Renew certificate** on the source. PQL makes a new certificate and keeps it **waiting**. The source goes on signing in with the current one. Azure setup opens with the new certificate.
2. Copy or download the one command Azure setup shows and run it in Cloud Shell: `bash pql-azure-renew.sh`. It uploads the new certificate's public half without replacing the current one, which keeps working meanwhile.
3. Press **Check it now** (the source has to be on), or wait for the next sync. A sync tries the waiting certificate first. Once Microsoft Entra accepts it, it becomes the one in use, and the old certificate's private key is destroyed. Until then the source says the renewal is waiting.
4. Azure setup then offers an optional command, `bash pql-azure-remove-old.sh`, that removes the old certificate from the app registration. The source never needs that certificate again. Run the command before you run the setup script again, because the script refuses an app registration that still carries a certificate that is not this source's. Run it also before the next renewal is in use: from then on, the command is for the certificate that renewal replaced, and nothing offers this one's again. **Renew certificate** reminds you while the command is still offered.

**Renewing again** before the waiting certificate is proven replaces it. The certificate that was waiting is never used, even if you uploaded it. If you did upload it, it stays on the app registration until you remove it. The setup script refuses the app registration until then, and prints the command.

**A client-secret source** has no renewal. Paste a new secret with **Replace secret** before the old one expires. Then delete the old secret from the app registration: it works until you do.

## What a sync reads

A sync reads these in turn:

1. **Keys.** Every key's **current version** in every vault in scope, through Azure Resource Manager. This works whatever a vault's firewall or private endpoints allow.
2. **Whether a key backs a certificate.** For each vault whose own endpoint answers, the sync checks whether each key **backs a certificate**. Key Vault makes a key for every certificate it holds. In the Keys view such a key carries a **Backs a certificate** mark, and an Azure key's source reads **Azure Key Vault**. The key's own page also says whether Azure reports it **enabled** and when it **expires**. These are facts shown as Azure gives them. Nothing grades or flags a disabled or expired key differently.
3. **The TLS front ends.** App Service, Front Door, Application Gateway and API Management, each on its own. See [TLS front ends and declared services](#tls-front-ends-and-declared-services).

## Partial syncs and notes

A sync is **partial**, with a warning, when something went wrong that is not a permission. That means one of these: Azure refused a vault's keys; the keys were not read at all while the front ends were; a front end's read failed; Azure asked the source to slow down while the front ends were read; or your tenant's service limit was reached.

A permission the source's role does not include is a neutral **note** beside a complete sync, never a warning. So is every other note below. A failed sync hides the note until the next sync completes.

| Message on the source | Kind | What it means |
|---|---|---|
| *N of M vaults could not be read* | Partial | Azure refused those vaults' keys. Their keys are kept as last read. The message names each vault and why, and for a refusal, the permission to grant. |
| *Keys not read: …* | Partial | The keys could not be read as a whole while the front ends were read: every vault refused, the scope was past one sync's limits, or no vault was found where keys were read before. The keys are kept exactly as last read. The message says why. |
| *App Service not read completely in 1 subscription; the services last read there are kept.* | Partial | A front end's read failed for a reason other than permission (named, in Azure's words), or Azure asked the source to slow down. What that part declared before is kept. |
| *App Service: not read …* | Note | The role does not include the action that surface needs, so it was not read. The keys and every other surface were. What it declared before is kept exactly as last read. One sentence per surface, naming the action and how to grant it. When none of the four is granted, the note reads *TLS front ends not read …* and names the thirteen actions **Azure setup** lists. |
| *App Service: TLS settings not read …* | Note | App Service was read, but the role does not include its TLS settings. Each app's TLS reads unknown. |
| *Certificate not read for N front ends …* | Note | A vault did not hand out the public part of a certificate a front end names. Each vault is named with its reason and the one command or role that grants the read. The front end is still declared. What was recorded for it before is kept. |
| *Certificate-backed unknown for N vaults …* | Note | The vault's own endpoint did not answer: a firewall, a private endpoint, no data-plane role (always at a management group, unless the optional Key Vault Reader command was run), or an access-policy vault. Every vault is named with its reason. Its keys are still listed, and a mark it gave before is kept. |
| *N Managed HSM(s) found; their keys are not read* | Note | Managed HSMs are found and named. Reading their keys is a later step. |
| *A renewed certificate … is waiting to be uploaded* | Note | See [Renewing the certificate](#renewing-the-certificate). |
| *The renewed certificate … is now in use* | Note | A renewal was proven and the old private key destroyed. Removing the old certificate is optional (step 4 above). |
| *Resource Graph found no Key Vault in …; a role assigned in the last few minutes may not apply yet* | Note | Only on a source's first sync. Azure answers a new role with an empty scope until it applies. Sync again shortly. |
| *Azure asked this source to slow down* | Throttled | During the sign-in or the key read. Nothing changed, and the sync tries again by itself. |

## A sync that reads nothing

A sync that reads nothing **fails**. It changes nothing and says why, in the words the keys gave. This happens when the keys were not read (see above) and no TLS front end was read either, for example because the role grants none of the four surfaces. A sync whose sign-in was refused fails the same way.

A scope that held keys, and where Azure now shows no vault, keeps its keys. Azure answers that way when the source's role was removed as well as when the vaults were deleted, so nothing is deleted on its word.

## Not read in this beta

- Older key versions. Only each key's current version is read.
- Soft-deleted keys.
- A vault's certificates as an inventory of their own. Only the one a front end names is read.
- The sovereign clouds (Azure Government, Azure China).

## TLS front ends and declared services

A source also reads the TLS front ends in its scope:

| Surface | What is read |
|---|---|
| **App Service** | Apps and their deployment slots. |
| **Front Door** | Standard and Premium custom domains. |
| **Application Gateway** | v2 HTTPS and TLS listeners. |
| **API Management** | Gateway host names. |

For each front end the source reads:

- the host names and ports it serves;
- its minimum TLS version and cipher policy, and whether anybody chose them or a platform default applies;
- Front Door's post-quantum key-exchange setting (a custom server TLS group policy listing ML-KEM groups);
- the certificate it is configured to present.

Each host name and port becomes a **declared** service, exactly as a Google load balancer's does. It is in the Inventory, and measured by the first scan that completes a handshake with it. **Rescan**, the schedule, an engine or a proxy dials it. See [Configuration versus scan](configuration-vs-scan.md) for what a declared service tells you, and [Planning in detail](planning-details.md) for how it is planned.

**Platform default host names.** A platform default host name (`*.azurewebsites.net`, `*.azurefd.net`, `*.azure-api.net`, a gateway's public address) is declared only when its front end has no custom name.

**Private front ends.** A front end reachable only privately, such as an app behind private endpoints or a gateway's private listener, needs a [Bifröst remote engine](../07-remote-engines.md) inside its network to be measured.

**On the source's card**, a **TLS front ends** summary counts what was read, surface by surface. One quiet line counts what could never be declared, such as wildcard names and domains not validated.

### Several front ends, one name

Microsoft's own guidance has Front Door, or an Application Gateway, and the App Service app behind it bind the same custom name. That is one service. The **Microsoft Azure configuration (beta)** card on its endpoint page lists every front end that declares it, outermost first: Front Door, Application Gateway, API Management, App Service. Each shows its TLS settings, its certificate and its post-quantum setting. Which of them a client reaches is decided by DNS, not by configuration, and the card says so. A scan records what is actually presented.

### Certificates recorded while declared

While a service is only declared, PQL records the chain of the certificate its **outermost** front end presents. It goes into the certificate inventory as the source's own, when its public part can be read:

- from Azure itself, for an Application Gateway's uploaded certificate or an App Service certificate where Azure hands it out;
- from the vault, for a certificate kept in Key Vault. It is read by exactly the name the front end names, and recorded only when it is the version the front end presents.

An inner front end's certificate is never recorded. That is what the origin shows the edge, not what clients see. A certificate Azure manages and renews (an App Service Managed Certificate, a Front Door managed certificate) is described, never recorded. A scan records the chain it presents.

A recorded certificate goes the way a Google source's does: it never puts the service into a figure, and it goes once a scan measures the service or the source no longer sees it, unless a person tagged it.

### When the role does not grant a surface

The source's note says so in one sentence per surface, naming the action and how to grant it: run the setup script again, or add the action to the role you gave the source. It is never a warning. The keys and every other surface are read, and the sync completes.

What that surface declared before is kept exactly as last read. It is never marked as not found, so it is never removed. A front end kept that way on a shared name says *Kept as last read on …* on the card.

A source whose role has none of the front-end actions gets a note saying all four are not read. Run the setup script again: it widens that role in place, and the next sync reads them.

When one or both of App Service's two TLS-settings actions are missing, App Service is still read. The TLS of the apps or slots they cover reads unknown.

### A known gap: Flex Consumption apps

The certificates a Flex Consumption app keeps itself are listed only for an app that binds a custom name with TLS. The permission that listing needs is not yet in the role the setup script grants, so running the script again does not add it. Where Azure refuses it, App Service in that app's subscription is kept exactly as last read, and the source's note names the permission.

### Narrowing on purpose

To give a source only some surfaces, remove the other surfaces' actions from its role. Then keep that role with `PQL_SKIP_ROLES=1 bash pql-azure.sh` whenever you run the setup script again. The switch leaves both roles and their assignments exactly as they are. Without it, a later run stops on the difference and says so.

### Claims and figures

- While the source is on, a service it declares cannot be deleted.
- A service a complete read no longer finds is marked as not found. 12 hours later it is removed or released.
- Deleting the source does the same at once.
- A service known only from cloud configuration is in no figure.

## Where it connects

The source connects to `login.microsoftonline.com`, `management.azure.com` and each vault's `<name>.vault.azure.net` (for the key list, and for each certificate a front end names). All of them on port 443, and all through your tenant's destination policy. Each source lists the host names it connects to.

## Removing a source

**Delete** removes the source and every key it read. It ends what the source declared, as deleting a Google source does: at once, without the 12 hours. A certificate source's private key is destroyed with it. The confirmation names the certificate to remove.

What the script made stays in your directory. To clean up:

- remove the certificate (or the secret) from the app registration, or delete the app registration;
- delete the custom roles if nothing else uses them.

## See also

- [Cloud discovery](../11-cloud-discovery.md): connecting Google Cloud and Microsoft Azure.
- [Configuration versus scan](configuration-vs-scan.md): what a declared service tells you.
- [Remote engines](../07-remote-engines.md): measuring front ends PQL cannot reach.
- [Inventory](../03-inventory.md): where declared services and keys are listed.
- [Planning in detail](planning-details.md): how declared services are planned.
