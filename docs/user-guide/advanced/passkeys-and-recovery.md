# Passkeys and recovery codes

How passkeys and recovery codes protect your Post Quantum Leap account, and what the
**Security** page and the **Confirm it's you** dialog ask of you. Read this when the
sign-in page offers a passkey, when you cannot use yours, or when a security notice
appears.

**Who:** every signed-in user with a local account, whatever the role (Reader, PKI
Operator, System Administrator, platform administrator). An account that signs in
through SSO is protected by its identity provider and has nothing to set up here.

## What a passkey is

A passkey signs you in with your fingerprint, your face, your device PIN or a security
key instead of your password.

- It works only at this installation's own address, so a look-alike page cannot use it.
- There is nothing to type, so there is nothing that could be reused elsewhere.
- Passkeys are for accounts that sign in with a password. An SSO account is protected
  by its identity provider instead.

Nothing about passkeys appears until whoever runs the installation turns them on. The
platform administrator chooses the policy: see
[Platform console: settings in detail](platform-settings.md).

## Setting up a passkey

Once passkeys are on, a password sign-in asks you to **Set up a passkey**.

- **Not now** takes you in. The next password sign-in asks again.
- Set one up only if nobody else signs in with this account.
- PQL does not ask on the sign-in that opens the welcome wizard, nor before a password
  change you were told to make.
- You can add a passkey at any time from **Security** (see below).

## Signing in with a passkey

Choose **Use a passkey** on the sign-in page. It needs neither your address nor your
password.

## When your installation requires a passkey

Under the policy *Required once set up*, setting up a passkey continues with **Save
your recovery codes**.

- **Finish** is the moment your password alone stops signing you in. Your other
  sessions end at the same time.
- **Not now** takes you in with nothing changed. Your next sign-in asks you to finish.

From then on, a password sign-in continues with **Confirm it's you** → **Use your
passkey**. A passkey kept on your phone works from a computer too: choose *Use a phone
or tablet* in the browser's window.

## Backup passkeys

Every setup ends by offering a second passkey. A backup matters because a passkey can
be lost with its device.

- A passkey that lives on a single device (Windows Hello, a security key) is lost with
  that device.
- A passkey saved in a password manager is usually backed up for you.

## Passkeys and other addresses

A passkey belongs to the address it was set up at. If you open the same installation
at another address (a LAN IP, a second host name), **Confirm it's you** says *Passkeys
don't work at this address* and links to the right one. **Use a recovery code** stays
available there.

## Recovery codes

Recovery codes are ten codes that look like `7KQ2-M9XD-4HRT-VW3P`.

- PQL shows them when you set up a passkey on an installation that requires one.
- Each code works once, together with your password, when you cannot use your passkey.
- Keep them where you can reach them without that device: a password manager or a
  printed copy.
- The setup asks you to type one code back, to show you have saved them.
- **Security** shows how many codes are left and makes a new set.

### Using a recovery code

On **Confirm it's you**, choose **Use a recovery code**. Check the address bar first.

- Only enter a code at the address your administrator gave you.
- Never enter one on a page a link sent you to.
- Never enter one after a certificate warning.

A password and a code are exactly what a fake sign-in page is after. The screen says
what your code will do before you type it.

### What a code lets you do

That depends on an installation setting chosen by the platform administrator. Either
way your passkeys stay, and once you are in, your other sessions end.

| Installation setting | What *You're almost in* offers | What happens next |
|---|---|---|
| *Require a new passkey* (the usual setting) | Only **Set up a passkey on this device** | The code is used once that passkey is saved. Then **Save your new recovery codes**: your old codes stop working when you finish. Until then, **Not now** included, the codes left on your old sheet keep working. |
| *Allow one sign-in without a passkey* | **Set up a passkey on this device** or **Continue without a new passkey** | The code is used either way, and your other codes keep working. For 3 days some changes are paused (below). |

If this device has no passkey, choose *Use a phone or tablet* or a security key when
the browser asks.

