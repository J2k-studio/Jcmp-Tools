# Jcmp-Tools

Tools for the [J2K language](https://github.com/J2k-studio/Jcmp) and its compiler `jcmp`, written in J2K. Each tool is one program (one file) for Linux ARM64 (Termux, the **Jaric app**, a Linux machine). Together with the app they are **Jaric OS in its console mode**: a shell, packages, an editor, a player, a build tool, and a protocol that lets programs ask the system for pictures, sound and settings.

| tool | what it does |
|---|---|
| [jget](tools/jget/README.md) | download files (https, progress bar), songs (`-m`), the libraries of J2K (`-li`), and the other tools (`jget tool NAME`) |
| [makej](tools/makej/README.md) | the build tool: `makej`, `-j N` (many cores), `init`, `init -pro`, `init -game`, `init -ai`, `apk`, `pack` (.jc), `dist`, `targets` |
| [jsh](tools/jsh/README.md) | the shell: line editing, ghost text, pipes, redirects, scripts, aliases, `jaric setting`, `jaric video` (MPL-2.0) |
| [jbox](tools/jbox/README.md) | about 60 small commands in one program: `dir cat grep sort sed find tree rev paste printf base64 sha256sum ...` (MPL-2.0) |
| [coderin](tools/coderin/README.md) | a text editor for the terminal with J2K colours, extensions and the compiler's errors (MPL-2.0) |
| [mujic](tools/mujic/README.md) | a music player: your songs, free songs to fetch, search the Internet Archive, synced lyrics |
| [zipj](tools/zipj/README.md) | `zipj` makes zip files, `unj` opens them (a password, `-f`, `-o`) (MPL-2.0) |
| [tarj](tools/tarj/README.md) | `tarj` makes and opens tar / tar.gz, `gzj` packs one file with gzip |
| [jvp4](tools/jvp4/README.md) | a video player made only of J2K (own container reader and decoders; today `jvp4 info FILE`) |
| [jpty](tools/jpty/README.md) | run a program on a pseudo terminal (for apps and tests) (MPL-2.0) |
| jcmp | the compiler and its library, as a tool: `jget tool jcmp` |

## Install

```
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh                 # a menu
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s -- jget makej  # the tools you name
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s -- --all      # every tool
```
Options after `sh -s --`: `--dir DIR` (default `$PREFIX/bin` on Termux, else `~/.local/bin`), `--version X.Y.Z`, `--list`, `--yes`. Every file is checked with its SHA-256. With `jget` installed: `jget tool list`, `jget tool NAME`, `jget tool all` (and it links the second names: `unj`, `gzj`, the commands of jbox). In the Jaric app: `install NAME` in the shell.
Libraries of J2K (`#import <name>`): `jget -li list`, `jget -li install gamej` (the game engine), `neuron` (small neural networks), `deflate` (gzip, CRC-32) and more.

## How it all works (the short picture)

```
 you type -> jsh (the shell) -> a program (coderin, makej, mujic, your own ...)
                 |                      |  text goes to the terminal
                 |                      |  pictures, sound, video, settings: messages  ESC ] 7777 ; ... BEL
              jpty (a pseudo terminal)  v
                 +------------- the Jaric app (Android) ---- screen, speakers, touch, clipboard
```
* **Everything is a program** that reads the keyboard and writes text; the Jaric app draws that text, and also understands small messages (`7777;gfx`, `7777;audio`, `7777;video`, `7777;theme`, ...) so a program can show a picture or play a sound. Elsewhere (any terminal) the messages are ignored and the program falls back to text. The full list: `docs/app-protocol.md` in the Jaric documents.
* **Packages:** a tool is one file; a program with data is a **`.jc`** (a zip: `manifest.toml`, the program, `assets/`) made by `makej pack`; an Android app is an **`.apk`** made by `makej apk`.
* **Settings** are plain text files you can edit (`usr/etc/config.local`, `theme.toml`, `~/.jshrc`); `jaric setting` is a screen over them.
* **Standard:** every tool answers `--version` and `--help`, prints errors as `name: message`, exits 0 / 1 / 2, and is tested before a release ([docs/STANDARD.md](docs/STANDARD.md)).

## How to write programs (a tour)

```
coderin hello.jk                  # Esc leaves, Ctrl-S saves.  void main() { cout << "hi\n"; }
jcmp hello.jk -o hello && ./hello
makej init -pro mytool            # a project with the right structure (src/, tests/, docs/, manifest.toml ...)
cd mytool && makej test && makej run
makej init -game                  # a game with Jaric Engine (library <gamej>) and 5 lessons: makej play1 ... play5
makej apk                         # the game as an Android app;  makej pack = a .jc;  makej dist = every system in manifest.toml
makej init -ai                    # a small neural network (library <neuron>)
```
* The language: [github.com/J2k-studio/Jcmp](https://github.com/J2k-studio/Jcmp) (`docs/LANGUAGE.md`; every example compiles). Libraries are used with `#import <name>`; your own files with `#import "name"`.
* `jcmp -d prog.jk` finds memory errors; `jcmp -l lib.jk -o lib.so` makes a shared library (`export` marks the entry points); `jcmp -target arm32` builds for 32-bit ARM.
* A game: `Game g = Game::open("title"); while g.running() { g.begin(); ...draw...; g.end(); } g.close();` (clear, rect, circle, text, art, held, hit, touch, sound). In the app it draws on a surface with the graphics chip; in a terminal with half blocks.

## Using many cores

* **Building:** `makej -j 8` builds up to 8 things at once (the default is the number of cores); a target starts as soon as what it needs is done. `makej -j 1` is one by one.
* **Running:** `#multithread` on the line before a `for i in a..b` loop splits the range over all cores (no `break` / `return` inside); threads and atomics are in the language (`Atomic::`, `Thread`).
* **The compiler itself** works on one core today (it compiles itself in about 2.4 s). Its `-cache DIR` keeps the code of functions that did not change, so a second build is much faster. A parallel code generator is on the plan.
* **Speed of the code:** `jcmp` makes native code; loops get their test at the bottom, values stay in registers, SIMD vectors (`vec`, `Simd`) use the NEON units.

## For the maker of a tool

**Layout:** `tools/` holds only the tools; `extensions/` the extensions of coderin (`coderin -ex NAME`); `install.sh` and `install-NAME.sh` and the list `tools.txt` stay at the root (they have public addresses). A tool lives in `tools/NAME/` (its source, `README.md`, `CHANGELOG.md`, `VERSION`, `LATEST`, `test.sh`, `release.sh`). A release has the tag `NAME-vX.Y.Z` with the file `NAME` and `SHA256SUMS`.
**The guide with every command and examples: [docs/GUIDE.md](docs/GUIDE.md). The rules every tool follows: [docs/STANDARD.md](docs/STANDARD.md).**

The old address `github.com/J2k-studio/Jget` leads here.

## Licences
The repository (jget, makej and the scripts) is under the licence in `LICENSE`. **jsh, jbox, jpty, coderin, zipj, tarj and mujic** are under the Mozilla Public License 2.0: each of their folders has the text.
