# jget

Download files from the web. A small program written in J2K: URLs, a progress bar, HTTPS (TLS 1.3 with the check of the certificate), mirrors. Since 1.0.0 **jget only downloads**; the tools and the libraries are installed by [jc](../jc/README.md).

```
jget https://example.com/file.tar.gz          save it here, named file.tar.gz
jget URL -o other.name                        save it with another name   (-o - : write it to the screen)
jget -q URL                                   no progress bar
jget -x URL                                   make any file executable (scripts and programs already are)
jget -m URL                                   a song from a link goes to ~/music (mujic plays it)
jget -sh URL [args]  /  jget -jsh URL         download a script and run it at once (sh / jsh)
jget untar FILE [DIR]                         open a .tar or a .tar.gz
jget --install [DIR]  /  jget --update        put this program in your commands folder / replace it by the latest release
```

Tools and libraries: `jc install NAME`, `jc update`, `jc unstall NAME`, `jc tools`, `jc lib install NAME`. (The old forms `jget tool ...` and `jget -li ...` are sent to jc.)

* A progress bar (percent, size, speed) is drawn when the error output is a terminal. A file is written as it arrives (any size, any bytes) and renamed when it is whole.
* `http://` and `https://` addresses are fetched by jget itself (DNS, TLS 1.3 with the check of the certificate, HTTP/1.1, redirects, chunked answers); `file://`, `ftp://` and servers that only know older protocols by `curl`, or `wget` when there is no `curl`.
  The trusted roots are the system's (Termux: `$PREFIX/etc/tls/cert.pem`) or the file in `J2K_CA`. The TLS code is new and has not been audited.
* Libraries: the index is a text file (`NAME VERSION URL SHA256`), several indexes can be given (`JGET_INDEX`, mirrors); the checksum is checked before anything is installed.
  The default index is [Jcmp-libs](https://github.com/J2k-studio/Jcmp-libs). Libraries go to `~/.j2k/Library` (`JGET_LIB`).

## Install

```
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install-jget.sh | sh
```

(Linux ARM64, for example Termux; the program is one file.) `jget --version` shows the version.

## Build

jget is written in J2K and needs the compiler `jcmp` (0.9.187 or newer) with its library: `jcmp tools/jget/jget.jk -o jget`. `tools/jget/test.sh` builds it and runs the tests (it needs `python3` for a local web server).

## Tools of Jcmp-Tools

`jget tool list` shows them and `jget tool coderin` (or several: `jget tool jsh jbox makej`) puts them next to jget, after a check of their SHA-256. No curl and no `sh` script are needed, so it works inside the Jaric app too.

## Install
```
jget --install                                                       # a jget you already have puts itself in your commands folder
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jget     # with curl, the first time
```
Update later with `jget --update`. In jsh: `jc install jget`.

## A short lesson
1. Fetch a file: `jget https://example.com/file.zip` (a bar shows the progress; `-q` hides it, `-o name` names the file).
2. See the tools: `jget tool list`; get one: `jget tool mujic` (more than one: `jget tool jsh jbox jc`).
3. Libraries of the language: `jget -li list`, `jget -li install deflate`, then `#import <deflate>`.
4. Open an archive: `jget untar FILE.tar.gz`.
5. A script from the net: `jget -sh URL` or `jget -jsh URL` shows the first lines and asks before it runs (`jaric setting`: run scripts from the net).

License: the license of the repository (the file `LICENSE` at the root of Jcmp-Tools). Build: `J2K_PATH=path sh build.sh` (the library deflate). Test: `sh test.sh`.
