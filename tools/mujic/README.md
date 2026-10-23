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
Keys in the player: up/down choose, Enter play, Space pause, n / p next / previous, left / right jump 10 s (Jaric app), l fetch the lyrics, g fetch a song, v hide the lyrics, s stop, q quit.
Your own lyrics: put `Song.lrc` (`[01:23.45]words`) or `Song.txt` next to `Song.mp3`.

Sound: in the Jaric app the app plays (mp3, ogg, m4a, flac, wav); elsewhere `termux-media-player`, `mpv`, `ffplay` or `mpg123` when one is installed.
License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.1.0.0 or newer). Test: `sh test.sh` (python3).
The lyrics come from lrclib.net when you ask; they belong to their authors: keep them for your own use.
