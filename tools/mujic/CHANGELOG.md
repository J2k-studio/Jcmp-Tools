# mujic changelog

## 0.5.0
* **Added:** `/scan [-s SECONDS] [PATH ...]` (and `mujic scan ...` for scripts): finds songs of at least SECONDS (default 60) in the home folder and the phone storage, or in the PATHs, and shows them in a list to play. The length comes from the header of `.wav` and `.mp3` (also Xing / Info of variable rate) and is a guess from the size (`~`) for other formats.
* **Changed:** the folder of the songs is hidden, `~/.music`; an old `~/music` is moved there once.

## 0.4.1
* **Added:** the buttons of the notification of the Jaric app (previous, pause, next) work: the app sends `7777;media;prev|pause|next` and mujic runs the same as `/prev`, `/pause`, `/next`.

## 0.4.0
* **Added:** mujic is a small terminal. `/dir [PATH]` (or `dir`, `ls` typed alone) opens a picker of folders and songs: Enter on a folder goes in (`..` goes up), Enter on a song plays it from where it is; `/dir FILE` and `/play PATH` play a song by its path; `/cd PATH`, `/pwd`; `~`, `:/`, `f:`, `0:`, `r:` work in paths. `!command` runs a shell command in that folder (jsh when it is installed, so drives work) and shows the lines in a third view (Tab: songs, lyrics, output).
* **Changed:** Tab now cycles songs, lyrics, output. The test `ui_test.py` covers `/dir`, entering a folder, playing by path, `!command` and `/pwd`.

## 0.3.3
* `mujic -session [arguments]`: in the Jaric app the player opens in a tab of its own and the shell stays free (elsewhere it runs here as before).

## 0.3.2
* `/import PATH` copies a song, or the songs of a folder, into the music folder.
* `/get ADDRESS` of YouTube, YouTube Music, TikTok or SoundCloud runs `yt-dlp` when it is installed (`pip install yt-dlp`; mujic does not include it). Use it only for songs you may download.

## 0.3.1
* `/mv NAME FOLDER` moves a song (and its `.lrc` / `.txt`) into a folder of the music folder; the folder is made when it is not there; `/mv NAME .` brings it back. The songs in the folders one level down are listed as `folder/song`.

## 0.3.0
* A new screen like the chat of Claude Code: a typing box at the bottom, the commands open as a menu when the line starts with `/` (/play /pause /next /prev /stop /queue /lyrics /get /find /shuffle /repeat /volume /seek /help /quit), pickers to choose from (songs, the free catalog, the results of the Internet Archive; type to narrow, arrows, Enter, Esc), plain words find a song and play it, Thai and other letters can be typed. Keys with an empty box: Enter plays, Space pauses, left / right seek, Tab songs / lyrics, Esc leaves.

## 0.2.1
* Esc leaves the player (it clears the find first).

## 0.2.0
* Shuffle (z), repeat off/all/one (r), volume (+ and -, in the Jaric app), find in the list (/), Esc clears the find; the app keeps the volume between songs.

## 0.1.0
* The player (list, synced lyrics, time bar), `list`, `catalog`, `get` (catalog name, address, archive:ID), `find` (archive.org), `lyrics` (lrclib.net). Sound: the Jaric app (message ESC ] 7777 ; audio), termux-media-player, mpv, ffplay or mpg123.
