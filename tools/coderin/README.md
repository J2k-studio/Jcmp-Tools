# coderin: a text editor for the terminal, in the way of micro and nano

Written in J2K, for the Jaric app and any ANSI terminal (alternate screen, 24-bit colours, the mouse). When you quit, the terminal is as it was.

```
coderin FILE
```

* **The mouse** (in the Jaric app a tap is a click): a click puts the cursor there, a drag selects, a double click takes a word, the wheel (a swipe in the app) scrolls.
* **Brackets and quotes are closed for you**: `(` gives `()`, also `[]`, `{}`, `""`, `''`; typing the closing one steps over it; Backspace between a pair removes both; Enter between `{` and `}` opens a block.
* **Keys** (as in nano): the line under the text shows them. Arrows, Home, End, PageUp, PageDown; Shift + arrows select; Ctrl-C / X / V copy, cut, paste (the copy also goes to the clipboard of the Jaric app, OSC 52); Ctrl-A select all; Ctrl-D copy the line below; Ctrl-K delete the line; Ctrl-F find; Ctrl-G go to a line; Ctrl-S save; Ctrl-Q quit (a second Ctrl-Q quits without saving); Ctrl-E the command bar.
* **The command bar** (Ctrl-E): `save`, `quit`, `q!`, `goto N`, `find TEXT`, `replace A B`, `set NAME VALUE`, `bind Ctrl-x ACTION`, `help`.
* **Settings** (like micro) in `~/.config/coderin/` — no file is made for you; `set NAME VALUE` writes the file `settings`:
  * `settings`: lines `name = value`: `tabsize`, `tabstospaces`, `ruler`, `autoindent`, `autopair`, `helpbar`, `mouse` (on / off), `colorscheme` (`dark` `light` `mono` `amber`, or the name of a file in `colors/`).
  * `bindings`: lines `Ctrl-s = save`. Actions: `save quit find goto copy cut paste selectall duplicate deleteline command`.
  * `colors/NAME`: lines `keyword = #RRGGBB` (`keyword string number comment type text gutter selection`).
* Colours for J2K, line numbers, auto indent.

Not yet: undo / redo (planned as an extension), several files.

```
sh build.sh      # needs jcmp 1.0.0.0 or newer (JCMP=path chooses the compiler)
sh test.sh
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).
