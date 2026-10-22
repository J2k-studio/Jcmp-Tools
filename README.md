# Jcmp-Tools

Tools for the [J2K language](https://github.com/J2k-studio/Jcmp) and its compiler `jcmp`, written in J2K. Each tool is one program (one file), made for Linux ARM64 (for example Termux).

| tool | what it does |
|---|---|
| [jget](tools/jget/README.md) | download files from the web (https, a progress bar) and the libraries of J2K |
| [makej](tools/makej/README.md) | a build tool for J2K projects: the build file is a plain file (`nano makej`) or a J2K program |
| [jsh](tools/jsh/README.md) | a small shell: line editing, ghost text, pipes, variables, aliases, scripts with if / while / for / functions (MPL-2.0) |
| [jbox](tools/jbox/README.md) | `ls cat grep sort cp mv rm ...` in one program (MPL-2.0) |
| [jpty](tools/jpty/README.md) | run a program on a pseudo terminal, driven through two pipes (MPL-2.0) |
| [coderin](tools/coderin/README.md) | a text editor for the terminal: colours for J2K, select, copy and paste, find (MPL-2.0) |

(more will come here, for example a build tool.)

## Install

Choose what to install:

```
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh                 # a menu (jget when there is no terminal)
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s -- jget       # the tools you name
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s -- --all      # every tool
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install-jget.sh | sh             # one tool: install-NAME.sh
```

Options (after `sh -s --`): `--dir DIR` (default `$PREFIX/bin` on Termux, else `~/.local/bin`), `--version X.Y.Z` (one tool), `--list`, `--yes` (never ask). Every file is checked with its SHA-256 before it is put in the folder.

## How to use them (a short tour)

```
# a phone or a Linux ARM64 machine with jcmp installed (github.com/J2k-studio/Jcmp)
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s -- jbox jsh coderin makej

jsh                         # the shell: Tab takes the grey ghost text, Ctrl-J starts another line, Ctrl-D leaves
coderin hello.jk            # write:  void main() { cout << "hi\n"; }   Ctrl-S saves, Ctrl-Q quits
jcmp hello.jk -o hello && ./hello
makej init                  # a build file for a bigger project; then  makej  and  makej -j 4
```

* **jbox** makes the commands `dir cat head tail wc grep sort uniq cp mv rm mkdir rmdir touch tee seq basename dirname sleep clear env kill true false` (it links them next to itself when installed).
* **jsh** scripts: `if` / `elif` / `else`, `while`, `until`, `for`, functions, `$(command)`, `$((1 + 2))`, `test` / `[ ]`, `break` / `continue`; `jsh file.sh`, `jsh -c "commands"`.
* **coderin** keys: Shift + arrows select, Ctrl-C / X / V copy, cut, paste, Ctrl-F find, Ctrl-G go to a line.
* **jpty** runs a program on a pseudo terminal: `jpty -w 100 -h 30 /path/to/program` (for apps and tests).
* The Jaric app for Android (a terminal with sessions, tiles and these tools inside) is in the releases of this repository (`jaric-v…`).

## For the maker of a tool

**Layout:** `tools/` holds only the tools (programs); `extensions/` the extensions of coderin (`coderin -ex NAME`); the scripts `install.sh` and `install-NAME.sh` and the list `tools.txt` stay at the top (their addresses are used by `curl` and by `jget`). The `jcmp` tool brings the extension `extensions/jcmp` with it.

A tool lives in `tools/NAME/` (its source, `VERSION`, `LATEST` = the newest released version, `test.sh`, `release.sh`). A release has the tag `NAME-vX.Y.Z` with the files `NAME` and `SHA256SUMS`. Add a line to `tools.txt` (`NAME|what it is`) and `install-NAME.sh` is the same as `install.sh NAME`.

The old address `github.com/J2k-studio/Jget` leads here.

## Licences
The repository (jget, makej and the scripts) is under the licence in `LICENSE`. **jsh, jbox, jpty and coderin** are under the Mozilla Public License 2.0: each of their folders has its own `LICENSE`.
