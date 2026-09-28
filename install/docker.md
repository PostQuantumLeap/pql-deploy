# Install with Docker — online

For a Linux host with internet access, running **Docker Engine** with the **Compose v2**
plugin. No internet on the host? Use [Docker — air-gapped](docker-airgapped.md). Podman?
Use [Podman — online](podman.md).

Every step is copy-paste. The [README](../README.md) explains the why behind each one.

> **Licence first.** Nothing is usable until a licence is entered at first login. Order it
> now from [info@postquantumleap.com](mailto:info@postquantumleap.com) — see
> [README §0](../README.md#0-order-your-licence-first).

## 1. Check Docker

```bash
docker compose version
```

Anything from `2.0` up is fine. If `compose` is missing, install Docker Engine with its
Compose plugin from [docs.docker.com/engine/install](https://docs.docker.com/engine/install/),
and make sure Docker starts at boot: `sudo systemctl enable --now docker`.

Run the commands below as a user in the `docker` group, or put `sudo` in front of each
`docker` command.

## 2. Get the files

```bash
cd ~
git clone https://github.com/PostQuantumLeap/pql-deploy.git postquantumleap
cd postquantumleap
```

No `git`? Download the [ZIP](https://github.com/PostQuantumLeap/pql-deploy/archive/refs/heads/main.zip),
unpack it and `cd` into `pql-deploy-main`.

## 3. Configure

Create `.env` with freshly generated secrets and the pinned image. Set `V` to the version
you install — the newest is on the [Releases](https://github.com/PostQuantumLeap/pql-deploy/releases)
page:

```bash
V=3.4.0
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

## 4. Start

```bash
docker compose up -d
docker compose ps
```

All three containers — `db`, `app`, `caddy` — should be running, `db` healthy. To watch the
app start: `docker compose logs -f app` (Ctrl-C to stop watching). The containers restart
on their own after a reboot.

## 5. Open the firewall (if other machines cannot reach it)

`curl -k https://localhost` answering on the host but nothing from another machine means
the host firewall blocks 80/443:

```bash
# RHEL, Rocky, Alma, Fedora
sudo firewall-cmd --permanent --add-service=https --add-service=http && sudo firewall-cmd --reload
# Ubuntu, Debian with ufw
sudo ufw allow 80,443/tcp
```

## 6. First login

Open `https://<your-host>/`. The browser warns once — the certificate comes from the
instance's own built-in CA until you install yours ([README §5](../README.md#5-certificates)).

1. Sign in with `INITIAL_ADMIN_USERNAME` / `INITIAL_ADMIN_PASSWORD` from `.env`.
2. Change the password when asked, and sign in again.
3. Paste your licence.

Then continue with [README §4, First login](../README.md#4-first-login), step 4.

## Next

- Certificates: [README §5](../README.md#5-certificates)
- Upgrading: [README §6](../README.md#6-upgrading)
- Backups: [README §7](../README.md#7-back-up-the-volumes--a-database-backup-is-not-a-key-backup)
- Something wrong: [README §13, Troubleshooting](../README.md#13-troubleshooting)
