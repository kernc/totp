#!/bin/sh
# TOTP on terminal PIN (generator) - library
# Environment variables: SECRETS_DIR, PASSWORD | SECURITY_TOKEN
# Usage:
#   . ./lib/_lib.sh
#   PASSWORD=debug decrypt "$secret" <"$SECRETS_DIR/$secret"
set -eu


SECRETS_DIR="${SECRETS_DIR:-$HOME/.totp/secrets}"

_GZIP_HEADER='\037\213\010\000\000\000\000\000\000\003'


warn () { echo "${0##*/}: $*" >&2; }
err () { warn "$@"; exit 1; }


openssl_enc () {
    openssl enc -aes-256-ctr -md sha512 -pbkdf2 -iter 31337 \
        -salt -pass fd:6 "$@" -
}


encrypt () {
    [ "$PASSWORD" ] || { cat; return 0; }
    pepper="$1"
    gzip -nc2                                |  # Compress text content
        tail -c +$((${#_GZIP_HEADER}/4 + 1)) |  # Strip gzip header
        openssl_enc 6<<EOF                   |  # Encrypt
$PASSWORD$pepper
EOF
        tail -c +9 -f                           # Remove "Salted__" prefix
}


decrypt () {
    [ "$PASSWORD" ] || { cat; return 0; }
    pepper="$1"
    { printf 'Salted__'; cat; }               |  # Re-add "Salted__" prefix
        openssl_enc -d 6<<EOF                 |  # Decrypt
$PASSWORD$pepper
EOF
        { printf '%b' "$_GZIP_HEADER"; cat; } |  # Re-add gzip header
        { gzip -dc 2>/dev/null || true; }        # Uncompress
}


password_prompt () {
    [ ! "${PASSWORD+1}" ] || return 0
    if [ "${SECURITY_TOKEN:-}" ]; then
        PASSWORD="$(
            echo 'totp-generated-security-token' |
            openssl dgst -engine pkcs11 -keyform engine -sha256 -binary \
                -sign "pkcs11:object=$SECURITY_TOKEN;type=private" 2>/dev/null |
            base64)"
    else
        {
            stty -echo; trap 'stty echo </dev/tty' EXIT
            { printf 'Enter PASSWORD: '; read -r PASSWORD; } >&2
            (
                _CR='\033[1K\r'
                { printf '%bRepeat: ' "$_CR"; read -r PASSWORD2; printf "%b" "$_CR"; } >&2
                [ "$PASSWORD" = "$PASSWORD2" ] ||
                    err 'ERROR: Password mismatch!'
                unset PASSWORD2
            )
            stty echo
        } </dev/tty
    fi
}
