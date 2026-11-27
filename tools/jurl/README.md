# jurl

Download files from the web. A small program written in J2K: URLs, a progress bar, HTTPS (TLS 1.3 with the check of the certificate), mirrors. Since 1.0.0 **jurl only downloads**; the tools and the libraries are installed by [jc](../jc/README.md).

```
jurl https://example.com/file.tar.gz          save it here, named file.tar.gz
jurl URL -o other.name                        save it with another name   (-o - : write it to the screen)
jurl -q URL                                   no progress bar
jurl URL URL ...                              several files, each under its own name
jurl -P DIR URL ...                           put the files into the folder DIR (made when missing)
jurl -l LIST                                  the addresses are in the file LIST (one a line, # starts a comment)
jurl -r N URL                                 try again up to N times when a download fails
jurl 'URL1|URL2'                              a mirror: the second is tried when the first fails
jurl -x URL                                   make any file executable (scripts and programs already are)
jurl -m URL                                   a song from a link goes to ~/music (mujic plays it)
jurl -sh URL [args]  /  jurl -jsh URL         download a script and run it at once (sh / jsh)
jurl untar FILE [DIR]                         open a .tar or a .tar.gz
jurl --install [DIR]  /  jurl --update        put this program in your commands folder / replace it by the latest release
```

Tools and libraries: `ex install NAME`, `ex update`, `ex unstall NAME`, `ex tools`, `jex lib install NAME`. (The old forms `jurl tool ...` and `jurl -li ...` are sent to `ex` and `jex`.)

## The everyday commands
| You want to | Type |
|---|---|
| save a file | `jurl LINK` (it says the name and the size) |
| save it under another name | `jurl LINK -o NAME` |
| see it | `jurl LINK -o -` |
| give it to another program | `jurl LINK \| sh` |
| run a script from the web | `jurl -sh LINK` |

## A command written for curl
Write `jurl` where it says `curl`:
```
curl -fsSL https://example.com/install.sh | sh
jurl -fsSL https://example.com/install.sh | sh
```
`-f -s -S -L -O -o -I -i -X -H -d -u -A -w -r`, bundled or long (`--silent`, `--output`), in any order. `-k` is refused: the certificate of a server is always checked.

**Limit:** jurl speaks TLS 1.3 only. A server without it (for example `registry.npmjs.org`) answers "the server sent an alert"; there a system `curl` is needed.

At a terminal `jurl LINK` saves the file under the name in the address and says so (`saved main.zip (2.4 MB)`); to see a page instead, use `jurl LINK -o -`.

* A progress bar (percent, size, speed) is drawn when the error output is a terminal. A file is written as it arrives (any size, any bytes) and renamed when it is whole.
* `http://` and `https://` addresses are fetched by jurl itself (DNS, TLS 1.3 with the check of the certificate, HTTP/1.1, redirects, chunked answers); `file://`, `ftp://` and servers that only know older protocols by `curl`, or `wget` when there is no `curl`.
  The trusted roots are the system's (Termux: `$PREFIX/etc/tls/cert.pem`) or the file in `J2K_CA`. The TLS code is new and has not been audited.
* Libraries: the index is a text file (`NAME VERSION URL SHA256`), several indexes can be given (`JGET_INDEX`, mirrors); the checksum is checked before anything is installed.
  The default index is [Jcmp-libs](https://github.com/J2k-studio/Jcmp-libs). Libraries go to `~/.j2k/Library` (`JGET_LIB`).

## jurl as a curl (1.1.0)
A request with a method, headers and a body; the answer goes to the screen:
```
jurl -d name=ann -d age=31 https://example.com/form                  # a POST (a body makes it a POST); two -d are joined with &
jurl -X PUT -H "Content-Type: application/json" -d @data.json URL      # -d @file reads a file, -d @- the keyboard
jurl -I URL                  # the head only          jurl -i URL     # the head, then the body
jurl -u me:secret URL        # Basic authorization    jurl -A "my app" URL
jurl -f URL                  # a code of 400 or more is an error (exit 22), as curl -f
jurl --no-location URL       # do not follow redirects (they are followed by default)
jurl -w x URL                # the HTTP code after the body    jurl -o answer.txt URL
```
Without these options `jurl URL` is a download with a progress bar, as before.

## Install

```
curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install-jurl.sh | sh
```

(Linux ARM64, for example Termux; the program is one file.) `jurl --version` shows the version.

## Build

jurl is written in J2K and needs the compiler `jcmp` (0.9.187 or newer) with its library: `jcmp tools/jurl/jurl.jk -o jurl`. `tools/jurl/test.sh` builds it and runs the tests (it needs `python3` for a local web server).

## Tools of ex-pkg

`jurl tool list` shows them and `jurl tool coderin` (or several: `jurl tool jsh jbox makej`) puts them next to jurl, after a check of their SHA-256. No curl and no `sh` script are needed, so it works inside the Jaric app too.

## Install
```
jurl --install                                                       # a jurl you already have puts itself in your commands folder
curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install.sh | sh -s jurl     # with curl, the first time
```
Update later with `jurl --update`. In jsh: `ex install jurl`.

## A short lesson
1. Fetch a file: `jurl https://example.com/file.zip` (a bar shows the progress; `-q` hides it, `-o name` names the file).
2. See the tools: `jurl tool list`; get one: `jurl tool mujic` (more than one: `jurl tool jsh jbox jc`).
3. Libraries of the language: `jurl -li list`, `jurl -li install deflate`, then `#import <deflate>`.
4. Open an archive: `jurl untar FILE.tar.gz`.
5. A script from the net: `jurl -sh URL` or `jurl -jsh URL` shows the first lines and asks before it runs (`jaric setting`: run scripts from the net).

License: the license of the repository (the file `LICENSE` at the root of ex-pkg). Build: `J2K_PATH=path sh build.sh` (the library deflate). Test: `sh test.sh`.
