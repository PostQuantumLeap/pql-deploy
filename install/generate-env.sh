#!/bin/sh
# Create .env from .env.example with freshly generated secrets.
#
#   sh install/generate-env.sh --version 3.4.0 --admin admin@yourcompany.example
#   sh install/generate-env.sh --admin admin@yourcompany.example      # in an offline kit
#
#   --version  the image version to pin (PQL_IMAGE). Optional inside an offline
#              kit, which records its own version in VERSIONS.
#   --admin    the first administrator's sign-in. Must look like an e-mail
#              address; nothing is ever mailed to it. Optional: without it the
#              example value stays and you edit INITIAL_ADMIN_USERNAME yourself.
#
# It NEVER overwrites an existing .env: SETTINGS_ENC_KEY and SESSION_SECRET_KEY
# must not change after go-live, and a second run would silently change both.
# Needs only openssl and sed.
set -eu
cd "$(dirname "$0")/.."

V=""; ADMIN=""
while [ $# -gt 0 ]; do
    case "$1" in
        --version) V="${2:-}"; shift 2 ;;
        --admin)   ADMIN="${2:-}"; shift 2 ;;
        -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
        *) echo "unknown argument: $1 (see: sh $0 --help)" >&2; exit 2 ;;
    esac
done

if [ -z "$V" ] && [ -f VERSIONS ]; then V="$(awk 'NR==1{print $4}' VERSIONS)"; fi
[ -n "$V" ] || { echo "Pass --version, e.g. --version 3.4.0 (newest: the Releases page)." >&2; exit 2; }
case "$ADMIN" in ""|*@*.*) ;; *) echo "--admin must look like an e-mail address, got '$ADMIN'" >&2; exit 2 ;; esac
[ -f .env.example ] || { echo "no .env.example here — run this from the deployment folder" >&2; exit 1; }
if [ -e .env ]; then
    echo ".env already exists — left untouched. Its secrets must not change after go-live;" >&2
    echo "remove it deliberately only if this installation has never been used." >&2
    exit 1
fi
command -v openssl >/dev/null 2>&1 || { echo "openssl is required" >&2; exit 1; }

umask 077
K="$(openssl rand -base64 32 | tr '+/' '-_')"
sed \
  -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 24)|" \
  -e "s|^SESSION_SECRET_KEY=.*|SESSION_SECRET_KEY=$(openssl rand -hex 32)|" \
  -e "s|^INITIAL_ADMIN_PASSWORD=.*|INITIAL_ADMIN_PASSWORD=$(openssl rand -hex 12)|" \
  -e "s|^SETTINGS_ENC_KEY=.*|SETTINGS_ENC_KEY=$K|" \
  -e "s|^#PQL_IMAGE=.*|PQL_IMAGE=ghcr.io/postquantumleap/pql-app:$V|" \
  .env.example > .env
if [ -n "$ADMIN" ]; then
    sed "s|^INITIAL_ADMIN_USERNAME=.*|INITIAL_ADMIN_USERNAME=$ADMIN|" .env > .env.tmp && mv .env.tmp .env
fi

if grep -q '^[A-Z_]*=CHANGEME' .env; then
    echo "some required values were not filled — check .env:" >&2
    grep '^[A-Z_]*=CHANGEME' .env >&2
    exit 1
fi

echo "Created .env (readable by you only). First sign-in:"
grep -E '^(INITIAL_ADMIN_USERNAME|INITIAL_ADMIN_PASSWORD|PQL_IMAGE)=' .env | sed 's/^/  /'
echo "Copy .env somewhere safe: SETTINGS_ENC_KEY cannot be recovered if it is lost."
