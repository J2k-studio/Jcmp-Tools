# The store of Jaric

The programs of the store are `.jc` packages (zip files made by `makej pack`); `store/index.txt` lists them: `ID VERSION URL SHA256 PERMISSIONS NAME`. The tool [jstore](../tools/jstore/README.md) reads it:
```
jstore list        jstore install store.hello        jstore update
```
Every download is checked with the SHA-256 of the index before it is installed, and `jc` shows the permissions of the program and asks once.
**Add a program (the maker):** `makej pack` -> `store/add.sh _out/game.jc` (the id, the version, the name and the permissions come from the manifest) -> commit and push. Only packages of this repository are listed; anyone can run their own store: an index file in the same form, named in `JSTORE_INDEX`.
