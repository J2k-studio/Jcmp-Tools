# Changelog

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
