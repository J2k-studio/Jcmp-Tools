# jsh: a small shell for J2K machines

A shell written in J2K, on the J2K library only. It is the shell of the Jaric project and works on any Linux ARM64 machine.

* Line editing (arrows, Home / End, Delete, Ctrl-A / E / U / D / C; UTF-8 aware, so a Thai vowel is erased alone) and history; **grey ghost text** while you type (the newest history line that continues yours, else a command or file name) and **Tab** takes it (with no ghost, Tab lists the choices); a prompt with the folder and `>>` (red `[status]` after a failure).
* Built-ins: `cd pwd echo history exit help export unset env alias unalias type which source . install`; `install coderin makej` fetches tools from Jcmp-Tools with jget (`install` alone lists them)
* Programs with arguments, found in `$PATH`; for the others jsh runs [jbox](../jbox/README.md) (`ls cat grep sort ...`).
* Pipes `a | b`, redirection `> >> <`, background `&`, `$?`, `$NAME`, `~`, globs `* ?`, quotes `'..'` `".."`, comments `#`.
* Several lines in one command: Ctrl-J (the key New line of the Jaric app) starts another line, Enter runs them all.
* Several commands on a line: `a ; b`, `a && b`, `a || b`.
* Variables: `export NAME=value`, or `NAME=value`; aliases: `alias ll="ls -l"`.
* Scripts: **`if` / `elif` / `else` / `fi`, `while`, `until`, `for NAME in WORDS`, functions `name() { ... }` with `$1 $2 ... $#` and `return`, command substitution `$(command)`, and `test` / `[ ]`** (`-f -d -e -z -n`, `= !=`, `-eq -ne -lt -gt -le -ge`, `!`). The keywords are keywords only where a command may start. Scripts: `jsh file`, `jsh -c "commands"`, `source file`; at start an interactive jsh runs `~/.jshrc`.

```
sh build.sh            # builds _out/jsh and _out/jbox (needs jcmp 1.0.0.0 or newer; JCMP=path chooses the compiler)
sh test.sh
_out/jsh
```

`break` / `continue`, arithmetic `$(( ))` (+ - * / %, ( ), < > <= >= == !=), `read NAME`, `jobs` and `wait` for the commands started with `&`, and Ctrl-C stops the loop of a script. Redirections also `2> 2>> 2>&1 1>&2 &> <<<` and here-documents (`<<EOT` in a script). Not yet: `fg` / `bg`, `${x%.y}`, arrays, a quoted `;` `&&` `||` `|` (they are always operators).

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder): use it, change it, share it; if you distribute a changed version of these files, you publish the changed files under the same licence.

## Drives
A path may start with a drive: `f:/jaric` (the drive `f` is **home**), `0:/Download` (the phone storage), `r:/etc` (the root of the system); `:/` with no letter is home, like `~/`. The prompt shows where you are: `jc f:/>` at home, `jc f:/jaric>` in `~/jaric`. More drives: `drive new music /sdcard/Music` then `cd music:/`; `drive` lists, `drive remove NAME` takes one away. A URL is never taken for a drive.

## Colours of the prompt
Put in `~/.jshrc`: `export JSH_COLOR_MARK=sky` (also `JSH_COLOR_NAME` for `jc`, `JSH_COLOR_PATH`, `JSH_COLOR_ERROR` for the mark after a failure). A value is a name (white grey black red green blue sky cyan yellow orange magenta), `#rrggbb` or `r,g,b`.

## Install
```
jc install jsh                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jsh     # with curl (no jget needed)
```
In jsh: `jc install jsh`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Start it: `jsh`. Type a few letters: the grey ghost text is the newest history line that continues them; Tab takes it.
2. Pipes and files: `ls | sort > list.txt`, then `cat list.txt`; `a && b` runs b only if a worked.
3. Variables and aliases: `NAME=world`, `echo hello $NAME`, `alias ll="ls -l"`; put the lines you want every time in `~/.jshrc`.
4. A script is a text file of commands. Put `[#jsh]` on the first line (`#jsh` and `#!jsh` work too; no line works too), then `if [ -z "$1" ]; then echo hi; else echo hi $1; fi`; save it as `hello.jsh` and run `jsh hello.jsh ana` (`$1` is the first argument, `$#` how many, `$0` the file). A file that begins with `[#jash]` is a settings file, jsh will not run it. `jget -jsh URL` downloads a script and runs it with jsh.
5. In the Jaric app: `jaric setting` for the look, `jaric theme NAME`, `jaric font 12`, `jaric -restart` to start the app again.
