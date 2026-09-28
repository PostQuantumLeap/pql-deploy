# Unsupported: installing on Podman older than 4.7

**Post Quantum Leap requires Podman 4.7 or newer.** This page exists for the operator who
cannot upgrade yet. It is not tested with each release, and support requests on this route
are answered with "upgrade Podman first". The supported guide is
[README §9, Running under Podman](../README.md#9-running-under-podman).

Check what you have:

```bash
podman --version
```

Debian 12, for example, ships Podman 4.3.1.

## Why it is different

Podman before 4.7 has no `compose` subcommand at all. `podman compose up -d` fails with
`Error: unknown shorthand flag: 'd' in -d`, which reads like a bad flag and is really a
missing command. The route below skips `podman compose` and points Compose v2 at Podman's
Docker-compatible socket directly.

`podman-compose` — a separate tool your package manager may offer — is not a way around
this: it cannot run this compose file ([README §9.1](../README.md#91-podman-compose-is-not-supported)).

## The route

**1. Install Compose v2**, the same single binary as the supported route:

```bash
mkdir -p ~/.local/bin
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o ~/.local/bin/docker-compose
chmod +x ~/.local/bin/docker-compose
export PATH="$HOME/.local/bin:$PATH"
```

**2. Start the socket and point Compose at it.** Ask Podman where its socket is rather
than assuming — it lives in a `podman/` subdirectory of the runtime dir
(`/run/user/1000/podman/podman.sock`), not directly in it, and hardcoding the shorter path
fails with `dial unix /run/user/1000/podman.sock: connect: no such file or directory`
*after* the socket has started perfectly well:

```bash
systemctl --user enable --now podman.socket
export DOCKER_HOST="unix://$(podman info --format '{{.Host.RemoteSocket.Path}}')"
```

**3. Rootless?** Allow ports 80 and 443 once, as in
[README §9](../README.md#rootless-and-ports-below-1024).

**4. Start** — as `docker-compose`, with a hyphen. `docker compose` (with a space) is a
subcommand of the Docker CLI, which you do not have:

```bash
docker-compose up -d
```

If it cannot connect, check the socket is running and see the path it reports:

```bash
systemctl --user status podman.socket
podman info --format '{{.Host.RemoteSocket.Path}} exists={{.Host.RemoteSocket.Exists}}'
```

`Exists=false` means the unit is enabled but not started — `systemctl --user start
podman.socket`.

## Everywhere else in the guide

The README writes `docker compose` for upgrading, backups, troubleshooting and logs. On
this route write **`docker-compose`** (hyphen) instead, and keep `DOCKER_HOST` exported in
that shell — put both `export` lines in `~/.bashrc` so new terminals keep finding Podman.
Nothing else changes.
