# Changelog

## 0.9.0
* **Added:** `makej init -apk` (and `makej -apk`) starts an Android app project: the game project of `-game` with `os = "android"` in `manifest.toml`. Before, `-apk` was not known and it wrote a bare `makej` file only. At the end it lists the tools that `makej apk` needs and that are still missing (aapt2 ecj d8 zipalign apksigner keytool, android.jar).

## 0.8.9
* **Fixed:** `makej --help` (and `-h`, `help`) prints the usage and exits 0 (it looked for the build file).
* The README names the license (the one of the repository).

## 0.8.8
* **Added:** the manifest of a game project has a line `permissions = ["audio"]` (what the package asks for; `jc install` shows it and asks once; the names are in the comment). Install a package with the tool `jc`: `jc install _out/game.jc`, `jc run game`.

## 0.8.7
* **Changed:** the progress bar is smooth and in proportion: `hello ▕██████████▌░░░░░░░░░░░▏  62%` — blocks that fill the whole cell with steps of 1/8 of a cell, a dim track, the percent in a column of fixed width, the names of the targets in a column, the bar up to 30 cells wide. Green while working, yellow after 60%, red when full. `MAKEJ_BAR=ascii` brings back the old `[|||   ]` for a font without block letters.
* The core bars (when jcmp runs on many cores) use the same form.

## 0.8.6
* **Changed:** the bars look like a real progress meter, `[||||||||      ] 62%`: green while the work goes on, yellow after 60%, and **red when the bar is full (100%)**; colours only at a terminal.
* **Changed:** `makej -j` alone builds with as many jobs as there are cores (like `make -j$(nproc)`); `makej -j N` still takes a number. (Before, `-j` as the last word was taken as the name of a target.)

## 0.8.5
* **Changed:** the steps of an -ai project (`makej train`, `chat`, `install`) install the program `neuron` themselves (`jget tool neuron`) when it is not there, so nothing has to be installed by hand first. (The library `neuron` of `jget -li` is a different thing and is not needed.)

## 0.8.4
* **Fixed:** `makej init -ai` wrote a numeric example program (`src/chat.jk`, `data/data.csv`) that a bare `makej` built, and it failed with "library not found 'neuron'" when the library was not installed. The project now has only `makej` and `data/chat.txt`; the steps `train`, `chat`, `install` run when named. Older -ai projects: delete the `[program.numeric]` and `[step.numeric_*]` parts of the file `makej`, or run `makej train` directly.

## 0.8.3
* **Added:** when jcmp is too old, makej at a terminal asks "update jcmp now with jget tool jcmp ? [Y/n]" and does it (`MAKEJ_UPDATE_JCMP=yes` without asking, `=no` never). Without jget or a terminal it prints the command.

## 0.8.2
* **Fixed:** with an old compiler (jcmp 0.9.x or 1.0) makej printed a wall of errors such as "unknown escape sequence: a backslash followed by 'e'" from its own library. It now checks the version first and says: "your jcmp is X; makej needs jcmp 1.2.0.0 or newer. Update it: jget tool jcmp". If jcmp is missing it says so.

## 0.8.1
* **Changed:** `makej init -ai` (also `makej -ai`) now writes a project for the tool neuron: `data/chat.txt` (a talk to learn), and the steps `makej train` (writes `assistant.jw`, the whole AI in one file), `makej chat`, `makej install` (makes it the assistant of the phone); the small numeric example stays as `makej numeric_train` / `numeric_ask`.

## 0.8.0
* **`makej pack` makes `NAME.jc`** (was `.jec`; the owner: `.jc` is the program of Jaric, short for jaric). The package is the same zip. A game gets its files through `JC_ASSETS` (`JEC_ASSETS` is still set for one more release).

## 0.7.1
* The bars of the live view follow the width of the screen (the bar of a job and one bar per core fit in a line, also on a narrow screen).

## 0.7.0
* **Bars while it builds:** on a terminal, `makej` (and `makej -j N`) shows `[||||||||      ] 62%  name  stage` for every target that runs, and under it the bars of the cores (`core 1 [|||| ] 70%  core 2 ...`) when jcmp works on many processes; a finished target stays as `[||||||||||||] 100%  name  built in 1.2 s`. What jcmp says (warnings, errors) is shown after the bars. Pipes and files get the plain lines as before.
* `makej -j N`: N targets at the same time, and the cores left over go to each jcmp (`jcmp -j K`, the compile of one big program on many processes). The default is the number of cores this process may use (not the cores of the phone: the system sometimes gives only some of them to a program that is in the background).
* Needs jcmp 1.2 for the bars and for `-j`; an older jcmp is used as before.

## 0.6.1
* `makej -pro`, `makej -game`, `makej -ai` work as `makej init -pro` and so on (the files did not appear when `init` was left out).

## 0.6.0
* `makej init -pro [NAME]`: the structure of a real project (src/ with src/lib/, tests/ with a runner, docs/, assets/, scripts/release.sh, manifest.toml, VERSION, CHANGELOG.md, README.md, .gitignore) with `makej test`, `makej run`, `makej release`.
* Systems: `makej targets`, `makej init -game -os android|jaric|linux|all`, `makej dist` (builds for the systems named in manifest.toml: android = apk, jaric = .jc of Jaric OS, linux = a folder), `makej linux`.

## 0.5.0
* `makej apk`: an Android app from a game project: the runner (GameActivity, Java) + your program + jpty + assets/ in a signed .apk (needs aapt2 ecj d8 zipalign apksigner and android.jar). `manifest.toml` gets orientation and controls (arrows and two buttons on the screen). The game library is Jaric Engine (`<gamej>`).

## 0.4.0
* `makej init -game`: a game project with the library gamej: src/main.jk (a small game), five lessons (makej play1 .. play5), manifest.toml and `makej pack` (NAME.jc, the package of a game: a zip with the manifest, the program and assets/).

## 0.2.0
* **Several cores:** `makej -j N` (default: the number of cores that are on) builds N targets at the same time, each as soon as what it needs is done; a failed target stops new ones from starting, the others finish, the exit code is 1.

## 0.1.1
* The build file is read without taking a value out of a `Result` (a compiler before 1.0 freed it twice: the first target could be built with an empty command). Works with jcmp 0.9.206 and later.


## 0.1.0
* The first version: the build file is the file `makej` (a simple TOML: `nano makej`, `makej init`) or `makej.jk` (a J2K program); programs, libraries and steps; a target is built again only when a source is newer than the result. The tool is one file (the library is inside). A prototype: the design is in docs/usage-design.md.

## Unreleased
* `makej init -ai`: an AI project (makej, src/chat.jk, data/data.json; steps train and ask).

## 0.3.0
* list, clean, -n (dry run), install FOLDER, the time of a build, targets named in the error of a wrong name, init -ai.

## 0.3.1
* init -ai makes a small project with the library neuron (train on data/data.csv, ask the model).
