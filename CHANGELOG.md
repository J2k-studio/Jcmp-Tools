# Changelog

## 0.2.0
* The first release as a project of its own (before: an example of the J2K compiler repository).
* Downloads a **file** (any size, any bytes) to disk as it arrives, with a progress bar (percent, size, speed) on a terminal; `jget URL` names the file after the address; `-o FILE`, `-o -`, `-q`.
* `http://` is fetched by jget itself; `https://` and others by curl or wget (written to `NAME.part` and renamed when whole).
* Libraries: `-li list | install | uninstall | installed`; several indexes (mirrors) in `JGET_INDEX`; several addresses (`a|b`) for a library file; the SHA-256 is checked before installing.
