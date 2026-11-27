# fcode: a modern code editor for the terminal (design, waiting for the owner's approval)

Name: **fcode** (the owner, 2026-11-27). It takes the place of coderin, the editor of today.

## Intent
The owner moves their work into exshell and writes code there. They want an editor like VS Code in the terminal: the same keys and command
names, extensions, usable on a phone. They chose approach A below on 2026-11-27.

## Goals
* The keys and the command names of VS Code, so that nothing has to be learned twice.
* Extensions that are installed with `ex install`, in our own format, able to read VS Code themes and snippets.
* Language help through the Language Server Protocol (LSP).
* Good on 40 columns with touch, and on a wide screen with a keyboard.

## Not goals
* Running VS Code extensions (`.vsix`, JavaScript) or being a copy of the whole VS Code window.
* `code-server` is not part of this; it can become a separate package later.

## Failure looks like
Slower than coderin today; needing a mouse; anything that does not fit 40 columns; losing text (a crash must leave a recovery copy).

## Approaches considered
| | What | Trade-off |
|---|---|---|
| **A (chosen)** | Our own editor and extension format, VS Code keys, themes, snippets, LSP | Light and ours; Marketplace extensions do not run |
| B | The real VS Code as a package (`code-server`) | Most extensions work; needs Node.js and a browser, heavy, not a CLI |
| C | Our own host for VS Code extensions | Years of work |

## What the person sees (40 columns)
```
 main.jex ● | util.j            ×
  1 fn main() {
  2     jout << "hi" << nl;
  3 }
 ┌ > format ───────────────────┐   F1 or Ctrl+Shift+P: the command palette
 │ Format Document       S+A+F │   Ctrl+P: open a file by a few letters
 └─────────────────────────────┘
 Ln 2, Col 9   spaces:4   jex  ✓0 !0
```
The file tree (Ctrl+B) covers the text on a narrow screen and sits at the side on a wide one.

## Parts (each its own file, each tested alone)
* **buffer**: the text, many cursors, undo and redo, recovery copy.
* **screen**: draws only what changed; widths of Thai and wide characters; never writes past the width.
* **keys**: reads the escape sequences, also the form that tells Ctrl+Shift+key apart.
* **commands**: one table by the VS Code id (`workbench.action.quickOpen`, `editor.action.commentLine` ...); keys, palette and extensions all call it.
* **config**: `settings.json` and `keybindings.json` in the form of VS Code (the keys we support; others are listed as ignored).
* **highlight**: today's highlighter, its languages described by data that an extension can add.
* **extensions**: a folder with a manifest that *contributes* themes, snippets, languages, keybindings, commands (any program) and language servers.
* **lsp**: JSON-RPC over the standard input and output of a server (errors, completion, hover, go to definition).

## Keys
VS Code defaults where a terminal can send them: Ctrl+S, Ctrl+P, F1 and Ctrl+Shift+P, Ctrl+F, Ctrl+H, Ctrl+G, Ctrl+/, Ctrl+D (select the next same
word; today it copies the line, which moves to Shift+Alt+Down), Alt+Up/Down (move the line), Ctrl+B, Ctrl+W (close the tab),
Ctrl+PageUp/PageDown (tabs). A terminal cannot tell Ctrl+Shift+P from Ctrl+P by itself: exshell gets the "modify other keys" mode (a change of the
app); everywhere else F1 opens the palette.

## Stages (each one is released and usable)
1. **Daily editor**: the parts above without extensions: tabs, tree, quick open, palette, many cursors, replace, the new keys. It replaces coderin
   only when it does everything today's editor does (save, find, undo, selection, clipboard, mouse, brackets, run and compile, next error).
2. **Make it yours**: settings and keybindings, themes and snippets of VS Code, extensions from `ex install fcode-ext-NAME` (today's
   `snippets`, `words`, `commands` folders keep working).
3. **Language help**: LSP, first `clangd` (package clang) and `pylsp` (python); a server for Jex later (a language task, paused now).
4. **Extension commands**: programs that talk to the editor (JSON in and out) to add features.

## Constraints and choices (mine, say if wrong)
* Written in Jex, one static program, `fcode`. The editor of today was renamed to fcode on 2026-11-27 (`coderin` is its old name); stage 1 builds on
  it. It reads `~/.config/coderin/` when there is no `~/.config/fcode/`.
* An extension of fcode is one file `NAME.fcde` (the owner, 2026-11-27): a zip with the manifest and its files, like a `.vsix`; `fcode --install NAME.fcde`
  and `ex install` put it in `~/.config/fcode/extensions/`.
* Tests drive it through a pseudo terminal and read the screen with exshell's own terminal at 40 and 80 columns.
* Every release comes with its lesson in the documents.

## Open for later
Which VS Code extensions the owner relies on (decides stage 3 order and whether `code-server` is wanted).
