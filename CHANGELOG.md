# Changelog

## 0.5.1
* `jget -li unstall NAME` removes a library (shorter; `remove` and `uninstall` still work).

## 0.5.0
* **`jget URL | sh` works**: when the output of jget goes to a pipe or a file (not a terminal) and there is no `-o`, the data goes there (like curl); in a terminal it is still saved in a file named after the address. `-O` saves in a file with the name of the address even in a pipe.
* `jget -li install gfx` installs `canvas` and `screen`; the libraries that come with jcmp (stdlib, math, vector, matrix, cpu) are known: nothing to install; `simd`, `quat`, `complex`, `stats`, `canvas`, `screen` are downloaded.
* The end of a very short download says `in 0:00 (2.2 MB/s)` and not `0 B/s`.

## 0.4.3
* The source uses `Sys::` instead of numbers of system calls (the library of jcmp 0.9.186). Nothing changes for the user. Test servers of `test.sh` no longer stay running.

## 0.4.2
* **A better progress line**: `[#########>         ]  50%  13.1 MB / 25.9 MB  844.9 KB/s  ETA 0:15`; the speed is that of the last second, the bar fits the width of the terminal; when the size is not known a block goes to and fro with the size, the speed and the time; at the end `[##########] 100%  25.9 MB in 0:31  (840.1 KB/s)`. (From the library of jcmp 0.9.185.)
* The repository is now called **Jget** (the old address still works); the program is still `jget`.

## 0.4.1
* A downloaded **script (#!) or program (ELF) is made executable by itself**; one that already is executable is left alone; an ordinary file is not touched. `-x` still does it for any file. (No hint about scripts any more.)

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
