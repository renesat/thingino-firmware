#!/usr/bin/env bash
#
# Refresh the static CA bundle shipped in the rootfs overlay from the
# Mozilla root store extract maintained by the curl project.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST="$REPO_ROOT/overlay/etc/ssl/certs/ca-certificates.crt"
URL="https://curl.se/ca/cacert.pem"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

curl -fsSL "$URL" -o "$TMP"

# A truncated download or an HTML error page must never ship in firmware.
CERTS=$(grep -c 'BEGIN CERTIFICATE' "$TMP" || true)
openssl crl2pkcs7 -nocrl -certfile "$TMP" 2>/dev/null | openssl pkcs7 -print_certs -noout >/dev/null
if [ "$CERTS" -lt 100 ]; then
	echo "ERROR: bundle has only $CERTS certificates, expected 100+" >&2
	exit 1
fi

install -m 0644 "$TMP" "$DEST"
echo "Updated $DEST ($CERTS certificates). Commit the diff to refresh camera builds."
