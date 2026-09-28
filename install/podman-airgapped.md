# Install with Podman — air-gapped

For a Linux host **without internet access**, running **Podman 4.7 or newer** as a
**normal (rootless) user** — the default this guide follows. Steps that differ when Podman
runs as **root** say so. Everything comes from one **offline kit**: the deployment files,
all three container images and the Compose v2 binary. Nothing is downloaded on the host.
Internet available? Use [Podman — online](podman.md). Docker? Use
[Docker — air-gapped](docker-airgapped.md).

Every step is copy-paste. The [README](../README.md) explains the why behind each one.

> **Licence first.** Nothing is usable until a licence is entered at first login. Order it
> from [info@postquantumleap.com](mailto:info@postquantumleap.com) — see
> [README §0](../README.md#0-order-your-licence-first). It is a text file, so it travels
> with the kit.

## 1. Check Podman

On the **target** host:

```bash
podman --version
uname -m      # x86_64 -> amd64    aarch64 -> arm64
```

**Podman 4.7 or newer is required.** Older Podman is unsupported — see
[deploy/PODMAN-BEFORE-4.7.md](../deploy/PODMAN-BEFORE-4.7.md). Run everything below as
the user who will own the installation, **not** with `sudo` unless a step says so.

## 2. Fetch the kit (on a machine with internet)

Download the kit matching the target's architecture, and its checksum. The newest version
is on the [Releases](https://github.com/PostQuantumLeap/pql-deploy/releases) page:

```bash
V=3.4.0; ARCH=amd64          # ARCH=arm64 for an aarch64 target
curl -fLO "https://github.com/PostQuantumLeap/pql-deploy/releases/download/v$V/pql-offline-$V-$ARCH.tar.gz"
curl -fLO "https://github.com/PostQuantumLeap/pql-deploy/releases/download/v$V/pql-offline-$V-$ARCH.tar.gz.sha256"
```

Carry both files to the target, into your home directory.

## 3. Verify, unpack, load the images

```bash
cd ~
V=3.4.0; ARCH=amd64
sha256sum -c "pql-offline-$V-$ARCH.tar.gz.sha256"
tar -xzf "pql-offline-$V-$ARCH.tar.gz"
cd "pql-offline-$V-$ARCH"
podman load -i images.tar
```

`podman images` now lists `docker.io/library/postgres`, `docker.io/library/caddy` and
`ghcr.io/postquantumleap/pql-app` — full names, exactly what the compose file asks for.

## 4. Install the kit's Compose

Podman does not ship a Compose implementation; `podman compose` runs this one:

```bash
mkdir -p ~/.local/bin && install -m 0755 bin/docker-compose ~/.local/bin/docker-compose
export PATH="$HOME/.local/bin:$PATH"
docker-compose version
```

**Running Podman as root?** Install it where root's `podman compose` looks instead:
`sudo install -D -m 0755 bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose`.

## 5. Start Podman's socket

Compose talks to Podman through it:

```bash
systemctl --user enable --now podman.socket
```

**Running Podman as root?** `sudo systemctl enable --now podman.socket` instead.

## 6. Allow ports 80 and 443 (rootless)

A normal user may not bind ports below 1024, and the proxy publishes 80 and 443. Once per
host:

```bash
echo 'net.ipv4.ip_unprivileged_port_start=80' | sudo tee /etc/sysctl.d/99-pql.conf
sudo sysctl --system
```

**Running Podman as root? Skip this step.**

## 7. Keep it running after you log out (rootless)

Without this, logging out of the last session stops your containers:

```bash
sudo loginctl enable-linger "$USER"
```

**Running Podman as root? Skip this step.**

## 8. Open the firewall

RHEL, Rocky, Alma and Fedora admit only SSH and Cockpit by default — the app would answer
on the host and nowhere else:

```bash
sudo firewall-cmd --permanent --add-service=https --add-service=http && sudo firewall-cmd --reload
```

(Ubuntu or Debian with ufw: `sudo ufw allow 80,443/tcp`.)

## 9. Configure

Create `.env` with freshly generated secrets, pinned to the image the kit carries (its
version is read from the kit's `VERSIONS` file):

```bash
V=$(awk 'NR==1{print $4}' VERSIONS) && echo "kit version: $V"
cp .env.example .env && chmod 600 .env
K=$(openssl rand -base64 32 | tr '+/' '-_')
sed -i \
  -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 24)|" \
  -e "s|^SESSION_SECRET_KEY=.*|SESSION_SECRET_KEY=$(openssl rand -hex 32)|" \
  -e "s|^INITIAL_ADMIN_PASSWORD=.*|INITIAL_ADMIN_PASSWORD=$(openssl rand -hex 12)|" \
  -e "s|^SETTINGS_ENC_KEY=.*|SETTINGS_ENC_KEY=$K|" \
  -e "s|^#PQL_IMAGE=.*|PQL_IMAGE=ghcr.io/postquantumleap/pql-app:$V|" \
  .env
```

Set the first administrator's sign-in — it must look like an e-mail address; nothing is
ever mailed to it:

```bash
sed -i "s|^INITIAL_ADMIN_USERNAME=.*|INITIAL_ADMIN_USERNAME=admin@yourcompany.example|" .env
grep -E '^(INITIAL_ADMIN_USERNAME|INITIAL_ADMIN_PASSWORD|PQL_IMAGE)=' .env
```

**Copy `.env` somewhere safe.** `SETTINGS_ENC_KEY` cannot be recovered if it is lost, and
never regenerate it or `SESSION_SECRET_KEY` after go-live.

## 10. Start — never pulling

```bash
podman compose up -d --pull never
podman compose ps
```

(As root: `sudo podman compose up -d --pull never`.) `--pull never` makes a missing image
fail here, loudly, instead of reaching for a registry the host cannot reach. All three
containers — `db`, `app`, `caddy` — should be running, `db` healthy.

## 11. Start it again after a reboot

Podman has no daemon to bring containers back after a reboot. One user service does it —
run this **in the kit folder**:

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/pql.service <<EOF
[Unit]
Description=Post Quantum Leap
Requires=podman.socket
After=podman.socket

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/podman compose up -d --pull never
ExecStop=/usr/bin/podman compose stop

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload && systemctl --user enable pql.service
```

It starts at boot because of step 7. **Running Podman as root?** Put the same unit in
`/etc/systemd/system/pql.service` with `WantedBy=multi-user.target`, then
`sudo systemctl daemon-reload && sudo systemctl enable pql.service`.

## 12. First login

Open `https://<your-host>/`. The browser warns once — the certificate comes from the
instance's own built-in CA. **Offline, Caddy cannot use Let's Encrypt:** install your own
certificate — your internal CA works — on the TLS page ([README §5](../README.md#5-certificates)).

1. Sign in with `INITIAL_ADMIN_USERNAME` / `INITIAL_ADMIN_PASSWORD` from `.env`.
2. Change the password when asked, and sign in again.
3. Paste your licence.

Then continue with [README §4, First login](../README.md#4-first-login), step 4.

## Next

The README writes `docker compose` everywhere; under Podman, write `podman compose`, and
add `--pull never` to every `up`.

- Upgrading offline: fetch the next version's kit, `podman load -i images.tar`, set
  `PQL_IMAGE` to the new version in `.env`, then `podman compose up -d --pull never` — and
  read [README §6](../README.md#6-upgrading) first.
- Backups: [README §7](../README.md#7-back-up-the-volumes--a-database-backup-is-not-a-key-backup)
- Something wrong: [README §13, Troubleshooting](../README.md#13-troubleshooting)