**The 3-day pause.** After a sign-in under *Allow one sign-in without a passkey*, some
changes are paused for 3 days: removing a passkey, changing your password, making new
codes, and administrator actions. They go ahead only if you sign in or confirm with a
passkey you already had. This stops someone who holds your password and one code from
locking you out of your own account.

### Recovery codes at another address

A code is accepted wherever you opened the installation, but a passkey cannot be set
up there.

- Under *Require a new passkey*, the screen says your recovery code is correct and
  **hasn't been used**, and links to the right address. Sign in there with your
  password and the same code, then set up your passkey.
- Where passkeys work only on the server itself, the screen asks you to get an
  administrator to reset your sign-in instead.
- Under *Allow one sign-in without a passkey*, you can continue without a new passkey
  where you are.

### A code is used only when you get in

Going back, a passkey setup that fails, or a sign-in step that expires leaves the code
unused.

### When a passkey is lost

- If you think your lost passkey is in someone else's hands, ask an administrator.
  They can remove it straight away.
- With no passkey and no codes left, ask a System Administrator of your tenant to
  reset your sign-in (see [Admin](../13-admin.md)). A platform administrator can reset
  anyone's, and so can whoever runs the server.

## Security notices

PQL records every change to how you sign in:

- a passkey added, removed or blocked
- a recovery code used
- new codes made
- your sign-in reset
- the installation's passkey policy changed

The ones that need your attention are shown at your next sign-in (**Security
notices**, then **Next**) and in a banner across the app. All of them stay listed under
*Recent security activity* on **Security** for 90 days.

- **This was me** dismisses a notice.
- If it was not you, choose **Review passkeys** or **Change password** straight away.

A change cannot be waved through by the session that made it. Dismissing a notice
takes a session that was already open before the change, or a passkey you had before
it. When no passkey from before the change is left, because you removed them or
because your sign-in was reset, that notice cannot be dismissed. After 14 days it is no
longer shown at sign-in or in the banner.

## The Security page

Open **Security**, next to **Sign out**. It shows how you sign in:

- whether a passkey protects your account
- any cooling-off after a recovery code
- your passkeys: name, created, last used, whether each is synced, on one device or a
  security key, and whether it can still be used here
- your recovery codes: which set, and how many are left
- your password
- the last 90 days of security activity

| Action | What it does |
|---|---|
| **Add a passkey** | On an installation that requires passkeys, the first one leads to your recovery codes. Once you have saved codes, further passkeys are backups, and adding one asks you to confirm with a passkey you already have. |
| **Rename** | Gives a passkey a new name. |
| **Remove** | Removes a passkey. Removing your last one lets your password alone sign you in again, and deletes your recovery codes. |
| **Create new codes** | Makes a new set. It replaces the old one only once you have saved it. Until then the old codes keep working. |

An SSO account is told its identity provider protects its sign-in. It has nothing to
change here.

## Changing your password

**Change password** is open to you at any time. The first time you sign in with the
installation's seeded administrator account, PQL sends you there automatically.

If your account requires a passkey, confirming with the passkey replaces typing your
current password. You may remove your other passkeys in the same step.

## Confirm it's you

Changes that affect who can sign in, or what they may do, ask you to confirm when you
have not signed in or confirmed in the last 10 minutes. That covers:

- adding people and changing roles
- resets and setup links
- SSO providers
- tokens and certificates
- the installation's settings
- your own passkeys and password

The dialog offers what your account can use: your passkey, your current password, or
your identity provider (which sends you back to the same page). **Cancel** changes
nothing.

Resetting the sign-in of somebody who uses a passkey asks for one of your passkeys, or
single sign-on. Your password is never accepted for that (see [Admin](../13-admin.md)).

## See also

- [Signing in](../01-signing-in.md)
- [Your account](../15-your-account.md)
- [Admin](../13-admin.md): resetting someone's sign-in
- [Platform console](../14-platform-console.md)
- [Platform console: settings in detail](platform-settings.md): the Passkeys policy
