# zipj changelog

## 0.1.2
* **Fixed:** `unj FILE.tar.gz` (also `.tgz`, `.tar`) opens the whole archive in one step (it left a `.tar` and then said "is not a zip file"); the work is done by `tarj` (`ex install tarj`).

## 0.1.1
* **Fixed:** `zipj --help` (and `-h`) prints the usage of `zipj` and `unj` and exits 0 (it exited 2).

## 0.1.0
* zipj and unj: zip (deflate, store), a password (ZipCrypto, asked without an echo), -f, -o, -l, .gz.
