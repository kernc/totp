#!/bin/sh
# decode-migration.sh — decode an otpauth-migration://offline?data=... URI
# (as obtained Google Authenticator) into
# individual otpauth://totp/... or otpauth://hotp/... URIs.
#
# Pure POSIX sh and coreutils.
#
# This code was generated. No support!
#
# Usage: ./decode-migration.sh 'otpauth-migration://offline?data=...'
#    or: ./decode-migration.sh < file_with_uri.txt

set -eu

ALPHABET="ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

# ---- low-level byte-stream helpers -----------------------------------
# BYTES holds the remaining unread bytes as a space-separated decimal
# string. All helpers mutate BYTES directly (no subshells) so state
# threads through correctly.

read_u8() {
    case "$BYTES" in
        *' '*) RET=${BYTES%% *}; BYTES=${BYTES#* } ;;
        *)     RET=$BYTES; BYTES='' ;;
    esac
}

read_varint() {
    val=0
    shiftn=0
    while :; do
        read_u8
        b=$RET
        val=$(( val | ( (b & 0x7f) << shiftn ) ))
        if [ $(( b & 0x80 )) -eq 0 ]; then
            break
        fi
        shiftn=$(( shiftn + 7 ))
    done
    RET=$val
}

# read N bytes, return them as a space-separated decimal string in RET
read_bytes_n() {
    n=$1
    out=""
    i=0
    while [ "$i" -lt "$n" ]; do
        read_u8
        if [ -z "$out" ]; then out=$RET; else out="$out $RET"; fi
        i=$(( i + 1 ))
    done
    RET="$out"
}

# skip one field's value given its wire type (for fields we don't care about)
skip_field() {
    wtype=$1
    case "$wtype" in
        0) read_varint ;;                              # varint
        2) read_varint; read_bytes_n "$RET" ;;          # length-delimited
        *) : ;;                                         # not expected here
    esac
}

# ---- conversions -------------------------------------------------------

# decimal byte list -> ASCII/UTF-8 text (raw bytes passed through)
bytes_to_text() {
    fmt=""
    for b in $1; do
        fmt="$fmt\\$(printf '%03o' "$b")"
    done
    if [ -z "$fmt" ]; then RET=""; else RET=$(printf "$fmt"); fi
}

# decimal byte list -> RFC4648 base32 (padded)
bytes_to_base32() {
    buffer=0
    bits=0
    out=""
    for b in $1; do
        buffer=$(( (buffer << 8) | b ))
        bits=$(( bits + 8 ))
        while [ "$bits" -ge 5 ]; do
            bits=$(( bits - 5 ))
            idx=$(( (buffer >> bits) & 31 ))
            buffer=$(( buffer & ( (1 << bits) - 1 ) ))
            out="$out$(printf '%s' "$ALPHABET" | cut -c$((idx + 1)))"
        done
    done
    if [ "$bits" -gt 0 ]; then
        idx=$(( (buffer << (5 - bits)) & 31 ))
        out="$out$(printf '%s' "$ALPHABET" | cut -c$((idx + 1)))"
    fi
    while [ $(( ${#out} % 8 )) -ne 0 ]; do
        out="$out="
    done
    RET="$out"
}

algo_name() { case "$1" in 1) RET=SHA1;; 2) RET=SHA256;; 3) RET=SHA512;; 4) RET=MD5;; *) RET=SHA1;; esac; }
digits_val() { case "$1" in 2) RET=8;; *) RET=6;; esac; }
type_name() { case "$1" in 1) RET=hotp;; *) RET=totp;; esac; }

# ---- protobuf message parsers ------------------------------------------

# parses one OtpParameters submessage out of the current BYTES
parse_otp_parameters() {
    SECRET=""; NAME=""; ISSUER=""; ALGO=1; DIGITS=1; TYPE=2; COUNTER=0
    while [ -n "$BYTES" ]; do
        read_varint; tag=$RET
        fnum=$(( tag >> 3 )); wtype=$(( tag & 7 ))
        case "$fnum" in
            1) read_varint; read_bytes_n "$RET"; SECRET=$RET ;;
            2) read_varint; read_bytes_n "$RET"; bytes_to_text "$RET"; NAME=$RET ;;
            3) read_varint; read_bytes_n "$RET"; bytes_to_text "$RET"; ISSUER=$RET ;;
            4) read_varint; ALGO=$RET ;;
            5) read_varint; DIGITS=$RET ;;
            6) read_varint; TYPE=$RET ;;
            7) read_varint; COUNTER=$RET ;;
            *) skip_field "$wtype" ;;
        esac
    done

    bytes_to_base32 "$SECRET"; B32=$RET
    algo_name "$ALGO"; ALGO_N=$RET
    digits_val "$DIGITS"; DIG_N=$RET
    type_name "$TYPE"; TYPE_N=$RET

    label=$NAME
    otauth="otpauth://${TYPE_N}/${label}?secret=${B32}&issuer=${ISSUER}&algorithm=${ALGO_N}&digits=${DIG_N}"
    if [ "$TYPE_N" = "hotp" ]; then
        otauth="${otauth}&counter=${COUNTER}"
    fi

    echo "name:     $NAME"
    echo "issuer:   $ISSUER"
    echo "secret:   $B32"
    echo "algo:     $ALGO_N"
    echo "digits:   $DIG_N"
    echo "type:     $TYPE_N"
    [ "$TYPE_N" = "hotp" ] && echo "counter:  $COUNTER"
    echo "uri:      $otauth"
    echo
}

# parses the top-level MigrationPayload from BYTES
parse_payload() {
    while [ -n "$BYTES" ]; do
        read_varint; tag=$RET
        fnum=$(( tag >> 3 )); wtype=$(( tag & 7 ))
        if [ "$fnum" = "1" ] && [ "$wtype" = "2" ]; then
            read_varint; len=$RET
            read_bytes_n "$len"; sub=$RET
            saved=$BYTES
            BYTES=$sub
            parse_otp_parameters
            BYTES=$saved
        else
            skip_field "$wtype"
        fi
    done
}

# ---- URL / base64 decode -----------------------------------------------

urldecode() {
    s=$(printf '%s' "$1" | sed 's/+/ /g; s/\\/\\\\/g;')
    #~ s=$(printf '%s' "$s" | perl -pe 's/%([0-9A-Fa-f]{2})/sprintf "\\%03o", hex($1)/ge')
    #~ printf '%b' "$s"
    printf '%s' "$s" | perl -pe 's/%([0-9A-Fa-f]{2})/chr(hex($1))/ge'
}

# ---- main ----------------------------------------------------------------

uri="${1:-$(cat)}"
data="$(printf '%s' "$uri" | sed -n 's/.*[?&]data=\([^&]*\).*/\1/p')"
if [ -z "$data" ]; then
    echo "Could not find a data= parameter in the given URI" >&2
    exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

urldecode "$data" | base64 -d >"$tmp"

BYTES="$(od -An -v -tu1 "$tmp" | tr -s ' \n' ' ')"
BYTES="$(printf '%s' "$BYTES" | sed 's/^ //; s/ $//')"

parse_payload
