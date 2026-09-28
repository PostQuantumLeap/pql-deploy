#!/bin/sh
# Start Post Quantum Leap again after a reboot under Podman, which has no daemon
# to do it. Installs and enables a systemd service named pql.service that runs
# `podman compose up -d` in this folder.
#
#   sh install/podman-autostart.sh                 rootless Podman (the default)
#   sudo sh install/podman-autostart.sh --system   Podman running as root
#
# Rootless, the service starts at boot only if lingering is on for your user
# (`sudo loginctl enable-linger "$USER"`); this script checks and says so.
# In an offline kit (a VERSIONS file is present) it starts with --pull never.
set -eu
cd "$(dirname "$0")/.."
DIR="$(pwd)"

MODE=user
case "${1:-}" in
    "") ;;
    --system) MODE=system ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1 (see: sh $0 --help)" >&2; exit 2 ;;
esac

PODMAN="$(command -v podman)" || { echo "podman not found on PATH" >&2; exit 1; }
PULL=""
if [ -f VERSIONS ]; then PULL=" --pull never"; fi

if [ "$MODE" = user ]; then
    [ "$(id -u)" != 0 ] || { echo "Run this as the installation's user — or, for Podman as root: sudo sh $0 --system" >&2; exit 2; }
    UNIT_DIR="$HOME/.config/systemd/user"; WANTED=default.target
    ENV_PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
    SOCKET_DEP="Requires=podman.socket
After=podman.socket"
else
    [ "$(id -u)" = 0 ] || { echo "--system needs root: sudo sh $0 --system" >&2; exit 2; }
    UNIT_DIR=/etc/systemd/system; WANTED=multi-user.target
    ENV_PATH="/usr/local/bin:/usr/bin:/bin"
    SOCKET_DEP="Requires=podman.socket
After=podman.socket network-online.target
Wants=network-online.target"
fi

mkdir -p "$UNIT_DIR"
cat > "$UNIT_DIR/pql.service" <<EOF
[Unit]
Description=Post Quantum Leap
$SOCKET_DEP

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$DIR
Environment=PATH=$ENV_PATH
ExecStart=$PODMAN compose up -d$PULL
ExecStop=$PODMAN compose stop

[Install]
WantedBy=$WANTED
EOF

if [ "$MODE" = user ]; then
    systemctl --user daemon-reload
    systemctl --user enable pql.service
    echo "Installed $UNIT_DIR/pql.service (starts: podman compose up -d$PULL in $DIR)."
    if [ "$(loginctl show-user "$(id -un)" --property=Linger --value 2>/dev/null || echo no)" != yes ]; then
        echo "Lingering is OFF for $(id -un), so this will not start at boot. Turn it on once:"
        echo "  sudo loginctl enable-linger $(id -un)"
    fi
else
    systemctl daemon-reload
    systemctl enable pql.service
    echo "Installed $UNIT_DIR/pql.service (starts: podman compose up -d$PULL in $DIR)."
fi
