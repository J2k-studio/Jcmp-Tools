# jstore: the store of the programs of Jaric

Find, install and update the programs of Jaric (`.jc` packages) from a list that is a plain text file. Every download is checked with its SHA-256; `jc` (the installer) shows the permissions the program asks for and asks once. Needs [jget](../jget/README.md) (download) and [jc](../jc/README.md) (install).

```
jstore list [WORD]          the programs (version, the permissions they ask for); * = you have it
jstore info ID              one program: where it comes from and its checksum
jstore install ID [-y]      download, check, install (jc asks about the permissions; -y says yes)
jstore update [-y]          the installed programs that have a newer version (-y installs them)
jstore remove ID            delete one
```
The index is `store/index.txt` of [Jcmp-Tools](https://github.com/J2k-studio/Jcmp-Tools/tree/main/store). Your own store: a file with lines `ID VERSION URL SHA256 PERMISSIONS NAME...` (`-` = no permissions) and `export JSTORE_INDEX="https://example.org/index.txt /sdcard/mystore.txt"` (several, with spaces). In the app: `jaric store`.

## Install
```
jget tool jstore                                                     # with jget (it installs jc too when you also name it: jget tool jc jstore)
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jc jstore     # with curl
```
In jsh: `install jstore`.

## A short lesson
1. `jstore list` shows what the store has (the sample is `store.hello`).
2. `jstore install store.hello` downloads it, checks the checksum and installs it (it asks for no permissions).
3. `jc run store.hello` runs it and prints the permissions it got.
4. Later `jstore update` tells you when there is a new version; `jstore remove store.hello` takes it away.
5. To publish a program of your own: `makej pack`, then `store/add.sh _out/game.jc` in a copy of Jcmp-Tools, or keep your own index file.

License: MPL-2.0. Build: `JCMP=path sh build.sh`. Test: `sh test.sh` (python3; it builds `jc` too).
