# authj: one-time codes for two-step logins

`authj` makes the 6-digit codes of the apps like Google Authenticator (TOTP, RFC 6238): the code that GitHub, GitLab and many sites ask for when you log in (also for `git push` with a token and two-step login). It works without a network, writes the codes in the terminal, and keeps the secrets in a file that can be locked with a passphrase. Written in J2K (SHA-1, HMAC-SHA1/256/512, base32 and PBKDF2 are in the program).

## Commands
```
authj add github JBSWY3DPEHPK3PXP        keep an account (the secret is the text the site shows next to the QR code)
authj add-uri 'otpauth://totp/GitHub:me?secret=JBSWY3DPEHPK3PXP&issuer=GitHub'    the same from the text of a QR code
authj scan screenshot.png                 read the QR code of the site from a picture and keep the account (PNG or JPEG)
authj code github                        the code now:   123456  17s  github     (17 s is how long it is good)
authj code                               the codes of all accounts
authj github                             a short way (a part of the name is enough)
authj list                               the accounts and their settings
authj remove github
authj code github --raw                 only the digits (for scripts and other programs: CODE=$(authj code github --raw))
authj now JBSWY3DPEHPK3PXP               a code at once, nothing is kept
authj passwd                             set, change or remove the passphrase of the file (empty = no lock)
options of add / now:  --digits 6..10   --period 30   --algo sha1|sha256|sha512
```
* The accounts are in `~/.authj/vault` (mode 600; `AUTHJ_DIR` changes the folder). **Lock it with `authj passwd`**: then the whole file is locked with a key from the passphrase (PBKDF2-HMAC-SHA256, 50 000 rounds; HMAC-SHA256 in counter mode as the cipher; an HMAC over everything, so a wrong passphrase or a changed file is refused). The passphrase is asked without an echo, or comes from `AUTHJ_PASS` (so that a script you trust can use a locked vault; any program that can read your environment can then read it too).
* The codes are the same as the apps give for the same secret (checked with the whole table of RFC 6238 for SHA-1, SHA-256 and SHA-512, and against Python for other secrets). The clock of the device must be right.
* It is **not** a hardware key: anyone who can read the vault and knows the passphrase (or runs the program while you are logged in) can make your codes. Keep recovery codes of your sites in a safe place.
* A QR code: take a screenshot or a photo of it and `authj scan PICTURE` (or type the secret the site shows as text, or paste the `otpauth://` text).

```
sh build.sh      # needs jcmp 1.2.2.0 or newer (JCMP=path chooses the compiler)
sh test.sh       # needs python3
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).

## Install
```
jc install authj                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s authj     # with curl (no jget needed)
```
In jsh: `jc install authj`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. On the site (GitHub: Settings, Password and authentication, Two-factor, set up an authenticator app) choose "enter this text code" and copy the secret.
2. `authj add github THE-SECRET` shows the first code: type it on the site to finish.
3. Every login: `authj github` gives the code (a new one every 30 seconds).
4. Lock the file: `authj passwd`. Write the recovery codes of the site down.
