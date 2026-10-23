# mujic changelog

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
