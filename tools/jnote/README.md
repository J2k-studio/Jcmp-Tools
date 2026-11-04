# jnote

Quick notes and checklists in the terminal. A note is a plain text file (the first line is its title) in `~/Documents/Notes`
(or the folder in `$JNOTE_DIR`), named `note-0001.txt`, `note-0002.txt` ... so any editor or program can read them. Written in J2K.

```
jnote                       list the notes
jnote add Buy milk          a new note   (\n in the text is a new line)
jnote todo Trip tent map    a checklist "Trip" with the items "tent" and "map"
jnote show 2                print note 2
jnote check 2 1             tick (or untick) item 1 of note 2
jnote append 1 and eggs     add a line to note 1
jnote find milk             the notes that contain "milk" (any case)
jnote rm 1                  delete note 1
jnote path                  the folder of the notes
```

Install: `jc install jnote`. Test: `sh test.sh`. License: MPL-2.0.
