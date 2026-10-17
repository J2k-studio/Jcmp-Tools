# jget

Download files from the web, and libraries for the [J2K language](https://github.com/J2k-studio/Jcmp). A small program written in J2K.

```
jget https://example.com/file.tar.gz          save it here, named file.tar.gz
jget URL -o other.name                        save it with another name   (-o - : write it to the screen)
jget -q URL                                   no progress bar
jget -li list                                 the libraries of the index
jget -li install NAME / uninstall NAME        install / remove a library (a library is one J2K source file)
```

* A progress bar (percent, size, speed) is drawn when the error output is a terminal. A file is written as it arrives (any size, any bytes) and renamed when it is whole.
* `http://` addresses are fetched by jget itself (DNS, HTTP/1.1, redirects, chunked answers); `https://` and the others by `curl`, or `wget` when there is no `curl` (TLS is not written yet).
* Libraries: the index is a text file (`NAME VERSION URL SHA256`), several indexes can be given (`JGET_INDEX`, mirrors); the checksum is checked before anything is installed.
  The default index is [Jcmp-libs](https://github.com/J2k-studio/Jcmp-libs). Libraries go to `~/.j2k/Library` (`JGET_LIB`).

## Install

```
curl -fsSL https://raw.githubusercontent.com/J2k-studio/jget/main/install.sh | sh
```

(Linux ARM64, for example Termux; the program is one file.) `jget --version` shows the version.

## Build

jget is written in J2K and needs the compiler `jcmp` (0.9.182 or newer) with its library: `jcmp jget.jk -o jget`. `./test.sh` builds it and runs the tests (it needs `python3` for a local web server).
