# Changelog

## 0.4.0
* Easier to use after a download: `-x` makes the file executable; a downloaded script that is not executable gets a hint (`sh NAME`); `jget -sh URL [args]` downloads a script, runs it at once and deletes it (what `curl URL | sh` does).
* `jget --install [DIR]` copies the program into the folder of commands (`$PREFIX/bin` on Termux, else `~/.local/bin`); `jget --update` replaces it by the latest release after checking the SHA-256.

## 0.3.1
* TLS also speaks AES-128-GCM (from the library of jcmp 0.9.184): more servers are reached. Needs jcmp 0.9.184 to build.

## 0.3.0
* **https:// is fetched by jget itself**: TLS 1.3 written in J2K (from the library of jcmp 0.9.183), with the check of the certificate chain, the name, the dates and the trusted roots (the system's, or the file in `J2K_CA`). No curl or wget is needed for http:// and https://.
* A certificate that is refused (not trusted, wrong name, expired, bad proof of the key) is reported and **not** retried with curl; a server that only knows older protocols is still fetched by curl or wget.

## 0.2.0
* The first release as a project of its own (before: an example of the J2K compiler repository).
* Downloads a **file** (any size, any bytes) to disk as it arrives, with a progress bar (percent, size, speed) on a terminal; `jget URL` names the file after the address; `-o FILE`, `-o -`, `-q`.
* `http://` is fetched by jget itself; `https://` and others by curl or wget (written to `NAME.part` and renamed when whole).
* Libraries: `-li list | install | uninstall | installed`; several indexes (mirrors) in `JGET_INDEX`; several addresses (`a|b`) for a library file; the SHA-256 is checked before installing.
