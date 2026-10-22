# makej: how it is used — the design (options for the owner; nothing is locked)

The first version (a prototype, 2026-10-22) was written before this design: it shows that the idea works, it is not the design. Everything below is open.

## 1. Commands  (what the owner types)
| Command | Meaning | Prototype |
|---|---|---|
| `makej` | build the default target(s) | yes (`all`) |
| `makej NAME` | build one target and what it needs | yes |
| `makej -v` | show the commands | yes |
| `makej list` | list the targets and what they need | no |
| `makej clean` | remove `_out/` | no |
| `makej -j N` | build N things at once | no |
| `makej init` | write a starting `makej.jk` for a new project | no |
| `makej watch` | rebuild when a file changes | no |
| `makej install` | copy the results to a folder | no |

## 2. The build file — options  (rule of three: borrow, easy for a human, easy for a machine)
| Option | Look | For | Against |
|---|---|---|---|
| **A. A J2K program** (the prototype) | `Build b = Build::make(); b.program("x", "src/x.jk", ""); return b.run();` | the full language (loops, `if`, reading files), one language to learn, like `build.zig` | a few lines of boilerplate; compiled at every run (cached) |
| B. A list of lines (like a Makefile / TOML) | `program x src/x.jk` | very short to read and write | a new little language; no logic without extra rules |
| C. A J2K file with only declarations | `target x { main = "src/x.jk"; }` | short, still J2K-like | needs new syntax in the compiler (the owner's decision) |
| D. A TOML file (the library has `Toml`) | `[program.x] main = "src/x.jk"` | known format, the editor helps | no logic; two languages |
**Owner's choice (2026-10-22): A and D, both.** `nano makej` is the way to write it by hand (the file `makej`, D); `makej.jk` is for a program (A). Both are in the prototype. (Earlier recommendation: **A now** (works today, no new syntax), **D as a second front end later** for simple projects (same engine).)

## 3. Targets and rules  (what makej understands)
* Kinds: `program`, `library` (needs `jcmp -l`), `step` (any command), later `test` (a program that must exit 0) and `app` (the Android package).
* `needs(a, b)`: b is made before a. Options per target: `flags`, `target` (`arm64` / `arm32` / both), `debug` (`-d`).
* "Up to date": the prototype compares file times in the folder of the main file. Better: a hash of every file that the compiler read (jcmp can print the list of imported files) so a change in a library or in `-I` folders is seen, and nothing is built twice by touching a file.
* Output folder: `_out/` (the prototype). Alternatives: `build/`, or one folder per target (`_out/arm64`, `_out/arm32`).

## 4. Where the library is found
Now: the script `makej` puts `lib/` next to itself on `J2K_PATH`. Alternatives: `jget install makej` (a library in the index of Jcmp-libs, the usual way), or a library inside the jcmp release.

## 5. Questions (the same list in Thai: docs/open-questions.md)
1. Build file: A (J2K program), D (TOML), or both?
2. Which commands from section 1 are wanted first (the prototype has 3)?
3. Output folder name and one folder per CPU?
4. How is makej installed: `jget`, with jcmp, or by hand?
5. Does makej live in its own repository (now) or in Jcmp-Tools (with jget)?
