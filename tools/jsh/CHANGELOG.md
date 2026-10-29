# Changelog

## 0.11.2
* **Fixed:** since 0.11.1 only 23 names were sent to jbox when they were not in the PATH (`less`, `find`, `tree`, `man`, `diff` ... were "not found" without the links of `jbox --install`); all the commands of jbox are known again.

## 0.11.1
* **Added:** a name that is not a command gets a hint: `ech` gives `(did you mean echo?)`, the name of a tool of Jaric that is not installed gives `(a tool of Jaric: jc install cam)`, a near name of a tool gives `(did you mean jfile? jc install jfile)`; nothing is guessed for nonsense.
* **Fixed:** jsh asked the small commands (jbox) for every unknown name, and jbox gave the error without a hint; now only the names that jbox knows go to it.

## 0.11.0 (needs jcmp 1.2.4 for the virtual root; the rest works with 1.2.3)
* **Added:** a shell nearer to the real ones: `echo -n`, `-e` (`\\t \\n \\e \\0NNN \\xHH \\c`) and `-E`; `kill` as a built-in with signals (`-9`, `-KILL`, `-s TERM`, `-l`) and jobs (`kill %1`, `%%`); `fg` and `bg`; `jobs` shows `Running` and the ended ones are told once (`[1]+ Done`, also before the prompt); `cd /etc`, `cd /`, `cd /u` read the virtual root of Jaric (the environment `JARIC_ROOT`).
* **Added (the grey text, better):** the history of the commands is kept in `~/.jsh_history` (the folder and the command; the last 3000 are read at the start; a line with a secret in it is not kept), so the grey text and the arrows know what you typed in the sessions before. The grey text chooses the line that you typed most often, in this folder, and lately; a tree of words made from the history guesses the next word (`git` + space gives the usual `status`; `x && git pu` gives `push`: each part after `&&` `||` `;` `|` is a command of its own); `$HO` gives `ME`. Tab still takes the grey text.
* **Fixed:** quotes keep their meaning: `'*.txt'` and `"*.txt"` are not patterns, `'$HOME'` is not replaced, `">"` and `";"` in quotes are words and not operators, `"\\t"` keeps its backslash (only `\\$ \\` \\" \\\\` are made plain inside double quotes).

## 0.10.2
* **Added:** `./script.jsh` (or `dir/script.jsh`) runs a jsh script: the file needs the execute right (`chmod +x`), else jsh says `permission denied (chmod +x NAME)`; arguments become `$1 $2 ... $#`. A script is a file ending in `.jsh` or with `[#jsh]`, `#jsh` or `#!jsh` on the first line.
* **Fixed:** none.

## 0.10.1
* **Changed:** as root the prompt keeps the name `jc` and turns it red (it said `root` in 0.10.0).
* **Added:** `login` (or `signin`) without a name asks `login:` and then the password, like a Unix login; `login root` skips the first question. An unknown name is refused (`no user 'bob'`; root is the only user with a password for now). `passwd` changes the root password (the old one is asked first).

## 0.10.0
* **Added (root):** `login root` (or `signin root`) asks the root password (the first time it is made, twice; kept as a salted SHA-256 in `files/.jaric/root`). As root `:/` is the top folder of the app (`:/usr/bin` holds the commands, `:/home` is home), the prompt says `root`, and `JC_ROOT=1` is set for the tools. `logout` (or `signout`) leaves. `root COMMAND ...` does one command as root and reads its words as root (`root cd :/usr/bin`). With jbox 0.8.0 the commands of the system (`usr/bin`, `usr/lib`, `usr/etc`) are changed by root only; reading is free. A rule that the tools keep, not a wall (Android is below it).

## 0.9.10
* **Changed:** when the tool `drive` is installed (`jc install drive`) the command `drive` is that program (a new drive can get its own new folder: `drive new NAME`); the built-in stays for a shell without it. The drive list is read again after every `drive`.

## 0.9.9
* **Fixed:** a long grey guess (a long old line of the history) wrapped over the end of the row and every key scrolled the screen and printed the line again and again; the grey text is now cut to the room that is left on the row (Tab still takes the whole guess).

## 0.9.8
* **Changed:** the grey text (the guess of the rest of the line) is found in a tree of letters (a trie) built from the history, not by scanning the whole history on every key. The result is the same: the newest line that continues what you typed.
* **Added:** `ghost_test.py` (a pseudo terminal test of the grey text).

## 0.9.7
* **Changed:** installing is done by `jc` only (`jc install NAME`, `jc update [-n]`, `jc unstall NAME`). The built-ins `install`, `update`, `unstall` and `jsh install` are gone; typing them says which `jc` command to use. Hints (`command not found`) and `help` name `jc install`.

## 0.9.6
* **Added:** the built-ins `update [-n]` (jsh and every installed tool that has a newer version; `-n` only shows them) and `unstall NAME` (removes a tool); they use `jc` and fall back to `jget tool`. `install all` now means the same as `update`.
* **Fixed:** the banner said `jsh 0.1`; it and `--version` now show the real version.

## 0.9.5
* **Added:** `jaric keepalive` says how to keep the sessions after the app is swiped away from the list (the notification stays, battery optimisation allowed, the settings of Huawei) and opens the system screen for it (the Jaric app 0.0.109). **Added:** the setting "wake lock (CPU awake)" in "terminal and security" (`wakelock = on|off`): the CPU stays awake while the sessions run.

## 0.9.4
* **Added:** `pwd` has options: `pwd -p` the real path of the system (`-P` too), `pwd -d` only the drive (`f`), `pwd -help` the usage; an unknown option is an error (exit 2). Before, every option printed the same `f:/`.

## 0.9.3
* **Fixed (the prompt `r:/../files/home>` in the app):** the roots of the drives are turned into their real paths before they are compared with the folder you are in. On Android `HOME` is `/data/data/...` (a link) and `getcwd` says `/data/user/0/...`; the two forms did not match, so home was not found as the drive `f` and the prompt fell back to the drive `r` with a cut path. It says `f:/` and `f:/jaric` now.

## 0.9.2
* **Changed:** `jaric` with a word it does not know (for example `jaric assistent`) says "Did you mean: jaric assistant ?" and lists every command, now including `assistant`, `store`, `drives` and `sessions` (the list was old).

## 0.9.1
* **Changed:** `pwd` prints the drive and the path (`f:/jaric`), like the prompt, in full; `pwd -P` prints the real path (`/data/data/.../home/jaric`).

## 0.9.0
* **Changed (the drives, the owner's design of 2026-10-23; replaces the `:/X` letters of 0.8.2):** a path may start with a drive written before the colon: `f:/jaric`, `0:/Download`. **The drive `f` is home** and `:/` with no letter is home too (the same as `~/`): `cp song.mp3 :/Music`, `cd f:/jaric`. `0:` is the phone storage, `r:` the root `/`; `drive new NAME PATH` makes more drives (kept in `~/.jsh_drives`), `drive remove NAME`, `drive` and `jaric drives` list them. A URL (`http://...`) and a name that is not a drive are left alone.
* **Changed (the prompt):** it shows the drive and the folder in it: `jc f:/>` at home, `jc f:/jaric>` in `~/jaric`, `jc 0:/Download>` in the storage, `jc r:/data>` elsewhere; a deep path is cut (`f:/../er/est`).

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
