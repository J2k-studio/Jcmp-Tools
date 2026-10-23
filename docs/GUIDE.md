# The guide: every command, with examples

For the Jaric app and any Linux ARM64 terminal. `NAME --help` or `help` inside `jsh` gives the short form; this is the long one. Every example is run in `jsh` unless it says otherwise.

## 1. jsh: the shell
**Typing.** Arrows move; Home / End (or Ctrl-A / Ctrl-E) go to the ends; Delete and Backspace erase one letter (a Thai vowel alone); Ctrl-U erases the line; Ctrl-C cancels; Ctrl-D on an empty line leaves. Up / Down walk through the history. The **grey text** after the cursor is a guess (the newest history line that continues yours, else a command or file name): **Tab** takes it; with no guess, Tab shows the choices and fills what they share. Ctrl-J starts another line of the same command (Enter runs all).

**Running things.**
```
echo hello world           # a built-in
ls -l                      # no ls in the PATH: jsh runs the jbox command (dir -l is the same)
a ; b                      # a, then b
a && b                     # b only if a worked
a || b                     # b only if a failed
long_job &                 # in the background;  jobs  lists, wait  waits
```
**Pipes and files.**
```
cat notes.txt | grep todo | sort | uniq   # the output of one is the input of the next
echo one > f.txt           # write (replaces)
echo two >> f.txt          # add to the end
sort < f.txt               # read from a file
prog 2> errors.txt         # the errors of prog go to a file
prog > all.txt 2>&1        # output and errors to one file      (also:  prog &> all.txt)
echo oops 1>&2             # write to the errors
cat <<EOT                  # a here-document (in a script or several lines): until the line EOT
text with $HOME
EOT
cat <<<"one line"          # a here-string
```
**Variables and quoting.**
```
NAME=jao                   # or  export NAME=jao  (programs you start see it)
echo "hi $NAME" 'no $NAME' # "..." expands $, '...' does not
echo $?                    # the status of the last command (0 = worked)
echo $(date)               # the output of a command inside a word
echo $((2 + 3 * 4))        # arithmetic: + - * / %  ( )  < > <= >= == !=
ls *.txt  ?.log            # globs
cd ~/notes ; pwd
alias ll="ls -l"           # aliases;  unalias ll
```
**Scripts** (a file `build.jsh`, run with `jsh build.jsh` or `source build.jsh`):
```
#!/usr/bin/env jsh
name=$1
if [ -f "$name" ]; then
    echo "$name is a file"
elif [ -d "$name" ]; then
    echo "$name is a folder"
else
    echo "no $name"
fi
for f in *.jk; do echo "building $f"; jcmp $f -o ${f%.jk}; done      # (the ${..%..} cut is not there yet: use  jcmp $f -o out )
i=0
while [ $i -lt 3 ]; do i=$((i+1)); if [ $i -eq 2 ]; then continue; fi; echo i=$i; done
greet() { echo "hello $1"; return 0; }
greet world
read ANSWER                # reads a line from the keyboard
```
`test` / `[ ]`: `-f -d -e -z -n`, `= !=`, `-eq -ne -lt -gt -le -ge`, `!`. Other built-ins: `cd pwd echo history export unset env type which source exit help install`.
`install` alone lists the tools; `install jcmp coderin` fetches them (with `jget`). In the Jaric app also: `jaric theme NAME`, `jaric font SIZE`, `jaric core`.

