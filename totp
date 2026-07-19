#!/bin/sh
# TOTP on terminal PIN (generator) - secret decoder
# Usage: ./$0 
# Environment variables: SECRETS_DIR, PASSWORD | SECURITY_TOKEN, VERBOSE
set -eu

. "${0%/*}"/lib/_lib.sh

success=
# shellcheck disable=SC2045
for f in $(ls -tr "$SECRETS_DIR" 2>/dev/null); do
    f="$SECRETS_DIR/$f"
    password_prompt
    url="$(decrypt "${f##*/}" <"$f")"
    if [ "$url" != "${url#otpauth://}" ]; then
        secret="$(echo "$url" | sed -E 's/.*?\bsecret=([^&]+).*/\1/')"
        pin="$(echo "$secret" | "${0%/*}"/lib/totp-gen.sh)"
        verbose= ; [ ! "${VERBOSE:-}" ] || verbose="\t$url"
        echo "$url" |
            sed -E "s,otpauth://([^/]+)/([^?]+)?.*?\bissuer=([^&]*).*,$pin\t\3/\2$verbose,"
        success=$((${success:-0} + 1))
    fi
done

[ ! "$success" ] || {
    count_args () { echo "$#"; }
    warn "Password unlocks $success/$(count_args "$SECRETS_DIR"/*) secrets"
    warn "New codes in $((30 - 1 - $(date +%s) % 30)) seconds"
}

[ "$success" ] || {
    if [ ! "${f:-}" ]; then err 'ERROR: No secrets. First import some.'
    else err 'ERROR: PASSWORD unlocks no secrets'
    fi
}
