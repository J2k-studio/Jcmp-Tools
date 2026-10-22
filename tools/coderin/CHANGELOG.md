# Changelog

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
