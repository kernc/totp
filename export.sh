#!/bin/sh
# TOTP on terminal PIN (generator) - exporter
# Export decrypted secrets into $PWD/totp_qr*.png
# Usage: ./$0
# Environment variables: SECRETS_DIR, PASSWORD | SECURITY_TOKEN
set -eu

qr_cmd () { true; }
command -v qrencode >/dev/null 2>&1 &&
    qr_cmd () { qrencode -v1 -m2 -s10 -d100 -o- "$1" >"$2"; } ||
warn 'WARNING: qrencode not available. apt install qrencode'

i=0
VERBOSE=1 "${0%/*}"/totp.sh |
    cut -f 3 |
    while read -r url; do
        i=$((i + 1))
        fname="totp_qr$i.png"
        printf '%s\t%s\n' "$fname" "$url"
        qr_cmd "$url" "$fname"
    done
