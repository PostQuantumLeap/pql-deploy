<#
.SYNOPSIS
  Bootstrap a Post Quantum Leap installation on Windows.

.DESCRIPTION
  ROAD-24. This does NOT replace the container runtime and does not pretend to:
  it automates the steps a Windows operator would otherwise copy out of
  INSTALLATION.md — check prerequisites, fetch the compose file, generate real
  secrets into .env, start the stack, print where to go.

  It writes the SAME .env and runs the SAME compose file a Linux operator uses.
  That is deliberate: one supported deployment shape, not a Windows-shaped
  variant that drifts away from it.

  Works with Docker or Podman. Podman Desktop is free for commercial use, which
  is the usual reason a Windows customer is reading this at all.

.PARAMETER PasskeyHostName
  Optional. The DNS name people use to reach this server over HTTPS, for
  example pql.corp.example.com. When given, a newly generated .env gets the
  two passkey settings for that name; without it, passkeys stay off. An IP
  address or a single-label name is refused with a warning.

.EXAMPLE
  .\install-windows.ps1
  .\install-windows.ps1 -Runtime podman -InstallDir C:\pql
  .\install-windows.ps1 -PasskeyHostName pql.corp.example.com
#>
[CmdletBinding()]
param(
    [ValidateSet('auto', 'docker', 'podman')]
    [string]$Runtime = 'auto',
    [string]$InstallDir = "$PWD\postquantumleap",
    [string]$Branch = 'main',
    [string]$PasskeyHostName = ''
)

# Stop on real errors, but never on a native command writing to stderr — plenty
# of healthy tools do, and treating that as failure paints a successful install
# red. (Learned the hard way on this project's scanner installer.)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Write-Step { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "    $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "    $m" -ForegroundColor Yellow }

# ⚠ `RandomNumberGenerator::Create().GetBytes()`, NOT `::Fill()`.
#
# `Fill` is a .NET Core / .NET 5+ static. **Windows PowerShell 5.1 runs on
# .NET Framework 4.x, where it does not exist**, and 5.1 is what ships with
# Windows — a customer has it and nothing else unless they installed PowerShell 7
# themselves. Measured 2026-08-25 on a stock Windows 11 box, running this script
# the way the README tells a customer to:
#
#     Method invocation failed because
#     [System.Security.Cryptography.RandomNumberGenerator] does not contain a
#     method named 'Fill'.
#
# It died at "Generating secrets", after locking the directory and fetching the
# compose file — so the install looked like it was working right up until it
# was not. `Create()` + `GetBytes()` exists on both runtimes and is the same CSPRNG.
function New-RandomBytes {
    param([int]$Count)
    $bytes = [byte[]]::new($Count)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return $bytes
}

# A 32-byte urlsafe-base64 value — the shape a Fernet key must have. Anything
# shorter or differently encoded is rejected by the application at boot.
function New-FernetKey {
    [Convert]::ToBase64String((New-RandomBytes -Count 32)).Replace('+', '-').Replace('/', '_')
}

function New-Password {
    param([int]$Length = 28)
    # Ask for more bytes than characters: the strip below removes `+`, `/` and
    # `=`, and on an unlucky draw base64 of exactly $Length bytes can lose
    # enough of them to leave the Substring short. Measured shortfall is small;
    # doubling makes it unreachable.
    $raw = [Convert]::ToBase64String((New-RandomBytes -Count ($Length * 2)))
    # Base64 minus the characters that need quoting in a DSN or an env file.
    ($raw -replace '[+/=]', '').Substring(0, $Length)
}

