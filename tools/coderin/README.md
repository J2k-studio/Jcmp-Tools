# coderin: a text editor for the terminal, in the way of micro and nano

Written in J2K, for the Jaric app and any ANSI terminal (alternate screen, 24-bit colours, the mouse). When you quit, the terminal is as it was.

```
coderin FILE
```

* **The mouse** (in the Jaric app a tap is a click): a click puts the cursor there, a drag selects, a double click takes a word, the wheel (a swipe in the app) scrolls.
* **Brackets and quotes are closed for you**: `(` gives `()`, also `[]`, `{}`, `""`, `''`; typing the closing one steps over it; Backspace between a pair removes both; Enter between `{` and `}` opens a block.
* **Keys** (as in nano): the line under the text shows them. Arrows, Home, End, PageUp, PageDown; Shift + arrows select; Ctrl-C / X / V copy, cut, paste (the copy also goes to the clipboard of the Jaric app, OSC 52); Ctrl-A select all; Ctrl-D copy the line below; Ctrl-K delete the line; Ctrl-F find; Ctrl-G go to a line; Ctrl-Z / Ctrl-Y undo, redo; Ctrl-S save; Ctrl-Q quit (a second Ctrl-Q quits without saving); Ctrl-E the command bar.
* **The command bar** (Ctrl-E): `save`, `quit`, `q!`, `goto N`, `find TEXT`, `replace A B`, `set NAME VALUE`, `bind Ctrl-x ACTION`, `help`.
* **Settings** (like micro) in `~/.config/coderin/` — no file is made for you; `set NAME VALUE` writes the file `settings`:
  * `settings`: lines `name = value`: `tabsize`, `tabstospaces`, `ruler`, `autoindent`, `autopair`, `helpbar`, `mouse` (on / off), `colorscheme` (`dark` `light` `mono` `amber`, or the name of a file in `colors/`).
  * `bindings`: lines `Ctrl-s = save`. Actions: `save quit find goto copy cut paste selectall duplicate deleteline command undo redo`.
  * `colors/NAME`: lines `keyword = #RRGGBB` (`keyword string number comment type text gutter selection`).
* Colours for J2K, line numbers, auto indent.

* **Extensions** (switch them with  `extensions = undo j2k`  in the settings; both are on): **undo** (Ctrl-Z) and **redo** (Ctrl-Y), typing and deleting in one go are one step; **j2k**: Tab after `main`, `for`, `while`, `if`, `ife`, `struct`, `enum`, `switch`, `try`, `cout`, `fn` or `exp` at the start of a line writes the snippet and puts the cursor in it, and Tab after the start of a word (2 letters or more) completes it with the words of J2K and of the text (the common start; again to see the choices).

**Your own extensions**: a folder `~/.config/coderin/extensions/NAME/` (or `DIR/coderin-extensions/NAME/` for a `DIR` on the PATH: a tool can bring one, the `jcmp` tool does) with up to three text files:
* `snippets`: lines `prefix = body` (`\n` is a new line, `|` is where the cursor goes). Tab after the prefix at the start of a line.
* `words`: words for the Tab completion.
* `commands`: lines `name = shell command` (`%f` is the file). Ctrl-E then `run name`; the last line of the output shows in the status line. `extensions` lists what is loaded.

**A list of words under the cursor, as in VS Code** (extensions on): type 2 letters or more and a small list shows the words that continue it (J2K, the extensions, the text). Down / Up choose, Tab or Enter take the word, Esc closes, any other key goes on typing.

**Errors of the compiler** (extension j2k, `jcmp` on the PATH): saving a `.jk` / `.j` file runs `jcmp` on it; the lines with an error get a red number with `!`, the cursor goes to the first error and the status line says it (`error 1/2 line 5: ...`). Ctrl-E then `next` shows the next one, `check` runs the compiler again.

Not yet: several files.

```
sh build.sh      # needs jcmp 1.0.0.0 or newer (JCMP=path chooses the compiler)
sh test.sh
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).

## Install
```
jc install coderin                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s coderin     # with curl (no jget needed)
```
In jsh: `jc install coderin`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Open or make a file: `coderin hello.jk`. Type: brackets close for you; Tab after `main` writes a program skeleton.
2. Save with Ctrl-S. Errors of the compiler show as red `!` numbers after a save (when `jcmp` is installed).
3. Move and select: arrows; Shift + arrows select; a click puts the cursor, a drag selects. Copy Ctrl-C, cut Ctrl-X, paste Ctrl-V, undo Ctrl-Z.
4. Find Ctrl-F, go to a line Ctrl-G; the command bar Ctrl-E: `replace old new`, `set tabsize 4`, `colorscheme light`.
5. Quit with Ctrl-Q (twice to leave without saving).
