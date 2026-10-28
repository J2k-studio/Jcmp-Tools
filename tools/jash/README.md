# jash: the settings of your programs in one file

Like the rc files of bash, but one plain file for all the programs of Jaric, and a command to read and change it. The file is `~/.jash` (`JASH_FILE` names another one). The first line is `[#jash]`; then `[section]` lines (one per program: `jsh`, `app`, `mujic` ...) and `key = value` lines; `#` starts a comment.

```
[#jash]
[jsh]
color_mark = sky
[app]
theme = black
font = 11
```
```
jash list [SECTION]          every setting (or the ones of a section)
jash get jsh.color_mark      one value (nothing and exit 1 when it is not set)
jash set app.font 12         set one;   jash unset app.font   remove one
jash edit                    open the file with coderin (or $EDITOR);   jash path   where it is
jash import                  take in the older files: $PREFIX/etc/config.local, theme.toml and the JSH_COLOR_* of ~/.jshrc
jash reset                   empty the file (the old one is kept as .jash.old)
```
A program reads its settings with `jash get SECTION.KEY`; a script can too: `color=$(jash get jsh.color_mark)`. A `.jash` file is not a script: `jsh file.jash` refuses to run it.

## Install
```
jc install jash                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jash     # with curl
```
In jsh: `jc install jash`.

## A short lesson
1. Set something: `jash set jsh.color_mark sky`, then look: `jash list`.
2. Read it in a script: `jash get jsh.color_mark` prints `sky`.
3. Change by hand: `jash edit` (coderin opens the file; keep the `[section]` lines).
4. You have older settings (`config.local`, `~/.jshrc`)? `jash import` takes them in; the old files are not changed.
5. Start again: `jash reset`.

License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.2.0.0 or newer). Test: `sh test.sh`.