# ── PASSKEYS: ONLY FROM -PasskeyHostName, NEVER DERIVED ──────────────────────
#
# v3.4 Wave 5 (spec §9). WEBAUTHN_RP_ID binds every passkey to one DNS name,
# and changing it later strands them all, so this script never guesses it —
# not from the machine name, not from a certificate. A derived value would
# switch passkeys on by itself at a re-run and move with a rename. The
# parameter is the operator saying "people reach this server at that name".
#
# Browsers refuse passkeys on an IP address and on a single-label name, so both
# are refused HERE, with a warning, and the install carries on with passkeys
# off: an installation reached only by IP must still install. The name rule
# mirrors backend/app/security/webauthn_origins.py, so a name accepted here is
# one the app boots with.
#
# ⚠ The warning is single-quoted with -f, not a "..." string. Windows
# PowerShell 5.1 reads this BOM-less file in the ANSI code page, where the em
# dash's last byte is a curly closing double quote — and PowerShell ends a
# double-quoted string at a curly quote. Checked while planning (2026-09-15)
# with pwsh 7 parsing a Windows-1252-decoded copy of this script: the "..."
# form fails to parse, this one parses. Not run on 5.1 itself. The script's
# existing messages with a dash are single-quoted, which is why they parse.
#
# EXACT comparisons only: -cmatch, anchored with \A and \z. PowerShell's -eq,
# -ceq and -match compare with culture rules. Measured with pwsh 7: -match
# accepts a name with a dotted capital I (U+0130), which lower-cases to a
# non-ASCII letter, as [a-z]; and -eq and -ceq both call "local", a soft hyphen
# or a control character, and "host" equal to 'localhost'. Each such name was
# then written to .env (a non-ASCII letter as '?'), a value the app refuses at
# boot, so the fresh install crash-looped. A regex's $ also matches before a
# final newline; \z does not. Non-ASCII is refused BEFORE lower-casing, because
# ToLowerInvariant turns the Kelvin sign (U+212A) into an ASCII k, and a name
# nobody typed would be written without a word.
if ($PasskeyHostName) {
    $PasskeyHostName = $PasskeyHostName.Trim()
    $hasNonAscii = $PasskeyHostName -cmatch '[^\x00-\x7F]'
    $PasskeyHostName = $PasskeyHostName.ToLowerInvariant() -replace '\.$', ''
    $parsedIp = $null
    $isIpAddress = [System.Net.IPAddress]::TryParse($PasskeyHostName.Trim('[', ']'), [ref]$parsedIp)
    $isDnsName = (-not $hasNonAscii) -and (
        ($PasskeyHostName -cmatch '\Alocalhost\z') -or (
            $PasskeyHostName.Length -le 253 -and
            $PasskeyHostName -cmatch '\A([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\z'))
    if ($isIpAddress -or -not $isDnsName) {
        Write-Warn ('Passkeys need a DNS name and HTTPS — ''{0}'' can''t be used. Leaving passkeys off.' -f $PasskeyHostName)
        $PasskeyHostName = ''
    }
}

Write-Step 'Checking the container runtime'
$candidates = if ($Runtime -eq 'auto') { @('docker', 'podman') } else { @($Runtime) }
$engine = $null
foreach ($c in $candidates) {
    if (Get-Command $c -ErrorAction SilentlyContinue) {
        # Present on PATH is not the same as running — Docker Desktop can be
        # installed and stopped, and the failure then looks like a network error.
        & $c info *> $null
        if ($LASTEXITCODE -eq 0) { $engine = $c; break }
        Write-Warn "$c is installed but not running"
    }
}
if (-not $engine) {
    Write-Host ''
    Write-Host 'No running container runtime found.' -ForegroundColor Red
    Write-Host '  Podman Desktop  https://podman-desktop.io   (free for commercial use)'
    Write-Host '  Docker Desktop  https://docker.com          (paid above a company-size threshold)'
    Write-Host ''
    Write-Host 'Install one, start it, then run this script again.'
    return    # not `exit`: in the ISE and in `iex` pipelines, exit closes the host
}
Write-Ok "using $engine"

