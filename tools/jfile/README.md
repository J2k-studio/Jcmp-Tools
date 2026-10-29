# jfile: the files of the phone in a terminal

`jfile` shows the places of the phone (Home, Downloads, Pictures, Camera, Documents, Music, Movies, all the storage `u:/`) and the folders in them, and lets you look at, open, copy, move, rename and delete what is there. Written in J2K (it reads PNG and JPEG itself to show a picture).

## Commands
```
jfile                     the places (choose with up / down and Enter)
jfile /sdcard/Download    a folder
jfile ls [FOLDER] [-a]    the list as text: name, size, date (for scripts)
jfile places              the names and the folders of the places
jfile cp SRC DST          copy a file or a folder with all that is in it
jfile mv SRC DST          move or rename           jfile rm PATH   delete          jfile mkdir PATH
```
Keys in the screen: **up / down**, PageUp / PageDown, **Enter** or right = open a folder or look at a file, **Backspace** or left = up, **Space** = mark (and go down), `a` mark all, `c` copy, `x` cut, `v` paste (a name that is taken gets `(2)`), `d` delete (asks `y`), `r` rename, `n` new folder, `/` find in the folder, `s` sort (name, size, date), `.` hidden files, `g` the places, `o` open with the phone, `i` picture, `t` text, `q` quit.
* A picture (png, jpg) is shown over the terminal (touch or `q` closes); a text file in pages; a video or a song is played by the app; a pdf, an apk or another kind is opened by the app of the phone that knows it (app 0.0.149 or newer).
* `rm` and `d` delete for good (there is no bin). `rm /` is refused.
* In the Jaric app the drive of these files is `u:/` (`cd u:/Download`).

```
sh build.sh      # needs jcmp 1.2.4.0 or newer and the libraries deflate and png
sh test.sh       # needs python3: the commands and the screen on a pseudo terminal
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).

## Install
```
jc install jfile                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jfile     # with curl (no jget needed)
```
In jsh: `jc install jfile`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Type `jfile`. Choose **Downloads** and press Enter.
2. Move with the arrows; Enter on a folder goes in, Backspace goes back. Enter on a picture shows it; touch the screen to come back.
3. Copy a file to another folder: put the cursor on it, `c`, go to the other folder, `v`.
4. Mark many with Space, then `x` (cut) and `v` in the new place: that is a move. `d` then `y` deletes.
5. `jfile ls u:/Download` or `jfile ls /sdcard/Download` gives the same list as text for a script.