## 2. jbox: the small commands
Run as `ls`, or `jbox ls`. A file name `-` (or none) means the input from a pipe.
| Command | Does | Examples |
|---|---|---|
| `dir` (`ls`) | list a folder; `-a` also hidden, `-l` long | `dir -a ~` |
| `tree` | the tree of a folder; `-a`, `-L N` depth | `tree -L 2 src` |
| `date` | the time now (UTC); `date +%s` the seconds since 1970 | `date` |
| `du` `stat` | the bytes under a folder (`-h` readable); size of a file | `du -h ~/src` |
| `xargs` | the words of the input become more arguments | `find . -name '*.tmp' \| xargs rm` |
| `sed` | replace in every line: `sed 's/old/new/g'` (plain text, not a pattern) | `sed 's/foo/bar/' f.txt` |
| `less` | one page at a time: space next, `b` back, Enter a line, `q` quit | `less long.txt` |
| `find` | `find [FOLDER] [-name PATTERN] [-type f\|d] [-maxdepth N]` | `find . -name '*.jk'` |
| `cat` | show files | `cat a.txt b.txt` |
| `head` `tail` | first / last lines, `-n N` | `tail -n 20 log.txt` |
| `wc` | count; `-l` lines `-w` words `-c` bytes | `cat f \| wc -l` |
| `grep` | lines with a text; `-n` numbers `-v` the others `-i` any case | `grep -n todo *.jk` |
| `sort` `uniq` | sort lines (`-r` backwards); drop repeated neighbours | `sort -r words \| uniq` |
| `cut` | one field: `cut -d : -f 2` | `cut -d , -f 3 data.csv` |
| `tr` | change letters: `tr abc xyz`; delete: `tr -d ' '` | `echo hello \| tr l L` |
| `diff` | `< only in the first`, `> only in the second`; status 1 if different | `diff old.txt new.txt` |
| `tee` | show and write (`-a` add) | `make \| tee build.log` |
| `cp` `mv` `rm` | copy, move, remove (`rm -f` no questions) | `cp a.txt b.txt` |
| `mkdir` `rmdir` `touch` | make a folder (`-p` with parents), remove an empty one, make or touch a file | `mkdir -p a/b/c` |
| `ln -s` | a symbolic link: `ln -s TARGET LINK` | `ln -s /sdcard sd` |
| `chmod` | `chmod 755 f`, `chmod +x f` | `chmod +x run.jsh` |
| `basename` `dirname` | the last part / the folder of a path | `basename /a/b.txt` |
| `seq` | numbers: `seq 5`, `seq 2 6` | `for i in $(seq 3); do echo $i; done` |
| `sleep` `clear` `env` `kill` `true` `false` | wait seconds; clear the screen; show the environment; `kill [-9] PID`; always 0 / 1 | |

