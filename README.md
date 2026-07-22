TOTP On-Terminal PIN (generator)
================================
[![Build status](https://img.shields.io/github/actions/workflow/status/kernc/totp/ci.yml?branch=master&style=for-the-badge)](https://github.com/kernc/totp/actions)
[![Coverage: 100%](https://img.shields.io/badge/Covr-100%25-brightgreen?style=for-the-badge)](https://github.com/kernc/totp/actions)
[![Language: shell / Bash](https://img.shields.io/badge/Lang-Shell-peachpuff?style=for-the-badge)](https://github.com/kernc/totp)
[![Source lines of code](https://img.shields.io/badge/SLOC-275-skyblue?style=for-the-badge)](https://ghloc.vercel.app/kernc/totp)
[![Script size](https://img.shields.io/badge/Size-8K-skyblue?style=for-the-badge)](https://github.com/kernc/totp)
[![Stars](https://img.shields.io/github/stars/kernc/totp?color=silver&style=for-the-badge&label=%e2%ad%90)](https://github.com/kernc/totp)
[![Sponsors](https://img.shields.io/github/sponsors/kernc?color=pink&style=for-the-badge&label=%e2%99%a5)](https://github.com/sponsors/kernc)
[![Issues](https://img.shields.io/github/issues/kernc/totp?style=for-the-badge&label=Bugs)](https://github.com/kernc/totp/issues)


Manage "authenticator" time-based OTP tokens
([RFC 6238](https://datatracker.ietf.org/doc/html/rfc6238))
most simply in your beloved terminal.
Written in somewhat dense POSIX Shell.

On disk, the secrets are encrypted with a password using OpenSSL
(future-proof/quantum-safe mode AES256-CTR).

This project vendors the
[excellently concise `totp` computer](https://github.com/KevCui/totp/blob/master/totp)
by [**@KevCui**](https://github.com/KevCui).


Features
--------
* Some 100 vetted lines of POSIX Shell total
* Import and export via QR-codes or `otpauth://` or `otpauth-migration://` URIs
* Safe encryption of secrets in storage (via `openssl enc`)


Installation
------------
```sh
# Discover dependencies already installed
sudo apt install openssl

# Download the latest release and unpack into $HOME/.totp
mkdir -p "$HOME/.totp"
curl -L 'https://github.com/kernc/totp/archive/master.tar.gz' |
    tar -C "$HOME/.totp" -xvz --strip-components 1 --exclude .github
```


Usage
-----
All of the contained are very simple scripts that (may) read lines on stdin
and take no command line arguments.

**Import some QR codes** using either `otpauth://` or
`otpauth-migration://` URI scheme:
```script
$ sudo apt install zbar-tools
$ zbarimg path/to/qr1.png
QR-Code:otpauth://totp/Login?secret=GEZDGNBVGY3TQOIK&issuer=Employer

$ zbarimg path/to/qr*.png | grep -o otpauth.* > otpauth_uris.list

$ .totp/import < otpauth_uris.list
Enter PASSWORD:
```
You pick a password for the encryption of secrets on disk.
If the password is blank, the secrets will be left plaintext (unsafe).
You can have different passwords for different secrets;
simply invoke `import` multiple times.

Assuming your system time is correct, **get the latest PIN tokens**:
```script
$ .totp/totp
123456	Employer/Login
331666	Google/auth
012489	CoinWallet/x
totp: Password unlocks 3/5 secrets
totp: New codes in 14 seconds
```
As you can see again, you can have different passwords for different secrets.

If need arises, **export to QR codes** or plaintext URIs:
```script
$ .totp/export
totp_qr1.png	otpauth://...
totp_qr2.png	otpauth://...
totp_qr3.png	otpauth://...
```

See the [test suite](https://github.com/kernc/totp/blob/master/lib/test.sh)
for more illustrative usage examples!


Environment variables
---------------------
* **`PASSWORD=`** Preset the password to encrypt/decrypt the secrets
  so that the program can run without asking.
  If the password is empty, the secrets are left unencrypted.
* **`SECURITY_TOKEN=`** If set, the password will be derived from a PKCS#11
  **hardware security token** _object URL_
  [matching this string](https://github.com/search?q=repo%3Akernc%2Ftotp+%22%24SECURITY_TOKEN%22&type=code).
  List available token object URL strings with:
  ```sh
  # Runtime deps to use the feature
  sudo apt install gnutls-bin libengine-pkcs11-openssl

  p11tool --list-token-urls | grep 'type=private'
  ```
* **`SECRETS_DIR=`** Save/read secrets from this directory (default: `$HOME/.totp/secrets`).
* **`VERBOSE=`** Make `totp` emit _three_ instead of two <kbd>Tab</kbd>-separated columns: PIN, label, and the full export URI.
