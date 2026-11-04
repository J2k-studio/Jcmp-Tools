# Changelog

## 0.2.0
* **Added:** `jmaip serve`: the API for other programs: JSON lines on `127.0.0.1` with a token (`api.token`, mode 600): ping, key.list / public / sign / verify, secret.get / put / rm / list, enc / dec (data in hex). 9 tests with a Python client.
* **Fixed:** none.

## 0.1.0
* **Added:** first release: the vault, passkeys (new, list, public, sign, verify, rm), encryption of files with the vault key or with a passkey (AES-256-GCM), secrets, `otp` through authj, `JMAIP_MASTERKEY_CMD` for a key from outside.
* **Fixed:** none.
