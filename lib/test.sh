#!/bin/sh
# TOTP on terminal PIN (generator) - E2E test suite
# Usage: ./$0
# shellcheck disable=SC1007
set -eux

PATH="$(readlink -f "${0%/*}/.."):$PATH"

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
cd "$dir"

HOME="$PWD"

otpauth_migration='otpauth-migration://offline?data=CjEKCkhlbGxvId6tvu8SGEV4YW1wbGU6YWxpY2VAZ29vZ2xlLmNvbRoHRXhhbXBsZTAC'
otpauth_single='otpauth://totp/Login2?secret=GEZDGNBVGY3TQOIK&issuer=Employer'

# Warn no secrets
! PASSWORD= totp.sh
PASSWORD= totp.sh 2>&1 | grep -q 'No secrets'

# Import one
PASSWORD= import.sh <<.
$otpauth_single
.
# shellcheck disable=SC2010
ls "$HOME/.totp/secrets" | grep -q ^33533

# Blank PASSWORD= means unencrypted
grep -q ^otpauth "$HOME"/.totp/secrets/33*

# Totp works
PASSWORD= totp.sh | grep -q Login2

# Encrypt. Filename is URI-dependent
PASSWORD=foo import.sh <<.
$otpauth_single
$otpauth_single
.
test "$(ls "$HOME/.totp/secrets" | wc -l)" -eq 1

# Secret is encrypted
! grep -q ^otpauth $HOME/.totp/secrets/33*

# Totp works
PASSWORD=foo totp.sh | grep -q Login

# Import migration
PASSWORD=bar import.sh <<.
$otpauth_migration
.
test "$(ls "$HOME/.totp/secrets" | wc -l)" -eq 2

# Totp works
PASSWORD=bar totp.sh | grep -q google

# Secrets order is preserved
ls -1tr "$HOME/.totp/secrets" | head -n1 | grep -q ^33

# Warn invalid password
PASSWORD=baz totp.sh 2>&1 | grep -q PASSWORD

# Warn report many secrets
PASSWORD=foo totp.sh 2>&1 | grep -q 1/2

# Warn report seconds
PASSWORD=foo totp.sh 2>&1 | grep -q seconds

# VERBOSE= output URI as 3rd col
VERBOSE=1 PASSWORD=bar totp.sh | cut -f3 | grep -q otpauth

# TODO: SECURITY_TOKEN

# SECRETS_DIR override
SECRETS_DIR=foobar PASSWORD= totp.sh 2>&1 | grep -q 'No secrets'

# Export
PASSWORD=bar export.sh | grep -Eq 'totp_qr.*?otpauth.*'
! command -v qrencode >/dev/null 2>&1 ||
    file totp_qr*.png | grep -q PNG
