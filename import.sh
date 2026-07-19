#!/bin/sh
# TOTP on terminal PIN (generator) - importer
# Import 'otpauth-migration://offline?data=...' URIs
# and 'otpauth://...' secrets into $HOME/.totp/secrets.
# Usage: ./$0 < otpauth_uris
# Environment variables: SECRETS_DIR, PASSWORD | SECURITY_TOKEN
set -eu

. "${0%/*}"/lib/_lib.sh

mkdir -p "$SECRETS_DIR"
chmod go-rwx "$SECRETS_DIR"


otpauth_migration () {
    echo "$1" |
        "${0%/*}"/lib/decode-migration.sh |
        grep -o 'otpauth://.*' |
        while read -r url; do
            otpauth_single "$url"
        done
}


otpauth_single () {
    url="$1"
    filename="$(echo "$url" | md5sum | cut -c-32)"
    echo "$url" |
        sed -E "s,[^[[:print:]]]*otpauth://([^/]+)/([^?]+)?.*?issuer=([^&]*).*,${0##*/}: Importing \1 $filename: \2 @ \3," >&2
    echo "$url" |
        encrypt "$filename" >"$SECRETS_DIR/$filename"
}


while read -r line; do
    password_prompt
    case "$line" in
        otpauth://*) otpauth_single "$line" ;;
        otpauth-migration://*) otpauth_migration "$line" ;;
        *) err 'ERROR: Only otpauth://... and otpauth-migration://.. URIs supported' ;;
    esac
done
