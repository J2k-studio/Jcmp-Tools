# jpty: a program on a pseudo terminal

`jpty [-w COLUMNS] [-h ROWS] PROGRAM [arguments]` gives PROGRAM a pseudo terminal (so a shell or an editor sees a real terminal) and relays the bytes: what jpty reads on its standard input is typed to the program, what the program writes comes out on the standard output. Two pipes are enough to drive a full terminal program, for example from an Android app (this is how the Jaric app runs jsh). PROGRAM is a full path (there is no PATH search). The exit code is the one of the program.

```
jpty -w 100 -h 30 /bin/sh        # build: jcmp jpty.jk -o jpty   (jcmp 1.0.0.0 or newer)
```
**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).

## Install
```
jget tool jpty                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jpty     # with curl (no jget needed)
```
In jsh: `install jpty`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Run a shell in a pseudo terminal: `jpty -w 80 -h 24 /bin/sh` (the program must be a full path).
2. What you type on jpty's input goes to the program; what the program prints comes out of jpty (with the colours and cursor codes of a real terminal).
3. Use it from an app: start `jpty` with two pipes, write keys to one, read the screen bytes from the other (this is how the Jaric app runs jsh).
4. The exit code of jpty is the program's exit code, so a script can test it.
