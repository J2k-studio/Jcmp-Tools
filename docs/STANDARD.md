# The standard of the tools of Jcmp-Tools

Every tool follows these rules. A new tool is not released until it passes the checklist at the end.

## What a tool does on the command line
1. `NAME --version` (also `-V`) prints one line `NAME X.Y.Z` and exits 0. The number is the same as the file `VERSION` (the test checks it).
2. `NAME --help` (also `-h`, unless the tool uses `-h` for something else, then only `--help`) prints the usage on the screen, **even when there is no terminal**, and exits 0.
3. Errors go to the error output as `NAME: what went wrong` (English, one line, no stack); the exit code is **1** when the work failed, **2** when the command line was wrong, **0** when it worked. A tool never prints a message on success unless it is its job (`-q` makes it silent).
4. Colours and cursor movement only when the output is a terminal and `NO_COLOR` is not set.
5. A tool that reads text reads the input when there is no file (a pipe works). A path of `-` means the input or the output.
6. A destructive action (remove, overwrite) asks, or needs a flag (`-f`), or refuses; it never deletes silently.

## Where things live
* Settings: one plain text file per tool, `~/.config/NAME/config` (key = value, `#` comments); the shell `~/.jshrc`; the Jaric app `usr/etc/config.local` and `theme.toml`. Settings can be changed by hand and by a screen (`jaric setting`); never only by a screen.
* Data: `~/.local/share/NAME/`; songs `~/music`; libraries `~/.j2k/Library`; the cache of the compiler `~/.j2k/cache`.
* Names of environment variables: `NAME_THING` in capitals (`MUJIC_DIR`, `JSH_COLOR_MARK`); `NO_COLOR`, `HOME`, `PATH`, `TMPDIR` as everywhere.

## The folder of a tool (tools/NAME/)
`NAME.jk` (+ parts), `README.md` (what it is, examples, license), `CHANGELOG.md` (newest first), `VERSION`, `LATEST` (the released version), `LICENSE` (MPL-2.0), `build.sh`, `test.sh`, `release.sh`. The tests need no network (or say so and skip).

## Versions and releases
* `X.Y.Z`: Z = a fix, Y = something new, X = a break (not before 1.0). One number in `VERSION`; the program prints it; the changelog has a section for it. **The version text in the source must be changed together with `VERSION`** (jsh 0.5.1 to 0.6.0 printed 0.5.0 because it was not: `test.sh` now checks `NAME --version` against `VERSION`).
* A release is the tag `NAME-vX.Y.Z` in Jcmp-Tools with the file `NAME` and `SHA256SUMS`; `release.sh` builds, tests, writes the sums. `install.sh NAME` and `jc install NAME` check the sums.
* A tool built for the Jaric app is built from the same source (no copy that differs): `build_app.sh` takes `~/jget/tools/*`; the only other copy (`os/userland/shell/jsh.jk` in Jaric) is replaced by the tool's file at every release.

## Checklist before a release
- [ ] `--version`, `--help` work, also from a pipe; exit codes as above
- [ ] `VERSION`, the text in the source, `CHANGELOG.md` and `README.md` agree
- [ ] `test.sh` passes (and checks the version)
- [ ] Each option is in `--help` and in `docs/GUIDE.md` with an example
- [ ] No file is read or written outside the folders above unless the user named it

## The options that mean the same in every tool (central standard, 2026-10-27)
| Option | Meaning | Rule |
|---|---|---|
| `--version`, `-V` | `NAME X.Y.Z` | exit 0 |
| `--help`, `-h` (`help` as a word where the tool has words) | the usage | to the screen, exit 0, also without a terminal |
| `-q` | quiet: only errors | |
| `-v` | verbose: say what is done | |
| `-y` | yes to every question | with no terminal and no `-y`, a tool that must ask refuses and says `use -y` |
| `-n` | dry run: show what would be done, do nothing | |
| `-o FILE` | the output file (`-` the screen) | |
| `-j N` | N jobs; `-j` alone = all cores | |
| `--no-color` / `NO_COLOR` | no colours | colours only at a terminal |
A tool uses a letter above for another meaning only if it says so in `--help`. A command word (`install`, `list`, `remove`, `update`, `info`) means the same everywhere: `list` shows, `info X` explains one, `install X` adds, `remove X` takes away, `update` brings up to date.

## Paths and drives
A tool takes the paths as the shell gives them: `jsh` turns `f:/jaric`, `:/x`, `0:/Download` into real paths **before** the tool starts, so a tool never parses drives itself. A tool that prints a path for people prints it as the real path unless it is the shell (prompt, `pwd`), which prints the drive form (`f:/jaric`).

## Settings of a tool
Defaults need no file. A setting is read in this order: the command line, the environment (`NAME_THING`), the file `~/.jash` section `[NAME]` (`jash get NAME.key`), the built-in default. The tool never writes `~/.jash` by itself; `jash set` and `jaric setting` do.

## The README of a tool (this order)
1. `# name: one line of what it is`, then a paragraph and the usage block (every option, as in `--help`).
2. What it does not do yet (said plainly).
3. `## Install` with **both** `jc install NAME` and `curl -fsSL .../install.sh | sh -s NAME` (jc is the installer; jget is only the downloader since jget 1.0.0).
4. `## A short lesson`: 4 to 6 numbered steps that a new person can follow.
5. A line `License: ...` (the file `LICENSE` of the tool, or "the license of the repository" when the tool has none of its own), the build line and the test line.

## The checks
`./check-standard.sh [NAME...]` checks every rule that a machine can check (files, versions, README sections, the table, `tools.txt`, `install-NAME.sh`, `--version` and `--help` of the built program) and its exit code is the number of tools with problems. Run it before every release; a release with a problem in it is not made.

## Checklist before a release (added)
- [ ] `./check-standard.sh NAME` prints `ok`
- [ ] the GitHub release has the notes of the section of `CHANGELOG.md` (Added / Changed / Fixed)
- [ ] `install-NAME.sh` and the line in `tools.txt` exist; the table of `README.md` links the README of the tool

## Install, update, remove
`jc install NAME`, `jc unstall NAME`, `jc update [-n]` do the work themselves (the code is `manage.j`, the downloads `core.j`); `update` compares `versions.txt` (written by `check-standard.sh`) with the installed versions, so a release must run `check-standard.sh` and publish `versions.txt`.

## The guide of a tool
A README is the front page; a tool with more than a few commands also has a **guide**: a section `## Commands` in the README, or a file `docs/GUIDE.md`, that goes through **every command and option with an example**, shows a step by step lesson for each big feature (for example an Android app with `makej init -apk`), and has a table of the error messages and what to do. `check-standard.sh` prints a note for a tool that has neither. (Written so far: makej.)
