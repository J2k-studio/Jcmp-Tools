# fcode stage 1 (the daily editor) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `fcode` opens several files, has a command palette, quick open, a file tree, replace, many cursors and keys close to VS Code, on a 40-column screen, and still does everything it does today.

**Architecture:** the one file `fcode.jk` is split into parts first, with no change of behaviour; then the state of a file moves into a `Buffer` struct; then every action becomes a command with a VS Code id that keys, the menu and the palette all call; the new features are built on those.

**Tech Stack:** Jex (compiler `~/Jcmp/bin/jcmp`), library `<stdlib>` only; tests are shell + Python driving the program through `../jpty`.

**Spec:** `docs/superpowers/specs/2026-11-27-fcode-design.md`

## Global Constraints

* Written in Jex, one static program `fcode`; only `#import <stdlib>` and files of `tools/fcode/`.
* Nothing is ever written past the width of the screen; every new view works at 40×30 (the phone) and 80×24.
* Keys need only Ctrl or Alt: whatever VS Code puts on Ctrl+Shift has a key without Shift.
* Command ids are VS Code's (`workbench.action.quickOpen` ...).
* `~/.config/fcode/` first, `~/.config/coderin/` when the first is not there; today's extension folders keep working.
* Build/test: `cd tools/fcode && JCMP=$HOME/Jcmp/bin/jcmp JCMP_LIB=$HOME/Jcmp/bin/Library sh test.sh` must end with `fcode test: ok`.
* Every task ends with a commit whose message says what was added and fixed, ending `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

## Review Focus

* A line, tab name or file name with Thai or wide characters in a narrow column: cut at a whole character, the cursor in the right place.
* Closing a tab or quitting with unsaved changes in a tab that is not shown: the person is asked, nothing is lost.
* Quick open in a very large folder (home): it stays responsive (at most 2000 files, hidden folders and `_out`, `.git` skipped).
* Many cursors on the same line, or two cursors that meet after an edit: no text is doubled or lost.
* The program is killed while a file is dirty: a recovery copy is offered the next time.

---

### Task 1: Split into parts (no change of behaviour)

**Files:**
- Modify: `tools/fcode/fcode.jk` (keeps `main`, `handle_key`, `handle`)
- Create: `tools/fcode/fc_term.j` (raw mode, size, `read_key`), `fc_text.j` (characters, columns, the lines), `fc_edit.j` (selection, clipboard, undo, commands), `fc_ext.j` (extensions, snippets, words, `-ex`), `fc_conf.j` (settings, bindings, schemes), `fc_draw.j` (drawing, menu, panes, popup, mouse), `fc_build.j` (compile, run, errors, examples)
- Test: `tools/fcode/test.sh` (unchanged)

**Interfaces:**
- Produces: the same global names and functions as today, now in those files, imported with `#import "fc_term"` and so on.

- [ ] **Step 1:** Run `sh test.sh`; expected `fcode test: ok` (the baseline).
- [ ] **Step 2:** Move each section (marked `// ----` in `fcode.jk`) to its file; add the `#import` lines; change nothing else.
- [ ] **Step 3:** Run `sh test.sh`; expected `fcode test: ok`, and `wc -l fcode.jk` below 500.
- [ ] **Step 4:** Commit.

### Task 2: A file is a Buffer

**Files:** Create `fc_buf.j`; modify the files of Task 1 that use `lines`, `cx`, `cy`, `top`, `left`, `sel`, `ax`, `ay`, `dirty`, `path`, the undo stacks.

**Interfaces:**
- Produces: `struct Buffer { String[] lines; i64 cy; i64 cx; i64 top; i64 left; bool sel; i64 ay; i64 ax; bool dirty; String path; ... undo fields }`, `Buffer[] bufs; i64 cur_buf;`, `void buffer_switch(i64 n)` (saves the globals into `bufs[cur_buf]`, loads `bufs[n]`), `i64 buffer_open(String path)` (the index of an open file with that path, or a new one).

- [ ] **Step 1:** Add to `test.sh`: `printf '\021' | $PTY -w 40 -h 30 "$ED" a.txt b.txt` ends and leaves both files unchanged.
- [ ] **Step 2:** Run; expected FAIL (a second file is not accepted).
- [ ] **Step 3:** Implement: the working globals stay (the drawing code reads them); `Buffer` is where they rest while another file is shown.
- [ ] **Step 4:** `sh test.sh` ok. Commit.

### Task 3: Commands by id

**Files:** Create `fc_cmd.j`; modify `fc_conf.j` (bindings map a key to an id), `fc_draw.j` (menu calls ids), `fcode.jk` (`handle_key` calls `run_command`).

**Interfaces:**
- Produces: `void command_register(String id, String title, String old_name)`, `bool run_command(String id)`, `String[] command_ids()`, `String command_title(String id)`. Old names in `bindings` files (`save`, `find`, `goto` ...) map to ids.
- Ids: `workbench.action.files.save`, `workbench.action.quit`, `actions.find`, `editor.action.startFindReplaceAction`, `workbench.action.gotoLine`, `editor.action.clipboardCopyAction`, `editor.action.clipboardCutAction`, `editor.action.clipboardPasteAction`, `undo`, `redo`, `editor.action.selectAll`, `editor.action.deleteLines`, `editor.action.copyLinesDownAction`, `editor.action.commentLine`, `editor.action.moveLinesUpAction`, `editor.action.moveLinesDownAction`, `editor.action.addSelectionToNextFindMatch`, `workbench.action.quickOpen`, `workbench.action.showCommands`, `workbench.action.toggleSidebarVisibility`, `workbench.action.nextEditor`, `workbench.action.previousEditor`, `workbench.action.closeActiveEditor`, `workbench.action.tasks.build`, `workbench.action.debug.run`.