## 3. coderin: the editor
`coderin FILE` (a new name makes a new file). Quit: **Ctrl-Q** (twice, or `q!`, when there are unsaved changes). Save: **Ctrl-S**.
* **Move and select**: arrows; Home / End; PageUp / PageDown; **Shift + arrows** select; the mouse (a tap is a click, drag selects, double click takes a word, the wheel / a swipe scrolls).
* **Edit**: Ctrl-C copy, Ctrl-X cut, Ctrl-V paste (the copy also goes to the phone's clipboard), Ctrl-Z undo, Ctrl-Y redo, Ctrl-F find, Ctrl-G go to a line, Ctrl-A select all, Ctrl-D duplicate the line; brackets and quotes close themselves (`(` gives `()`).
* **The command bar (Ctrl-E)**: `save`, `quit`, `q!`, `goto 120`, `find text`, `replace old new`, `set tabsize 2`, `bind Ctrl-s save`, `check` and `next` (errors of the compiler), `run NAME` (a command of an extension), `extensions` (what is loaded), `help`.
* **Settings** in `~/.config/coderin/` (none is made for you): `settings` (`tabsize = 4`, `tabstospaces`, `ruler`, `autoindent`, `autopair`, `helpbar`, `mouse`, `colorscheme = dark|light|mono|amber`), `bindings` (`Ctrl-s = save`), `colors/NAME` (`background = #0D1117`, `keyword = #FF7B72` ...).
* **For J2K**: Tab at the start of a line after `main`, `for`, `while`, `if`, `ife`, `struct`, `enum`, `switch`, `try`, `cout`, `fn`, `exp` writes a snippet; two letters of a word show a **list of words** (Down / Up, Tab or Enter take, Esc closes); saving a `.jk` file runs the compiler and marks the lines with an error in red.
* **Extensions**: `coderin -ex` lists them, `coderin -ex python` installs one (into `~/.config/coderin/extensions/python/`), `coderin -ex -r python` removes it. Your own: a folder with `snippets` (`prefix = body`, `\n` new line, `|` the cursor), `words`, `commands` (`name = shell command`, `%f` the file).

## 4. jget: download
```
jget https://example.com/f.tar.gz        # saved as f.tar.gz  (a progress bar shows)
jget URL -o name.ext                      # another name   (-o - : to the screen)
jget -sh URL arg1                         # download a script and run it
jget tool list                            # the tools of Jcmp-Tools
jget tool coderin jsh jbox                # install tools next to jget (checked with SHA-256)
jget -li list                             # libraries of the J2K language
jget -li install NAME / unstall NAME
jget --update                             # replace jget by the latest release
```
In the Jaric app no `curl` is needed: `install coderin` in `jsh` does `jget tool coderin`.

## 5. makej: build projects
`makej init` writes a file `makej`; `makej init -ai` writes an AI project that uses the library `neuron` (`jget -li install neuron`; steps `train` on `data/data.csv` and `ask`). Then:
```
makej                 # build everything          makej -j 4   # 4 jobs at once
makej NAME            # one target and what it needs      makej -v   # show the commands
```
The file (TOML): `[program.NAME] main = "src/a.jk" flags = ""`, `[library.NAME] main = "x.jk" flags = "-l"`, `[step.NAME] run = "sh test.sh" needs = "NAME"`. A program is built again only when a `.jk` / `.j` file below its folder is newer.

## 6. jcmp: the language
```
jcmp hello.jk -o hello      # compile      ./hello
jcmp prog.jk -d -o prog     # with checks of memory and indexes
jcmp prog.jk -target arm32 -o prog32
jcmp lib.jk -l -o lib.so    # a shared library (functions marked export)
jcmp prog.jk -show main     # the code of one function
jcmp -version
```
A first program:
```
#import <stdlib>
void main() {
    cout << "hello\n";
}
```
`install jcmp` (in `jsh`) brings the compiler and its library. The tutorial and the reference are in the repository of the language.

## 6b. zipj, unj, tarj, gzj: archives
Install: `jget tool zipj`, `jget tool tarj` (each also makes its second name: `unj`, `gzj`).
```
unj test.zip                open here, no folder          unj test.zip -f   into a folder named test
unj test.zip -o dest        into dest                     unj test.zip -l   only list
unj test.zip -p secret      a password (without -p it is asked, nothing is shown)
zipj out.zip a.txt folder   make a zip                    zipj out.zip a -P secret   with a password
tarj c out.tar.gz src       make a tar (.gz / .tgz: gzip too)
tarj x out.tar.gz -o dest   open (a gzip inside is found)  tarj t out.tar   list
gzj notes.txt               make notes.txt.gz              gzj -d notes.txt.gz   open it
```

## 6c. mujic: music
Install: `jget tool mujic`. Songs are in `~/music`.
```
mujic                       the player: up/down, Enter play, Space pause, n/p, left/right jump, l lyrics, g fetch, q quit
mujic catalog               free songs;   mujic get sneaky-snitch   fetch one
mujic get https://site/song.mp3 -n "My Song"      mujic find piano      mujic get archive:ID
mujic lyrics "My Song" -q "artist title"          lyrics with times, kept next to the song (My Song.lrc)
```

## 7. jpty
`jpty [-w COLS] [-h ROWS] PROGRAM args` runs a program on a pseudo terminal (so a shell or an editor sees a real terminal). It is what the Jaric app uses to start `jsh`.

## 8. The Jaric app
* `@` (top right): the tabs wait behind it; tap to show them and choose a session. `+` new, `#` tile, `x` close, hold a tab for the menu.
* Hold a word to select; drag the two handles; the bar gives Copy / Paste / Select all / Share. Pinch to change the size of the letters.
* Volume down = Ctrl (latch), volume up = Esc. The two rows of keys give Tab, arrows, Home, End, Paste.
* `usr/etc/config.local` (not made for you): `theme`, `font`, `topbar = hidden|shown`, `animation = on|off`, `animation_ms`, `animation_curve`.
