# Changelog

## 0.8.3
* **Added:** `jaric store` (also `jaric -store`) opens the store of the programs of Jaric: `jaric store` lists them, `jaric store install ID`, `update`, `remove ID` (the tool `jstore`; says how to install it when it is missing).

## 0.8.2
* **Added (drives):** a word that starts with `:/X` is the folder of a drive, so the paths of the prompt can be typed: `:/f` the folder of the app (the parent of home), `:/h` home, `:/0` the phone storage (`/storage/emulated/0`), `:/s` `/sdcard`, `:/p` the prefix, `:/t` temporary files, `:/r` and `:/` the root `/`. `cp song.mp3 :/0/Music`, `cd :/f/home`. A URL or an unknown letter is not touched. `jaric drives` shows the table. (Designed by the assistant, adjustable: docs/os-userland-ideas.md.)

## 0.8.1
* **Added:** `jaric assistant [question]` talks to the assistant xaiorin (runs `xr`; says how to install it when it is missing).
* **Changed:** the item "run scripts from the net" of `jaric setting` works now (`ask`, `never`, `allow`): jget 0.8.0 reads it. It asks at a terminal before it runs a script that `jget -sh` / `-jsh` downloaded.

## 0.8.0
* **Added:** the shell can feed the assistant xaiorin (xr): with the setting `xr_learn = on` (`jaric setting`, section "assistant xaiorin (xr)") every command you type is written as `COMMAND<tab>STATUS<tab>MESSAGE` to `~/.neuron/events.txt` on this phone only (a line that has "password", "token", "secret", "api_key" or "authorization" is skipped; the file stops growing at 400 KB). `xr learn` teaches the assistant from it, `xr forget` deletes it. Off by default.
* **Added:** settings "xr runs in the background" (`xr_autostart`; the Jaric app starts `xr start` with the app) and "xr learns from the shell".

## 0.7.6
* `jaric setting` no longer scrolls and overprints itself: every line is drawn at its place, and when the list is longer than the screen it is a window that follows the chosen item ("more above / more below" in the help line).

## 0.7.5
* `start PROGRAM [arguments]` runs a program in a new tab (session) of the Jaric app (`7777;session;new;COMMAND`; in other terminals nothing happens). `jaric sessions` says how the tabs work.

## 0.7.4
* `jaric setting` is in sections (look, prompt, keyboard and keys, terminal and security, font and cursor, screen, other) with new items: cursor shape, screen rotation, full screen, keep the screen lit, volume keys as Ctrl/Esc (these work in the app 0.0.102); scrollback lines, bell, key vibration, start command and "run scripts from the net" are listed as "(later)": the settings are saved, the app does not use them yet.

## 0.7.3
* The first line of a script may be `[#jsh]` (the owner's form; taken away), `#jsh` or `#!jsh` (comments); `[#jash]` / `#jash` is a settings file of jash and is not run. `jsh script a b` sets `$1`, `$2`, `$0` and `$#`. `$#` is expanded (it was not, also in functions).

## 0.7.2
* A long line (longer than the screen) is redrawn in the right place: the arrows, Home, End and editing no longer start new lines again and again (the cursor goes up to the first row of the line before the line is printed, and the width of colour codes, Thai marks and wide letters is counted).

## 0.7.1
* The prompt keeps the name of the folder you are in whole and shortens only the one above: `jc :/f/home>`, `jc :/h/Jaric>` (short paths stay whole: `jc :/home>`).

## 0.7.0
* `jaric video FILE|URL` plays a video over the terminal in the Jaric app (message `7777;video`), `jaric video stop`.

## 0.6.2
* A long path in the prompt is the first letters of the last two folders: `jc :/f/h>` (short ones stay whole: `jc :/home>`).

## 0.6.1
* --help and -V work (the standard of the tools: docs/STANDARD.md); the version text was wrong (0.5.0) in 0.5.1 to 0.6.0

## 0.6.0
* `jaric setting`: one screen (arrows, Enter, q) for the theme, the font size, the background / text / accent colours, the top bar, the animation and the four colours of the prompt. It writes the plain files (config.local, theme.toml, ~/.jshrc) and the app reads them again when the screen is left (message `reload`).

## 0.5.4
* The mark `>` is white (red after a failure). The colours of the prompt are settings: in ~/.jshrc `export JSH_COLOR_NAME=sky`, `JSH_COLOR_PATH`, `JSH_COLOR_MARK`, `JSH_COLOR_ERROR`; a value is a name (white grey black red green blue sky cyan yellow orange magenta), `#rrggbb` or `r,g,b`.

## 0.5.3
* The mark `>` of the prompt is sky blue.

## 0.5.2
* The prompt is `jc :/home>`: the real path, `:` in front says the drive (`:/` is the root), long paths are cut (`:/../files/home`).

## 0.5.1
* The prompt is `jc ~/ >` (the mark is red after a failure); while typing the first word is green when it is a command and red when it is not.

## 0.4.1
* `clear` and `dir [-a] [FOLDER]` are built in when jbox is not installed (a fresh install can list its files); jaric-core.

## 0.4.0
* `install NAME ...` (also `jsh install NAME`): puts tools of Jcmp-Tools next to jget (it runs `jget tool NAME`); `install` alone lists them.

## 0.3.0
* break and continue, $(( )) arithmetic, read, jobs and wait (a command with & runs in the background and ends its statement), Ctrl-C stops a loop of a script.

## 0.2.0
* Scripts: if / elif / else, while, until, for, functions with parameters and return, command substitution $( ), test and [ ].
* A failed cd sdcard asks the Jaric app to make the link (a private sequence, ignored by other terminals).

## 0.1.2
* A private sequence (ESC ] 7777 ; prompt BEL) after the prompt tells a terminal program where the typing starts (the Jaric app moves the cursor with a tap only inside that line); other terminals ignore it.

## 0.1.1
* New line: Ctrl-J starts another line of the same command (prompt ".. "), Enter runs all the lines.

## 0.1.0
* First release.

## 0.5.0
* Redirections 2> 2>> 2>&1 1>&2 &> <<< and here-documents; tree in the command list.
