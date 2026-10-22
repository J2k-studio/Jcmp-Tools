# jpty: a program on a pseudo terminal

`jpty [-w COLUMNS] [-h ROWS] PROGRAM [arguments]` gives PROGRAM a pseudo terminal (so a shell or an editor sees a real terminal) and relays the bytes: what jpty reads on its standard input is typed to the program, what the program writes comes out on the standard output. Two pipes are enough to drive a full terminal program, for example from an Android app (this is how the Jaric app runs jsh). PROGRAM is a full path (there is no PATH search). The exit code is the one of the program.

```
jpty -w 100 -h 30 /bin/sh        # build: jcmp jpty.jk -o jpty   (jcmp 1.0.0.0 or newer)
```
**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).
