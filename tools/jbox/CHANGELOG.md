# Changelog

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