# ⟳ WHERE THIS ACTUALLY LANDS, said out loud. Security review, 2026-08-24.
#
# The default is `$PWD\postquantumleap`, and this script needs a container
# runtime — so it is commonly run from an ELEVATED PowerShell, where elevation
# has already reset the working directory to `C:\Windows\System32`. The install
# therefore lands in `C:\Windows\System32\postquantumleap` without the operator
# choosing that, and without noticing until they go looking for their `.env`.
#
# The DACL below makes that safe rather than merely visible. This warning is so
# the operator can put it somewhere they meant.
$resolvedParent = Split-Path -Parent $InstallDir
if ($resolvedParent -and ($resolvedParent -match '(?i)\\Windows\\System32/?$' -or
                          $resolvedParent -match '^[A-Za-z]:\\?$')) {
    Write-Warn "Installing into $InstallDir"
    Write-Warn 'That is under a system directory — elevation resets the working'
    Write-Warn 'directory, so this is probably not where you meant. Consider:'
    Write-Warn '  -InstallDir C:\ProgramData\PostQuantumLeap'
}

Write-Step "Preparing $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# ── LOCK THE DIRECTORY BEFORE ANYTHING SECRET IS WRITTEN INTO IT ─────────────
#
# ⟳ Security review, 2026-08-24. `.env` here holds EVERY secret the stack has —
# the Postgres passwords, SESSION_SECRET_KEY, SETTINGS_ENC_KEY and the initial
# admin password — and it was written with no permission handling at all, into a
# directory created with inheritance ON.
#
# That matters because of where this lands. The script needs a container runtime,
# so it is commonly run from an ELEVATED PowerShell — and elevation resets the
# working directory to `C:\Windows\System32`, making the default
# `$PWD\postquantumleap` resolve to `C:\Windows\System32\postquantumleap`. The
# documented alternative is `C:\pql`. Both parents carry the stock inheritable
# ACE granting BUILTIN\Users Read & Execute, so the child inherited it and every
# unprivileged local account could read the file.
#
# Inheritance is stripped and an explicit DACL applied: SYSTEM, the local
# Administrators group, and the installing user. Then it is VERIFIED — a failure
# to apply an ACL must not be discovered by an auditor later, so it aborts here
# rather than continuing to write secrets into a readable directory.
# ⚠ ALREADY-LOCKED IS A SUCCESS, NOT A NO-OP TO REDO — this script has to be
# safe to re-run, and re-applying the DACL is what stopped it being so.
#
# `Set-Acl` on a directory whose access rules are already PROTECTED needs
# `SeSecurityPrivilege`, which an ordinary user does not hold. So the first run
# succeeded (fresh directory, inheritance on) and the second aborted:
#
#     ERROR: could not secure ... (The process does not possess the
#     'SeSecurityPrivilege' privilege which is required for this operation.)
#
# Measured 2026-08-25 — and it aborted BEFORE the "`.env` already exists, keeping
# it" branch, so the one path that exists specifically to protect an established
# installation was unreachable on the very runs it was written for: upgrades and
# retries. Verifying instead of re-applying keeps the security property (the
# check below is the same one either way) and costs the privilege.
$alreadyLocked = $false
try {
    $existing = Get-Acl -Path $InstallDir
    $alreadyLocked = $existing.AreAccessRulesProtected -and -not (
        $existing.Access | Where-Object {
            $_.IdentityReference -match 'BUILTIN\\Users|Everyone|Authenticated Users'
        })
} catch { $alreadyLocked = $false }

if ($alreadyLocked) {
    Write-Ok 'install directory already locked (verified, not re-applied)'
} else {
try {
    $acl = Get-Acl -Path $InstallDir
    # $true = protect from inheritance, $false = do NOT copy the inherited rules
    # down first. Copying them would keep the very ACE this exists to remove.
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }
    foreach ($who in @(
        'NT AUTHORITY\SYSTEM',
        'BUILTIN\Administrators',
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    )) {
        $acl.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new(
            $who, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow'))
    }
    Set-Acl -Path $InstallDir -AclObject $acl

    # Verified, not assumed. `Set-Acl` can succeed and still leave a rule behind
    # if a principal failed to resolve.
    $stillReadable = (Get-Acl -Path $InstallDir).Access | Where-Object {
        $_.IdentityReference -match 'BUILTIN\\Users|Everyone|Authenticated Users'
    }
    if ($stillReadable) {
        Write-Host ''
        Write-Host "ERROR: $InstallDir is still readable by ordinary local users." -ForegroundColor Red
        Write-Host '       .env would hold every secret this stack has. Refusing to write it.' -ForegroundColor Red
        Write-Host '       Choose a directory you control, e.g. -InstallDir C:\ProgramData\PostQuantumLeap' -ForegroundColor Red
        return
    }
    Write-Ok 'install directory locked to SYSTEM, Administrators and you'
} catch {
    Write-Host ''
    Write-Host "ERROR: could not secure $InstallDir ($($_.Exception.Message))." -ForegroundColor Red
    Write-Host '       Refusing to write secrets into a directory whose permissions are unknown.' -ForegroundColor Red
    return
}
}   # end: else ($alreadyLocked)

