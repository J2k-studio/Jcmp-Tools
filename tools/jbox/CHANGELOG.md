# Changelog

## 0.10.0
* **Added:** `df [-h] [FOLDER...]` (size, use, free of a drive), `ps` (the programs you can see: pid, state, memory, cpu, name) and `hex FILE` (the bytes in hex). The web is fetched by `jget` (`jget URL -o -` writes the answer to the screen), not by a second program in jbox.
* **Fixed:** none.

## 0.9.1
* **Fixed:** `jbox --install` made no link for `man` (0.9.0).

## 0.9.0
* **Added:** `man NAME`: the manual of a tool or a library of Jaric (a Markdown file on the phone, `~/.jaric/man/NAME.md`, or the README from GitHub, kept in `~/.cache/jaric/man/`; `man` alone lists the tools; `man language` and `man usage` are the language and the compiler), shown in the pager with headings, code and lists; the pager of `less` is better: long lines are cut at a letter, `/` finds (the matches are marked) with `n` / `N`, `g` / `G`, half pages `d` / `u`, the arrows, Home / End, Page Up / Down, a percent, `h` shows the keys.
* **Fixed:** none.

## 0.8.0
* **Added:** the commands of the system (`usr/bin`, `usr/lib`, `usr/etc` of the app) are changed by root only: `rm`, `mv` and `cp` (into it) refuse unless `JC_ROOT=1`, which jsh sets after `login root` or for `root COMMAND`. Reading is free. A rule that the tools keep, not a wall (Android is below it).

## 0.7.1
* **Fixed:** `rm -r` and `rm -R` did nothing for a folder that is not empty (`rm -rf */` left every folder, without a word). Now `rm -r` removes a folder and all that is in it; a symbolic link inside is removed, not followed; `/`, `.` and `..` are refused; `rm` of a folder without `-r` says so (`is a folder (rm -r ...)`) instead of failing silently with `-f`.

## 0.7.0
* **Changed (dir / ls):** at a terminal the names stand in columns that fit the width of the screen, going down the first column and then the next, like `ls`; sorted without regard to capitals; folders in blue with a `/`, programs in green; names in Thai are measured right (a vowel above or below takes no cell). `-1` one name on a line, `-l` the rights, the size (`-h`: 1.5K) and the name, `-a` the names that start with a dot. Into a pipe or a file: one name on a line, as before.
* **Fixed (cp):** `cp` read and wrote text, so a file with a zero byte (a song, a picture, a program) was cut short. It copies the bytes now, keeps the right to run, copies into a folder, and says clearly when the source is a folder or is missing.

## 0.6.2
* tree: -d (folders only), -s (sizes), and a folder that cannot be read is shown as [cannot read this folder].

## 0.6.1
* less: Esc leaves (the arrows still move).

## 0.6.0
* New: rev (Thai marks stay with their letter), yes, uname, hostname, whoami, realpath, base64 (-d), sha256sum, cmp, paste, fold -w, printf, uptime, free, nproc.

## 0.5.2
* --help and -V work (the standard of the tools: docs/STANDARD.md)

## 0.5.1
* nl (numbered lines) and tac (lines in reverse).

## 0.2.0
* kill [-9 | -TERM | -INT | -HUP ...] PID ...

## 0.1.1
* head, tail, wc, sort, uniq and grep called without a file while the input is the keyboard say what is needed, instead of waiting for typing.

## 0.1.0
* First release.

## 0.5.0
* date, du, stat, xargs, sed (s///), less.

## 0.4.0
* find, ln -s, chmod, cut, tr, diff, tree.
