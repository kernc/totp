#!/usr/bin/sh
#
# Yet another minimal TOTP generator
#
# © Kevin Cui <krazycavin@gmail.com>
#
# https://github.com/KevCui/totp
#
# Converted to POSIX sh for @kernc/totp.
#
# Usage: ./$0 < secret_file

hd () { od -An -tx1 | tr -d ' \n'; }
hd_rev () { perl -pe 's/../chr hex $&/ge'; }
hmac () { openssl dgst -sha1 -binary -mac hmac -macopt "hexkey:$1"; }

secret="$(cat)"
secret="$secret$(printf "%$(( (8-${#secret}) % 8 ))s" | tr ' ' '=')"
key="$(echo "$secret" | base32 -d | hd)"
mac="$(printf "%016X" "$(( ($(date +%s)) / 30 ))" | hd_rev | hmac "$key" | hd)"
offset="$(( 0x$(echo "$mac" | cut -c40) * 2 ))"
part="$(echo "$mac" | cut -c$((offset + 1))-$((offset + 8)))"
printf "%06d\n" "$(( (0x$part & 0x7FFFFFFF) % 1000000 ))"
