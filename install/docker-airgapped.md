# Install with Docker — air-gapped

For a Linux host **without internet access**, running **Docker Engine**. Everything comes
from one **offline kit**: the deployment files, all three container images and the
Compose v2 binary. Nothing is downloaded on the host. Internet available? Use
[Docker — online](docker.md). Podman? Use [Podman — air-gapped](podman-airgapped.md).

Every step is copy-paste. The [README](../README.md) explains the why behind each one.

> **Licence first.** Nothing is usable until a licence is entered at first login. Order it
> from [info@postquantumleap.com](mailto:info@postquantumleap.com) — see
> [README §0](../README.md#0-order-your-licence-first). It is a text file, so it travels
> with the kit.

**Docker Engine must already be installed** on the host — install it from your
distribution's offline repository or mirror. The kit brings Compose, not Docker.

## 1. Fetch the kit (on a machine with internet)

Find the target's architecture first — on the **target** host:

```bash
uname -m      # x86_64 -> amd64    aarch64 -> arm64
```

Then, on any machine with internet access, download the matching kit and its checksum.
The newest version is on the [Releases](https://github.com/PostQuantumLeap/pql-deploy/releases)
page:

```bash
V=3.4.0; ARCH=amd64          # ARCH=arm64 for an aarch64 target
curl -fLO "https://github.com/PostQuantumLeap/pql-deploy/releases/download/v$V/pql-offline-$V-$ARCH.tar.gz"
curl -fLO "https://github.com/PostQuantumLeap/pql-deploy/releases/download/v$V/pql-offline-$V-$ARCH.tar.gz.sha256"
```

Carry both files to the target, into your home directory.

## 2. Verify, unpack, load the images

```bash
cd ~
V=3.4.0; ARCH=amd64
sha256sum -c "pql-offline-$V-$ARCH.tar.gz.sha256"
tar -xzf "pql-offline-$V-$ARCH.tar.gz"
cd "pql-offline-$V-$ARCH"
docker load -i images.tar
```

`docker images` now lists `pql-app`, `postgres` and `caddy`.

## 3. Compose

```bash
docker compose version
```

If that fails, install the kit's Compose as a Docker plugin:

```bash
mkdir -p ~/.docker/cli-plugins && install -m 0755 bin/docker-compose ~/.docker/cli-plugins/docker-compose
docker compose version
```

(For every user on the host instead: `sudo install -D -m 0755 bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose`.)

## 4. Configure

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

## 5. Start — never pulling

```bash
docker compose up -d --pull never
docker compose ps
```

`--pull never` makes a missing image fail here, loudly, instead of reaching for a registry
the host cannot reach. All three containers should be running, `db` healthy. The
containers restart on their own after a reboot.

## 6. Open the firewall (if other machines cannot reach it)

```bash
# RHEL, Rocky, Alma, Fedora
sudo firewall-cmd --permanent --add-service=https --add-service=http && sudo firewall-cmd --reload
# Ubuntu, Debian with ufw
sudo ufw allow 80,443/tcp
```

## 7. First login

Open `https://<your-host>/`. The browser warns once — the certificate comes from the
instance's own built-in CA. **Offline, Caddy cannot use Let's Encrypt:** install your own
certificate — your internal CA works — on the TLS page ([README §5](../README.md#5-certificates)).

1. Sign in with `INITIAL_ADMIN_USERNAME` / `INITIAL_ADMIN_PASSWORD` from `.env`.
2. Change the password when asked, and sign in again.
3. Paste your licence.

Then continue with [README §4, First login](../README.md#4-first-login), step 4.

## Next

- Upgrading offline: fetch the next version's kit, load its `images.tar`, set `PQL_IMAGE`
  to the new version in `.env`, then `docker compose up -d --pull never` — and read
  [README §6](../README.md#6-upgrading) first.
- Backups: [README §7](../README.md#7-back-up-the-volumes--a-database-backup-is-not-a-key-backup)
- Something wrong: [README §13, Troubleshooting](../README.md#13-troubleshooting)
