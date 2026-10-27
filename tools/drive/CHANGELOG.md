# drive changelog

## 0.1.0
* **Added:** the tool `drive`: `drive` (the list), `drive NAME` (where a drive is and how many entries it holds), `drive new NAME` (a new drive with a new folder in `~/drives/NAME`), `drive new NAME PATH` (a drive of a folder that is there), `drive remove NAME [-d]` (take a drive away; `-d` also deletes its folder, only if `drive new` made it). It keeps the list in `~/.jsh_drives`, the file jsh reads, so a new drive is seen at once in the prompt and in paths (`NAME:/file`).
