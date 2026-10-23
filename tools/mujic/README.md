# mujic: a music player for the terminal

Songs live in a folder (`~/music`, or `$MUJIC_DIR`). The player shows the list, the lyrics (the line that is sung is lit) and a time bar.

```
mujic                       the player
mujic play "Song"           start with a song (a number or a part of the name)
mujic list                  the songs (a mark when lyrics are next to them)
mujic catalog               free songs (Kevin MacLeod, CC BY 4.0) ;  mujic get sneaky-snitch
mujic get URL [-n NAME]     fetch a song from an address ;  mujic get archive:ID  from the Internet Archive
mujic find WORDS            search the Internet Archive (check the licence of what you fetch)
mujic lyrics NAME [-q "artist title"]   fetch the lyrics from lrclib.net, kept as NAME.lrc (with times) or NAME.txt
```
The player is a screen like the chat of Claude Code: the songs (or the lyrics) above, a **typing box** below. Type words and Enter to find a song and play it (several matches open a list to choose from). Type `/` and a **menu of commands** opens (arrows, Tab to complete, Enter to run): `/play` (a picker of your songs), `/pause`, `/next`, `/prev`, `/stop`, `/queue`, `/lyrics` (and `/lyrics get`), `/get` (a picker of the free catalog, or a name, an address, `archive:ID`), `/find words` (search the Internet Archive, then choose), `/shuffle`, `/repeat`, `/volume 80`, `/seek +10`, `/help`, `/quit`. With an empty box: Enter plays the song under the cursor, Space pauses, left / right seek 10 s (Jaric app), Tab switches songs / lyrics, Esc leaves.
Your own lyrics: put `Song.lrc` (`[01:23.45]words`) or `Song.txt` next to `Song.mp3`.

Sound: in the Jaric app the app plays (mp3, ogg, m4a, flac, wav); elsewhere `termux-media-player`, `mpv`, `ffplay` or `mpg123` when one is installed.
License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.1.0.0 or newer). Test: `sh test.sh` (python3).
The lyrics come from lrclib.net when you ask; they belong to their authors: keep them for your own use.
