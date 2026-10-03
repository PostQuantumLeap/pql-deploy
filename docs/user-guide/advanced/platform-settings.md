# Platform console: settings in detail

What each control in the Post Quantum Leap Platform console does, what to choose, and
what happens when you change it. Read [Platform console](../14-platform-console.md)
first for the overview.

**Who:** Platform administrator. The sections on resetting someone's sign-in and on
platform support access also concern a tenant's System Administrators.

## Who can reach it

Only an account that holds the platform-administrator flag. The flag is not a fourth
role: a role is held inside one tenant, the flag over every tenant the installation
hosts. The strongest System Administrator of a tenant cannot reach any of the console.

The console shows nothing that belongs to a single tenant. If you also belong to one,
a control in the header takes you into it, and **Back to Platform console** at the foot
of the tenant's rail brings you back. The screen always says which mode you are in.

## Tenants

One row per tenant: kind, status, how many users and services it holds, its
capabilities, where it may connect, and when it was created.

| Control | What it does |
|---|---|
| **New tenant** | Creates a tenant from a preset and shows every value the preset will stamp before anything is created. A preset stamps values; it is not a mode, and nothing afterwards remembers which one was used. |
| **Members** | Manages that tenant's people, including handing a new tenant its first administrator. That is the recovery path that needs no approval. For somebody who uses passkeys it offers **Reset sign-in…** (below), including for people who also work in another tenant. Suspending is refused on yourself, and on the last platform administrator who can still sign in. |
| **Edit** | Changes the tenant's limits and capabilities one at a time. It also holds *Active/Disabled* and the isolation switch (below). Disabling stops sign-in and keeps every row. |
| **Request access** | Asks that tenant for time-boxed administrator access (below). It grants nothing by itself. |

Deleting a tenant removes its data and its audit trail with it.

## Administrators

Who administers the installation: the account, when it was added, and when it last
signed in.

| Control | What it does |
|---|---|
| **Add administrator** | Searches accounts that already exist on this installation and grants the flag. It is not an invitation form: the account must already sign in here. Bring somebody new in through a tenant's **Members** dialog first. |
| **Setup link** | Issues a one-time password link for another administrator. It is the only route that can, which is why a tenant's **Admin** page refuses to reset a platform administrator and says *only another platform administrator can change its credentials*. For an administrator who uses passkeys, the row offers **Reset sign-in…** (below) instead. |
| **Remove** | Clears the flag and nothing else: the person keeps every tenant role they hold. Refused on yourself (a peer can do it for you), and when no other administrator could still sign in; a suspended one does not count. An installation with nobody able to sign in cannot appoint anyone. |

Your own row offers neither **Setup link** nor **Reset sign-in…**. Use your recovery
codes, or ask another administrator.

## Scan history maximum

- **What it does:** sets the longest scan history window any tenant may keep. A tenant
  can set less, never more. A tenant that states no retention of its own runs on this
  number.
- **What to choose:** the longest window you are prepared to keep for any tenant.
- **When you change it:** lowering it shortens every tenant above the new value and
  deletes history that cannot be recovered. PQL previews the change and audits it.

## Where a tenant may connect

- **What it does:** sets the installation's default allowed ports and blocked prefixes.
- **What applies whatever you choose:** a built-in floor binds any tenant that has
  "block private networks" switched on. Loopback, link-local and cloud metadata
  addresses are refused for every tenant.

## Passkeys

This card decides whether local accounts use passkeys, and what a recovery code lets
someone do. What each choice means for a user is in
[Passkeys and recovery codes](passkeys-and-recovery.md).

### Before you can choose

- Until the server is configured for passkeys (see the Installation guide), the card
  says so and nothing else.
- When the server is configured with an IP address instead of a DNS name, or you
  opened the console at an IP address, the card says *Passkeys need a DNS name and
  HTTPS*. Browsers never use passkeys at an IP address, so passkeys stay off and
  everyone signs in with their password.
- Once the server is configured, a banner on the console's other pages says passkeys
  stay off until somebody chooses. **Choose in Settings** brings you here. Saving any
  choice ends the banner, *Off* included.

### Whether local accounts use passkeys

| Choice | What it means |
|---|---|
| *Off* | Asks nobody. |
| *Optional* | Asks at every password sign-in and never requires a passkey. |
| **Required once set up (recommended)** | Somebody who has set up a passkey and saved their recovery codes can no longer sign in with a password alone. |

When you change it, tightening signs those people out of their other sessions, and
loosening tells them their password works on its own again. Nothing is deleted either
way. Saving asks you to confirm it's you. While anybody uses passkeys, loosening needs
one of your passkeys or single sign-on: a password alone is not enough to switch their
protection off.

### When someone signs in with a recovery code

| Choice | What their password and a code let them do |
|---|---|
| **Require a new passkey (recommended)** | They must set up a new passkey on that device, then save a new set of codes. Where a passkey cannot be set up, the code is not used and they are sent to the installation's address, or to an administrator. A code never gets anybody in without a new passkey, and nothing is paused afterwards. |
| **Allow one sign-in without a passkey** | They may set up a passkey or sign in once without one. For 3 days some changes to their sign-in are paused unless they use a passkey they had before. |

Choose **Require a new passkey** unless people use devices that cannot hold a passkey
(a remote desktop, no phone, no security key) and would otherwise need an
administrator for every lost passkey. Switching to **Allow one sign-in without a
passkey** while anybody uses passkeys needs the same confirmation as loosening: one of
your passkeys, or single sign-on. Switching back tells nobody and ends no pause already
running.

