# coderin: a text editor for the terminal

Written in J2K, for the Jaric app and any ANSI terminal (it uses the alternate screen, 24-bit colours and the cursor addressing). Version 0.1.

```
coderin FILE
```

| Key | What |
|---|---|
| arrows, Home, End, PageUp, PageDown | move (Ctrl + arrows: by word, Ctrl + Home / End: start / end of the file) |
| Shift + arrows | select |
| Ctrl-C, Ctrl-X, Ctrl-V | copy, cut, paste (the copy also goes to the clipboard of the phone in the Jaric app, OSC 52) |
| Ctrl-A | select all |
| Ctrl-D, Ctrl-K | copy the line below / delete the line |
| Ctrl-F, Ctrl-G | find / go to a line |
| Ctrl-S, Ctrl-Q | save / quit (a second Ctrl-Q quits without saving) |
| Tab | four spaces |

Colours for J2K (keywords, types, text, numbers, comments), line numbers, auto indent after `{`, a closing `}` steps back.
Not yet: undo / redo (planned as an extension), several files, mouse, tabs in the display of a long line.

```
sh build.sh      # needs jcmp 1.0.0.0 or newer (JCMP=path chooses the compiler)
sh test.sh
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).
