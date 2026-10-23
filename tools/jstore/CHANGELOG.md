# jstore changelog

## 0.1.0
* **Added:** the tool `jstore`, the store of the programs of Jaric (`.jc` packages): `jstore list [WORD]` (a `*` marks the installed ones, the permissions are shown), `info ID`, `install ID [-y]`, `update [-y]`, `remove ID`. The index is a text file (`ID VERSION URL SHA256 PERMISSIONS NAME`); the default is `store/index.txt` of Jcmp-Tools, `JSTORE_INDEX` names others (addresses or files, separated by spaces; a local store works).
* **Safety:** every package is checked with the SHA-256 of the index before `jc install` sees it (a wrong sum installs nothing); `jc` shows the permissions and asks once; an update asks again for permissions the old version did not have. Needs the tools `jget` and `jc`.