Set-Location $InstallDir

Write-Step 'Fetching the compose file'
# ⚠ THE PUBLIC DEPLOY REPOSITORY, NOT THE PRODUCT REPOSITORY.
#
# This pointed at PostQuantumLeap/pql, which is PRIVATE: every
# anonymous fetch of it returns 404, so this script worked only for someone
# holding credentials — i.e. everyone except the customers it is written for.
# Measured 2026-08-25 before publishing the script: the private raw URL answers
# 404 and the public one answers 200.
#
# The public repo is also where docker-compose.yml is PUBLISHED to, by
# scripts/sync-deploy-repo.sh, so this fetches the same bytes the rest of the
# customer documentation tells people to use.
$base = "https://raw.githubusercontent.com/PostQuantumLeap/pql-deploy/$Branch"
Invoke-WebRequest -Uri "$base/docker-compose.yml" -OutFile 'docker-compose.yml' -UseBasicParsing
Write-Ok 'docker-compose.yml'

# ⚠ THE PROXY'S BOOTSTRAP CONFIG IS NOT OPTIONAL, AND OMITTING IT FAILS IN THE
# WORST POSSIBLE WAY. `docker-compose.yml` mounts it by RELATIVE PATH —
# `./deploy/caddy/bootstrap.json:/etc/caddy/bootstrap.json` — and Docker's
# answer to a bind source that does not exist is to CREATE IT AS A DIRECTORY.
# Caddy then dies on every restart with
#
#     Error: reading config from file: read /etc/caddy/bootstrap.json: is a directory
#
# Measured 2026-08-25, running this script as a customer: `db` and `app` came up
# healthy, `caddy` crash-looped, and the install printed "Post Quantum Leap is
# starting. Open https://localhost" over a stack with **no TLS terminator at
# all**. A successful-looking install whose front door never opens is worse than
# a failed one, because nothing points at the cause.
#
# The README's file table already says this ("Keep the directory layout ...
# mounts the last two by relative path, so moving them breaks the start"). The
# script simply never fetched the second file.
New-Item -ItemType Directory -Force -Path 'deploy\caddy' | Out-Null
Invoke-WebRequest -Uri "$base/deploy/caddy/bootstrap.json" `
    -OutFile 'deploy\caddy\bootstrap.json' -UseBasicParsing
# Verified, not assumed: a stray directory from an earlier run of THIS bug would
# make `Invoke-WebRequest` fail above, but a zero-byte or HTML error page would
# not — and Caddy would fail just as opaquely.
if (-not (Test-Path 'deploy\caddy\bootstrap.json' -PathType Leaf) -or
    (Get-Item 'deploy\caddy\bootstrap.json').Length -eq 0) {
    Write-Host ''
    Write-Host 'ERROR: deploy\caddy\bootstrap.json did not download as a file.' -ForegroundColor Red
    Write-Host '       The TLS proxy cannot start without it. If a DIRECTORY exists at' -ForegroundColor Red
    Write-Host '       that path, an earlier run created it — delete it and re-run.' -ForegroundColor Red
    return
}
Write-Ok 'deploy\caddy\bootstrap.json'

# Remembered for the closing message: with a kept .env, that file's own
# WEBAUTHN_RP_ID decides whether passkeys are available, not -PasskeyHostName.
$envKept = $false
if (Test-Path '.env') {
    $envKept = $true
    Write-Warn '.env already exists — keeping it, secrets not regenerated'
    Write-Warn 'Regenerating SESSION_SECRET_KEY or SETTINGS_ENC_KEY would sign every'
    Write-Warn 'user out and orphan every stored SSO secret. Delete it deliberately if'
    Write-Warn 'that is what you want.'
    if ($PasskeyHostName) {
        # A kept .env is never edited: it may already hold a passkey value
        # somebody chose on purpose, and a silently changed RP ID strands every
        # passkey. Say what to add instead.
        Write-Warn 'To make passkeys available for that name, add these two lines to .env'
        Write-Warn "  WEBAUTHN_RP_ID=$PasskeyHostName"
        Write-Warn "  WEBAUTHN_ORIGINS=https://$PasskeyHostName"
        Write-Warn "and run '$engine compose up -d' again."
    }
} else {
    Write-Step 'Generating secrets'
    $adminPassword = New-Password -Length 20
    @(
        "POSTGRES_PASSWORD=$(New-Password)"
        "APP_DB_PASSWORD=$(New-Password)"
        "SESSION_SECRET_KEY=$(New-Password -Length 48)"
        "SETTINGS_ENC_KEY=$(New-FernetKey)"
        "INITIAL_ADMIN_USERNAME=admin@example.invalid"
        "INITIAL_ADMIN_PASSWORD=$adminPassword"
        "ENV=production"
    ) | Set-Content -Path '.env' -Encoding ascii
    # The directory's DACL is inherited by this file, and the directory is
    # already verified above. Stated rather than assumed, because a reader
    # checking whether the secrets are protected should not have to infer it.
    Write-Ok '.env written with freshly generated values (inherits the locked DACL)'
    if ($PasskeyHostName) {
        # From the parameter alone, after the secrets. This makes passkeys
        # AVAILABLE; the console policy stays Off until a platform
        # administrator chooses one (spec §5.1, P1).
        @(
            "WEBAUTHN_RP_ID=$PasskeyHostName"
            "WEBAUTHN_ORIGINS=https://$PasskeyHostName"
        ) | Add-Content -Path '.env' -Encoding ascii
        Write-Ok "passkeys available for https://$PasskeyHostName (policy still Off)"
    }
}

Write-Step "Starting the stack ($engine compose up -d)"
& $engine compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host "compose failed (exit $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "Logs:  $engine compose logs"
    if ($engine -eq 'podman') {
        Write-Host ''
        Write-Host 'If this failed binding port 80 or 443, that is rootless Podman refusing'
        Write-Host 'a privileged port. INSTALLATION.md section 4 has both fixes.'
    }
    return
}

Write-Host ''
Write-Ok 'Post Quantum Leap is starting.'
Write-Host '    Open      https://localhost'
Write-Host '    Sign in   admin@example.invalid  /  the INITIAL_ADMIN_PASSWORD in .env'
Write-Host '    Logs      ' -NoNewline; Write-Host "$engine compose logs -f"
Write-Host ''
Write-Warn 'The browser will warn about the certificate until you configure TLS'
Write-Warn 'properly — INSTALLATION.md section 9 covers the four supported modes.'
# The .env in use decides, and this script never reads it: a kept one was not
# changed, so neither the parameter nor its absence says anything about it.
# Saying "off" there could invite a second WEBAUTHN_RP_ID, which would strand
# every passkey registered for the first.
if ($envKept) {
    Write-Warn 'Passkeys unchanged: .env was kept, and its WEBAUTHN_RP_ID setting decides. See INSTALLATION.md section 9 (Passkeys).'
} elseif ($PasskeyHostName) {
    Write-Host '    Passkeys  ' -NoNewline; Write-Host "https://$PasskeyHostName - a platform administrator turns them on in Settings"
} else {
    Write-Warn 'Passkeys off — see INSTALLATION.md section 9 (Passkeys) to turn them on.'
}
