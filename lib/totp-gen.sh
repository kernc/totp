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
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this file (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions: The above copyright
# notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
