# Changelog

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
