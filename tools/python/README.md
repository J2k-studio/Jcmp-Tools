# python: Python 3.14 for the Jaric app and Android ARM64

The official build of python.org for Android (`libpython3.14.so`, 21 MB packed) with a small launcher written in J2K (`python.jk`, built with `jcmp -dyn`; it opens the library with `<native>` and calls `Py_BytesMain`). The launcher sets `PYTHONHOME` and `SSL_CERT_FILE` itself, so nothing else is needed. Works in Termux and in the Jaric app. `ssl`, `sqlite3`, `zlib`, `json`, `ctypes` are there; no `pip` yet and no tkinter.

```
python3 -c "print(1 + 1)"
python3 script.py
```
Without Jaric it is on its own: the launcher finds the folder `python-android` next to itself (about 78 MB open, 13 MB to fetch).

## Install
```
jc install python                                                     # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s python     # with curl
```
`python3` is a link to `python`. In jsh: `jc install python`.

## A short lesson
1. Check: `python3 --version`, then `python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"`.
2. A script: write `hello.py` with `print("hello")`, run `python3 hello.py`.
3. The web: `python3 -c "import urllib.request as u; print(u.urlopen('https://www.python.org').status)"` prints 200.
4. The tool [yt-dlp](../yt-dlp/README.md) runs on this Python.

Build (for the maker): `sh release.sh JCMP python-3.14.0-aarch64-linux-android.tar.gz` (the tarball from https://www.python.org/ftp/python/3.14.0/). Licenses: the launcher MPL-2.0, Python PSF License.
