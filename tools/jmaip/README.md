# jmaip

Keys and secrets for the programs of the Jaric world: a vault locked by a passphrase, **passkeys** (P-256 keys that sign a challenge), and
**encryption of files with a key that comes from a passkey**: the file can be opened only by the one who has the passkey. Written in J2K.

```
jmaip init                              make the vault (asks a passphrase: 8 characters or more)
jmaip key new phone                     a new passkey; prints its public key (04 + x + y, 130 hex digits)
jmaip key list | public NAME | rm NAME
jmaip key sign phone "login:7f3a"       the signature in hex (128 digits) of a challenge: text, hex:..., or @FILE
jmaip key verify PUBLIC CHALLENGE SIG   valid / NOT valid (needs no vault)
jmaip enc -k phone notes.txt            notes.txt.jmaip: sealed with a key made from the passkey "phone"
jmaip enc notes.txt                     the same with the key of the vault
jmaip dec notes.txt.jmaip               opens it (the passkey is found from the file)
jmaip secret put NAME VALUE | get NAME | list | rm NAME
jmaip otp ...                           the one-time codes of authj
```
**How it works.** The vault key (32 random bytes) is wrapped with PBKDF2-HMAC-SHA256 (100 000 rounds) and the passphrase. Every passkey, secret and file is sealed with AES-256-GCM;
keys come from the vault key by HMAC / HKDF-SHA256. A passkey is an ECDSA P-256 key; its *encryption secret* is the deterministic signature of a fixed text, put through HKDF
(like the PRF of a FIDO2 key), so the same passkey gives the same file key on every machine that has it. The header of a file (magic, kind, key id, salt) is authenticated:
a changed file or a wrong key is refused, never half-decrypted.

**For other programs.** `JMAIP_PASS` gives the passphrase; `JMAIP_MASTERKEY_CMD` names a command that prints the vault key in hex: this is how a fingerprint or face check of the phone
(the Android part, later) releases the key without a passphrase. `JMAIP_DIR` is the folder (`~/.jmaip`, mode 700). The signing code is the one of `apkj`.

**Limits (honest).** Nothing is constant-time (a machine of one person, not a server). The passkey is a file, not a hardware key: whoever has the vault files and the passphrase has the keys.
There is no recovery: a lost passphrase is a lost vault. The system passkeys of Android (websites) and the face scan come in later steps (see the plan in the Jaric repository).

Install: `jc install jmaip`. Test: `sh test.sh` (needs python3). License: MPL-2.0.
