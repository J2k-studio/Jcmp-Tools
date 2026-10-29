# authj changelog

## 0.1.0
* **Added:** `add`, `add-uri` (the `otpauth://` text), `code`, `list`, `remove`, `now`, `passwd`; TOTP with SHA-1, SHA-256 and SHA-512, 6 to 10 digits, any period; a vault in `~/.authj/vault` (mode 600) that can be locked with a passphrase (PBKDF2-HMAC-SHA256, HMAC counter-mode cipher, HMAC over the whole file).
* **Fixed:** none (first release). Not yet: reading a QR picture.
