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
* A release is the tag `NAME-vX.Y.Z` in Jcmp-Tools with the file `NAME` and `SHA256SUMS`; `release.sh` builds, tests, writes the sums. `install.sh NAME` and `jget tool NAME` check the sums.
* A tool built for the Jaric app is built from the same source (no copy that differs): `build_app.sh` takes `~/jget/tools/*`; the only other copy (`os/userland/shell/jsh.jk` in Jaric) is replaced by the tool's file at every release.

## Checklist before a release
- [ ] `--version`, `--help` work, also from a pipe; exit codes as above
- [ ] `VERSION`, the text in the source, `CHANGELOG.md` and `README.md` agree
- [ ] `test.sh` passes (and checks the version)
- [ ] Each option is in `--help` and in `docs/GUIDE.md` with an example
- [ ] No file is read or written outside the folders above unless the user named it
