# drive: the drives of Jaric

`f:/` is your home, `0:/` the storage of the phone, `r:/` the root. `drive` makes more: a new place of your own (a new folder in `~/drives`) or a name for a folder you have. The list is the file `~/.jsh_drives`, which jsh reads, so `songs:/` works in every command at once.

```
drive                       the list
drive songs                 where a drive is, how many entries it holds
drive new work              a new drive with a new folder (~/drives/work)
drive new songs /storage/emulated/0/Music     a drive of a folder that is there
drive remove work -d        take it away; -d: delete its folder too (only a folder that drive new made)
```
A name is letters, digits and `_` (up to 12). `f`, `0` and `r` belong to the system.

## Install
```
jget tool drive                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s drive     # with curl
```
In jsh: `jc install drive`.

## A short lesson
1. Make a place: `drive new work`, then `cd work:/` and `pwd`.
2. Name a folder you have: `drive new songs /storage/emulated/0/Music`, then `dir songs:/`.
3. Look: `drive` and `drive songs`.
4. Finish: `drive remove work -d` (the folder goes too) or `drive remove songs` (the folder stays).

License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.2.0.0 or newer). Test: `sh test.sh`.
