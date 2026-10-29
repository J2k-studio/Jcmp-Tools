# Changelog

## 0.5.1
* **Added:** the look comes from `jaric settings` (the file `~/.config/jaric/settings`, `coderin = devcpp|dark|light|mono|amber`) when the settings of coderin do not say; in the Jaric app with no setting at all the look is Dev-C++ (devcpp). The settings of coderin itself come first.
* **Fixed:** none.

## 0.5.0
* **Added:** the look of Dev-C++: the colour scheme `devcpp` (white page, navy keywords) with a **menu bar** (F10, or a touch: File, Edit, Search, Run, Help; arrows and Enter); **compile and run** from the editor: F9 compiles (`jcmp`), F11 compiles and runs, F5 runs, the log or the output shows in a pane under the text (Esc closes it), the lines with an error get a red number and F8 goes to the next error; **examples** (File > Examples: hello, loops, struct, read a file, arguments); the function keys F1-F12 are read (also from the key rows of the Jaric app); `set menubar on` gives the menu bar and the keys to any scheme.
* **Fixed:** none.

## 0.4.2
* Esc leaves (a second Esc when there are unsaved changes), like Ctrl-Q; an open menu or prompt takes the Esc first.

## 0.4.1
* --help and -V work (the standard of the tools: docs/STANDARD.md)

## 0.3.0
* Extensions: undo / redo (Ctrl-Z, Ctrl-Y) and j2k (snippets and the completion of a word with Tab); `extensions = undo j2k` in the settings.

## 0.2.0
* The mouse (click, drag, double click, wheel), brackets and quotes closed for you, the command bar (Ctrl-E), settings, key bindings and colour schemes in ~/.config/coderin/ (as micro), the keys shown under the text (as nano), 4 colour schemes.

## 0.1.0
* First release: edit, save, select (Shift + arrows), copy / cut / paste (also to the clipboard of the Jaric app), find, go to a line, colours for J2K, auto indent.

## Unreleased
* Extensions that you write: `~/.config/coderin/extensions/NAME/{snippets,words,commands}` and `DIR/coderin-extensions/NAME/` on the PATH; command bar `run NAME`, `extensions`.
* The j2k extension shows the errors of the compiler: after a save the lines with an error are marked, `next` / `check` in the command bar.
* A list of words under the cursor while typing (Down / Up / Tab / Enter / Esc), like VS Code.

## 0.4.0
* coderin -ex (extensions from the repository), your own extensions, errors of the compiler after a save, a list of words under the cursor, a background colour per scheme.
