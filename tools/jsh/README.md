# jsh: a small shell for J2K machines

A shell written in J2K, on the J2K library only. It is the shell of the Jaric project and works on any Linux ARM64 machine.

* Line editing (arrows, Home / End, Delete, Ctrl-A / E / U / D / C) and history; a prompt with the folder and `>>` (red `[status]` after a failure).
* Built-ins: `cd pwd echo history exit help export unset env alias unalias type which source .`
* Programs with arguments, found in `$PATH`; for the others jsh runs [jbox](../jbox/README.md) (`ls cat grep sort ...`).
* Pipes `a | b`, redirection `> >> <`, background `&`, `$?`, `$NAME`, `~`, globs `* ?`, quotes `'..'` `".."`, comments `#`.
* Several commands on a line: `a ; b`, `a && b`, `a || b`.
* Variables: `export NAME=value`, or `NAME=value`; aliases: `alias ll="ls -l"`.
* Scripts: `jsh file`, `jsh -c "commands"`, `source file`; at start an interactive jsh runs `~/.jshrc`.

```
sh build.sh            # builds _out/jsh and _out/jbox (needs jcmp 1.0.0.0 or newer; JCMP=path chooses the compiler)
sh test.sh
_out/jsh
```

Not yet: job control (`fg` / `bg`), tab completion, `if` / `while` in scripts, a quoted `;` `&&` `||` `|` (they are always operators).

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder): use it, change it, share it; if you distribute a changed version of these files, you publish the changed files under the same licence.
