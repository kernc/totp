TOTP on terminal PIN (generator)
================================
Written in somewhat dense POSIX shell.

On disk, the secrets are encrypted with a user's password.

The project vendors the excellently concise `totp` computer [by **@KevCui**](https://github.com/KevCui/totp/blob/master/totp).


Installation
------------
```sh
# Discover dependencies already installed
sudo apt install openssl

# Download release and unpack into $HOME/.totp
curl 'https://github.com/kernc/totp/archive/master.tar.gz' |
    tar -C "$HOME/.totp" -xvzf -
```


Usage
-----
Import some QR codes using either `otpauth://` or
`otpauth-migration://` URI scheme:
```script
$ sudo apt install zbar-tools
$ zbarimg path/to/qr1.png
QR-Code:otpauth://totp/Login?secret=GEZDGNBVGY3TQOIK&issuer=Employer

$ zbarimg path/to/qr*.png | grep -o otpauth.* > otpauth_uris.list
$ .totp/import.sh < otpauth_uris.list
```

Assuming your time is correct, get the latest PIN numbers:
```script
$ .totp/totp.sh
123456	Employer/Login
331666	Google/auth
012489	CoinWallet/x
```

Export to QR codes:
```script
$ .totp/export.sh
totp_qr1.png	otpauth://...
totp_qr2.png	otpauth://...
totp_qr3.png	otpauth://...
```

See the [test suite](https://github.com/kernc/totp/blob/master/lib/test.sh)
for more usage examples!


Environment variables
---------------------
* **`PASSWORD=`** Preset the password to encrypt/decrypt the secrets
  so that the program can run without asking.
  If the provided password is empty, the secrets are left unencrypted.
* **`SECURITY_TOKEN=`** If set, the password will be derived from a PKCS#11 hardware security token
  **_URL_ matching this string**. List available token object URL strings with:
  ```shell
  p11tool --list-token-urls | grep 'type=private'
  ```
  Runtime dependencies to use:
  ```shell
  sudo apt install openssl libengine-pkcs11-openssl
  ```
* **`SECRETS_DIR=`** Save/read secrets from this directory (default: `$HOME/.totp/secrets`).
* **`VERBOSE=`** Make totp.sh emit _three_ <kbd>Tab</kbd>-separated columns: PIN, label, and the full export URI.
