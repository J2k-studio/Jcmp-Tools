# makej: the guide (every command, with examples)

`makej` has two jobs: it **builds** (the build file `makej` in the project) and it **starts and packs projects** (`makej init ...`, `makej apk`, `makej pack`, `makej dist`). This guide goes through all of it. Needs `jcmp` 1.2.0.0 or newer (`jc install jcmp`).

## 1. Start a project: `makej init`

| Command | What you get |
|---|---|
| `makej init` | one file `makej` (the build file) in the current folder |
| `makej init -pro NAME` | a real project: `src/`, `tests/`, `docs/`, `scripts/`, `manifest.toml`, `README.md`, `CHANGELOG.md`, a build file with `run`, `test`, `pack` |
| `makej init -game` | a game for the library `gamej` (Jaric Engine): `src/main.jk`, five lessons, `assets/`, `manifest.toml` |
| `makej init -apk` | the same as `-game` with `os = "android"`: a project that becomes an Android app |
| `makej init -ai` | a small AI project for `neuron`: `data/chat.txt`, `makej train`, `makej chat` |
| `makej -pro`, `-game`, `-apk`, `-ai` | the same, without the word `init` |

`makej init` never overwrites: if the file `makej` is there already it says so and stops.

## 2. Build and run

```
makej                 build everything that changed (the target all)
makej NAME            build one target and what it needs first (makej test, makej run)
makej list            the targets and what each one needs
makej -n              show what would be done, do nothing
makej -v              show the commands as they run
makej -j 4            build 4 things at once (no number: one per core)
makej clean           remove the folder of the results (_out/)
makej install DIR     build, then copy the programs to DIR
```
A program is built again only when a `.jk` / `.j` file below the folder of its main file is newer than the result.

## 3. An Android app: `makej init -apk`, step by step

**What it is.** `makej apk` makes a real `.apk` of your program: a small Android runner (a screen with the terminal of Jaric), your compiled program, `jpty` and your `assets/`. It runs on the phone without Jaric installed.

**Before the first time (once).**
1. Tools: `pkg install aapt2 ecj dx apksigner zipalign openjdk-17` (in Termux). `makej init -apk` prints which ones are still missing.
2. `android.jar` (from the Android SDK, `platforms/android-34/android.jar`): put it in the project folder, or in `~/android.jar`, or set `ANDROID_JAR=/path/android.jar`.
3. `jpty`: `jc install jpty`. The library of the game: `jc lib install gamej`.

**Step by step.**
```
mkdir mygame && cd mygame
makej init -apk                 # writes makej, manifest.toml, src/main.jk, lessons/, assets/
coderin src/main.jk             # your program (it starts as a small window with a loop)
makej run                       # try it in the terminal first (Esc ends it)
coderin manifest.toml           # name, id, version, orientation (see below)
makej apk                       # builds _out/NAME.apk
cp _out/NAME.apk /sdcard/       # then open the file on the phone and install it
```
`makej dist` builds every system listed in `os = "..."` of the manifest (android, jaric, linux); `makej targets` lists them.

**The file `manifest.toml`.**
```
name = "My Game"               # the name under the icon; the apk is _out/My_Game.apk
id = "com.you.mygame"          # the name of the app on Android: letters, digits, dots; it needs a dot
version = "1.2.0"              # x.y.z; the version code is x*10000 + y*100 + z, so every new version must be higher
os = "android"                 # android jaric linux (any of them, separated by spaces)
orientation = "landscape"      # landscape | portrait | sensorLandscape | unspecified
controls = true                # arrows and two buttons on the screen
permissions = ["audio"]        # for a .jc package (jc asks for them); an apk does not use this line
```
* **Icon:** put `icon.png` in the project folder (a square png, 192x192 or more); without it Android shows a plain icon.
* **assets/:** every file in `assets/` is inside the apk; the program reads it from the folder `data/` next to it (`Game` finds it for you).
* **Signing:** the apk is signed with a key that `makej` makes the first time (`~/.jaric-debug.keystore`). An update installs over the old app only if it was made with the same key, so keep that file (or `MAKEJ_KEYSTORE=path`).
* **Install without a file manager:** `pm install -r _out/NAME.apk` (on a phone that allows it).

**When something goes wrong.**
| The message | What to do |
|---|---|
| `aapt2 is needed to make an apk` (or ecj, d8, zipalign, apksigner, keytool) | `pkg install aapt2 ecj dx apksigner zipalign openjdk-17` |
| `android.jar was not found` | copy it to the project folder or set `ANDROID_JAR` |
| `manifest.toml needs name, id and version` | fill the three lines |
| `the id in manifest.toml needs a dot` | `com.you.mygame`, not `mygame` |
| `jpty was not found` | `jc install jpty` |
| the phone says the app is not installed | an app with the same id but another key is there: uninstall it, or use the same keystore |

## 4. A package for Jaric: `makej pack`

`makej pack` makes a `.jc` file in `_out/` (the test builds `_out/game.jc`): a zip with `manifest.toml`, the program and `assets/`. Install it in Jaric with `jc install _out/FILE.jc` (it shows the permissions from `permissions = [...]` and asks once). `makej dist` does `pack` for `os = "jaric"` and `apk` for `android`.

## 5. A game project: the lessons

`makej play1` ... `makej play5` run the five lessons in `lessons/` (a window and a loop, moving, gravity and jump, falling things with a score, pictures and sound). Each file is short and has comments; read it with `coderin lessons/lesson1.jk`, change a number, run it again.

## 6. An AI project: `makej init -ai`

`makej train` learns `data/chat.txt` (lines `You: ...` / `Bot: ...`) and writes `assistant.jw`; `makej chat` talks to it; `makej install` makes it the assistant of the phone (`xr "question"`).

## 7. The build file in short

A plain file `makej` (TOML): `[program.NAME]` with `main` and `flags`; `[library.NAME]` (`flags = "-l"`); `[step.NAME]` with `run` (a shell command) and `needs`. For loops and conditions write `makej.jk` instead (`Build b = Build::make(); b.program(...); return b.run();`). The README of this tool has both forms with examples.
