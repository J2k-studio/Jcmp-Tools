# Jget

Download files from the web, and libraries for the [J2K language](https://github.com/J2k-studio/Jcmp). A small program written in J2K.

```
jget https://example.com/file.tar.gz          save it here, named file.tar.gz
jget URL -o other.name                        save it with another name   (-o - : write it to the screen)
jget -q URL                                   no progress bar
jget -x URL                                   make any file executable (scripts and programs already are)
jget -sh URL [args]                           download a script and run it at once
jget --install [DIR]  /  jget --update        put this program in your commands folder / replace it by the latest release
jget -li list                                 the libraries of the index
jget -li install NAME / unstall NAME          install / remove a library (a library is one J2K source file)
```

* A progress bar (percent, size, speed) is drawn when the error output is a terminal. A file is written as it arrives (any size, any bytes) and renamed when it is whole.
* `http://` and `https://` addresses are fetched by jget itself (DNS, TLS 1.3 with the check of the certificate, HTTP/1.1, redirects, chunked answers); `file://`, `ftp://` and servers that only know older protocols by `curl`, or `wget` when there is no `curl`.
  The trusted roots are the system's (Termux: `$PREFIX/etc/tls/cert.pem`) or the file in `J2K_CA`. The TLS code is new and has not been audited.
* Libraries: the index is a text file (`NAME VERSION URL SHA256`), several indexes can be given (`JGET_INDEX`, mirrors); the checksum is checked before anything is installed.
  The default index is [Jcmp-libs](https://github.com/J2k-studio/Jcmp-libs). Libraries go to `~/.j2k/Library` (`JGET_LIB`).

## Install

```
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jget/main/install.sh | sh
```

(Linux ARM64, for example Termux; the program is one file.) `jget --version` shows the version.

## Build

jget is written in J2K and needs the compiler `jcmp` (0.9.187 or newer) with its library: `jcmp jget.jk -o jget`. `./test.sh` builds it and runs the tests (it needs `python3` for a local web server).