### What else the card shows

- Counts: who uses passkeys, who needs one to sign in, who holds passkeys only for
  another address, and who is in a recovery's cooling-off.
- A request to confirm the certificate is one browsers trust, when PQL cannot tell.
- Warnings: addresses that disagree, sign-ins from addresses that are not configured,
  and only one platform administrator who can sign in.

## Isolated tenants

- **What it does:** locks a tenant down so that its members belong to it and to
  nothing else. Nobody who belongs to another tenant can be added to it, and nobody in
  it can be added to another tenant.
- **Where:** **Tenants → Edit** for that tenant, next to *Active/Disabled*.
- **When you turn it on:** PQL shows who would have to be removed first, each account
  and where else it belongs, and refuses until they are.
- **When you turn it off:** never refused. Break-glass is unaffected either way:
  platform support still has to be requested and approved by the tenant itself, and
  still expires.

It is a rule about people, not about data: every tenant's records are already kept
apart from every other's, isolated or not. The second half of the rule is what makes
the promise hold. A member who gained a second tenant would hand that tenant's
administrator a password reset over the account that signs in here.

## SSO providers

- **What it does:** adds one login button per enabled provider. Local sign-in stays
  available beside them. An account that requires a passkey still needs its passkey, or
  its password and a recovery code.
- **What to choose:** the tenant each provider signs people into. *Installation-wide*
  puts them in the primary tenant. A named tenant makes the provider that customer's
  own: their staff sign in through their own directory and land in their own tenant.
- **When you change it:** you cannot. The binding is fixed once the provider exists,
  because changing it would leave everybody it had already signed in behind.

Three rules apply, and each shows up as a refusal:

1. **One app registration, one tenant.** A second provider with an application
   (client) ID already in use is refused. Otherwise one tenant could point at
   another's directory and collect its people.
2. **A session works where its credential reaches.** Signing in through a provider
   gets you the tenants that provider signs you into. A tenant you hold with a local
   password, or behind a different provider, is not offered in the switcher on that
   session: sign in again the way that tenant expects. The reverse holds too: a
   password or passkey sign-in reaches only the tenants you sign in to locally.
3. **No provider signs in somebody who uses a passkey.** A provider that asserts the
   address of a local account holding passkeys is refused, whichever provider it is.
   A generic OIDC provider must also mark the e-mail address as verified, or its users
   are told the provider did not send an e-mail address.

## Resetting someone's sign-in

For somebody who uses passkeys, **Reset sign-in…** takes the place of **Reset**. The
dialog is the same in three places: a tenant's **Admin → Users and roles**, a tenant's
**Members** in the Platform console, and the console's **Administrators**.

1. **Why are you resetting it?** Nothing is preselected. *Lost their passkey and
   recovery codes* removes their passkeys and codes and keeps their password. *Forgot
   their password* issues a password setup link and also removes their passkeys and
   codes, which you may untick; a passkey somebody else planted would otherwise
   survive the reset. *Account may be compromised* does both.
2. **Confirm it's really them.** Call them back on a number you already have, or ask
   in person. Do not act on an e-mail or a chat message alone: whoever controls their
   mailbox would otherwise be handed the account. The reset does not go ahead until
   you tick *I confirmed it's really them*.
3. Add an optional **note** of up to 200 characters. It is kept in the audit trail.
4. **Reset sign-in.** Every session they had ends. A setup link is shown once and
   lasts seven days. They are told who reset their sign-in.

### Who may reset whom

- Nobody resets their own sign-in.
- A tenant's own **Admin** cannot reset an SSO account or a platform administrator.
- Somebody who also works in another tenant can only be reset by a platform
  administrator.
- Taking a passkey off somebody else's account needs a stronger **Confirm it's you**:
  one of your own passkeys, or single sign-on. A password is not enough: an
  administrator who signs in with a password alone is refused and pointed at a
  platform administrator or at the server's recovery command.
- The same stronger confirmation applies to adding a System Administrator, and to
  changing the tenant's SSO providers, while anyone in the tenant uses a passkey.

## Platform support access (break-glass)

**Request access** on a tenant's row asks that tenant for time-boxed administrator
access to it. It grants nothing by itself. The tenant's System Administrators find the
request at the top of **Admin → Users and roles**. What they see and control:

- Nothing is granted until a tenant administrator approves. Until then the request is
  visible and useless.
- They see your reason exactly as you wrote it, not a summary.
- They choose the window, 1 to 72 hours, when they approve.
- The grant ends by itself. Any administrator of the tenant can end it early with
  **End access now**, not only whoever approved it. Your session stops working on its
  next request.
- **Refuse** removes the request and grants nothing.

An approved grant is an ordinary membership with an expiry, so it appears in the
tenant's Accounts list like any other member for as long as it lasts. Recovery is
outside this gate: adding or resetting an administrator for a tenant that has locked
itself out reads none of its data and needs no approval. Break-glass is about reading
the tenant's inventory, which is the thing the tenant may refuse.

## See also

- [Platform console](../14-platform-console.md)
- [Admin](../13-admin.md): Users and roles, **Reset**, and the break-glass request
- [Signing in](../01-signing-in.md)
- [Your account](../15-your-account.md): Confirm it's you
- [Passkeys and recovery codes](passkeys-and-recovery.md): the policy from the user's side