- [ ] **Step 1:** Test: a `~/.config/fcode/bindings` line `ctrl-t = workbench.action.files.save` saves with Ctrl-T; the old form `ctrl-t = save` does too.
- [ ] **Step 2:** Run; expected FAIL.
- [ ] **Step 3:** Implement. **Step 4:** ok. Commit.

### Task 4: Tabs

**Files:** Create `fc_tabs.j`; modify `fc_draw.j` (a tab line on top when two or more files are open).

**Interfaces:** Consumes `buffer_switch`, `buffer_open`, `command_register`. Produces `String tab_line(i64 width)`, commands next / previous (`Ctrl+PageDown` `ESC[6;5~`, `Ctrl+PageUp` `ESC[5;5~`, also `Alt+Right` / `Alt+Left`), close (`Ctrl+W`).

- [ ] **Step 1:** Test (40×30): open `a.txt b.txt`, type `x`, `ESC[6;5~`, type `y`, save, switch back, save: `a.txt` is `x`, `b.txt` is `y`. Ctrl-W on a dirty tab shows `unsaved` and keeps it; twice closes without saving. The quit with a dirty hidden tab asks.
- [ ] **Step 2:** FAIL. **Step 3:** Implement (names cut at a character boundary; `●` marks a dirty tab). **Step 4:** ok, and the narrow-screen width check of `test.sh` passes. Commit.

### Task 5: The picker, command palette and quick open

**Files:** Create `fc_pick.j`.

**Interfaces:** Produces `i64 pick(String title, String[] items, String[] hints)` (a box of at most `cols` wide: typing filters by letters in order, arrows move, Enter returns the index, Esc `-1`), `String[] workspace_files(String root, i64 limit)`.
Keys: palette `Ctrl+E` and `F1` (`ESC OP`), quick open `Ctrl+P`. The command bar of today stays as the palette entry `> command` (id `fcode.commandBar`).

- [ ] **Step 1:** Test: `Ctrl+P`, `b.t`, Enter opens `sub/b.txt` as a tab; `Ctrl+E`, `save`, Enter saves; a folder with `.git/x` and `_out/x` lists neither.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** ok at 40 columns with a file name of 80 letters. Commit.

### Task 6: Replace, comment, move and copy lines

**Files:** Modify `fc_edit.j`.

**Interfaces:** commands `startFindReplaceAction` (`Ctrl+H`: asks what, then with what; `y` / `n` / `a` all / `q` at each place), `commentLine` (`Ctrl+/`, byte `\037`; `//` for `.j .jk .jex .c .rs`, `#` for `.py .sh .jsh .toml`), move lines (`Alt+Up` `ESC[1;3A`, `Alt+Down` `ESC[1;3B`), copy line down (`Ctrl+L`).

- [ ] **Step 1:** Test: replace all `aa` with `b` in `aa aaaa` gives `b bb`; comment twice restores the line; Alt+Down moves line 1 to line 2; Ctrl+L doubles it.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** ok. Commit.

### Task 7: Many cursors

**Files:** Create `fc_multi.j`; modify `fc_edit.j`, `fc_draw.j`.

**Interfaces:** Produces `i64[] mc_y; i64[] mc_x;` (extra cursors), `void mc_clear()`, `void mc_apply_insert(String text)`, `void mc_apply_backspace()`. `Ctrl+D`: selects the word, then adds the next same word. Esc clears. Edits go from the last place to the first so that earlier places do not move.

- [ ] **Step 1:** Test: in `ab ab ab`, Ctrl-D three times, type `X`: `X X X`; two lines `ab` / `ab`: the same; one undo restores both.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** ok. Commit.

### Task 8: The file tree

**Files:** Create `fc_tree.j`; modify `fc_draw.j`.

**Interfaces:** `Ctrl+B` toggles. Below 80 columns the tree covers the text and closes when a file is opened; from 80 columns it takes 24 columns at the left. Arrows, Enter (open / unfold), tap.

- [ ] **Step 1:** Test: Ctrl-B, Down, Enter opens the second entry as a tab; at 80 columns the text still starts after column 24.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** ok at both widths. Commit.

### Task 9: A recovery copy

**Files:** Modify `fc_buf.j`, `fcode.jk`.

**Interfaces:** every 2 seconds of change a dirty buffer is written to `~/.cache/fcode/<path with / as %>`; removed on save and on a quit without saving; opening a file that has one asks `a recovery copy is newer: use it? [y/n]`.

- [ ] **Step 1:** Test: type, wait 3 s, `kill -9`, open again, `y`: the typed text is there; after a save no copy is left.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** ok. Commit.

### Task 10: Release

**Files:** `tools/fcode/README.md` (a lesson with every key), `CHANGELOG.md`, `VERSION`, `LATEST` (0.7.0), `coderin/VERSION` (the same).

- [ ] **Step 1:** `sh test.sh` ok twice.
- [ ] **Step 2:** Release `fcode` and `coderin` 0.7.0 (`release.sh`, `gh release create`, `./check-standard.sh fcode coderin`, push).
- [ ] **Step 3:** The owner tries it on the phone.
