# jene: make, build and run a game

`jene` makes and runs games with jex (it makes games (the engine and its libraries are in the repository Jaric-Engine).

```
jene -c NAME    new project in the folder NAME (a game that runs)
jene -b         build the project of this folder (bin/)
jene -rc        run it in the console
jene -rec       reset the cache
```
The project file `NAME.jene` is short TOML. `jene` calls the compiler `jcmp`, the compiler comes with `ex install jexcmp`.
License: MPL-2.0. Build: `JCMP=path sh build.sh`. Test: `sh test.sh`.

## A short lesson
```
jene -c snake      # the folder snake/ with snake.jene and a small game
cd snake
jene -b            # builds bin/snake with the compiler
jene -rc           # runs it in the console: the arrows move, Esc ends
```
The game source is in `src/`; the first game is a square that the arrows move.

## Install
```
ex install jene
curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install.sh | sh -s jene
```
