# drive changelog

## 0.2.0
* **Added:** sizes. `drive new NAME 2G` (or `NAME PATH 500M`) gives a drive a limit; `drive size NAME 1.5G|none` changes it; `drive NAME` shows used / limit and the percent; the list shows the limit; `drive check` lists the drives with a limit and exits with the number that are over. Units K, M, G, T (1024-based, decimals allowed). The limit is shown and checked, not enforced by the system yet (a plain folder cannot be stopped from growing; the Jaric kernel / VM will).

## 0.1.0
* **Added:** the tool `drive`: `drive` (the list), `drive NAME` (where a drive is and how many entries it holds), `drive new NAME` (a new drive with a new folder in `~/drives/NAME`), `drive new NAME PATH` (a drive of a folder that is there), `drive remove NAME [-d]` (take a drive away; `-d` also deletes its folder, only if `drive new` made it). It keeps the list in `~/.jsh_drives`, the file jsh reads, so a new drive is seen at once in the prompt and in paths (`NAME:/file`).
