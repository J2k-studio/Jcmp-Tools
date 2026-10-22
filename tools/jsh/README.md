# jsh: a small shell for J2K machines

A shell written in J2K, on the J2K library only. It is the shell of the Jaric project and works on any Linux ARM64 machine.

* Line editing (arrows, Home / End, Delete, Ctrl-A / E / U / D / C; UTF-8 aware, so a Thai vowel is erased alone) and history; **grey ghost text** while you type (the newest history line that continues yours, else a command or file name) and **Tab** takes it (with no ghost, Tab lists the choices); a prompt with the folder and `>>` (red `[status]` after a failure).
* Built-ins: `cd pwd echo history exit help export unset env alias unalias type which source .`
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

`break` / `continue`, arithmetic `$(( ))` (+ - * / %, ( ), < > <= >= == !=), `read NAME`, `jobs` and `wait` for the commands started with `&`, and Ctrl-C stops the loop of a script. Not yet: `fg` / `bg`, here-documents, a quoted `;` `&&` `||` `|` (they are always operators).

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder): use it, change it, share it; if you distribute a changed version of these files, you publish the changed files under the same licence.
