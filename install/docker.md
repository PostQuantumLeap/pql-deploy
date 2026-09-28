# Install with Docker — online

For a Linux host with internet access, running **Docker Engine** with the **Compose v2**
plugin. No internet on the host? Use [Docker — air-gapped](docker-airgapped.md). Podman?
Use [Podman — online](podman.md).

**Every command box is ONE command** — copy it whole, paste it, press Enter. The
[README](../README.md) explains the why behind each step.

> **Licence first.** Nothing is usable until a licence is entered at first login. Order it
> now from [info@postquantumleap.com](mailto:info@postquantumleap.com) — see
> [README §0](../README.md#0-order-your-licence-first).

## 1. Check Docker

```bash
docker compose version
```

Anything from `2.0` up is fine. If `compose` is missing, install Docker Engine with its
Compose plugin from [docs.docker.com/engine/install](https://docs.docker.com/engine/install/).
Make sure Docker starts at boot:

```bash
sudo systemctl enable --now docker
```

Run the commands below as a user in the `docker` group, or put `sudo` in front of each
`docker` command.

## 2. Get the files

```bash
cd ~ && git clone https://github.com/PostQuantumLeap/pql-deploy.git postquantumleap && cd postquantumleap
```

No `git`? Download the [ZIP](https://github.com/PostQuantumLeap/pql-deploy/archive/refs/heads/main.zip),
unpack it and `cd` into `pql-deploy-main`.

## 3. Configure

One command creates `.env` with freshly generated secrets and the pinned image. Put the
version you install (newest: the [Releases](https://github.com/PostQuantumLeap/pql-deploy/releases)
page) and your first administrator's sign-in — it must look like an e-mail address;
nothing is ever mailed to it:

```bash
sh install/generate-env.sh --version 3.4.0 --admin admin@yourcompany.example
```

It prints the sign-in and password for step 6. **Copy `.env` somewhere safe** —
`SETTINGS_ENC_KEY` cannot be recovered if it is lost.

## 4. Start

```bash
docker compose up -d && docker compose ps
```

All three containers — `db`, `app`, `caddy` — should be running, `db` healthy. They
restart on their own after a reboot. To watch the app start (Ctrl-C to stop watching):

```bash
docker compose logs -f app
```

## 5. Open the firewall (if other machines cannot reach it)

If `curl -k https://localhost` answers on the host but nothing reaches it from another
machine, the host firewall blocks 80/443.

RHEL, Rocky, Alma, Fedora:

```bash
sudo firewall-cmd --permanent --add-service=https --add-service=http && sudo firewall-cmd --reload
```

Ubuntu, Debian with ufw:

```bash
sudo ufw allow 80,443/tcp
```

## 6. First login

Open `https://<your-host>/`. The browser warns once — the certificate comes from the
instance's own built-in CA until you install yours ([README §5](../README.md#5-certificates)).

1. Sign in with the username and password step 3 printed.
2. Change the password when asked, and sign in again.
3. Paste your licence.

Then continue with [README §4, First login](../README.md#4-first-login), step 4.

## Next

- Certificates: [README §5](../README.md#5-certificates)
- Upgrading: [README §6](../README.md#6-upgrading)
- Backups: [README §7](../README.md#7-back-up-the-volumes--a-database-backup-is-not-a-key-backup)
- Something wrong: [README §13, Troubleshooting](../README.md#13-troubleshooting)
