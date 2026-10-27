# tarj and gzj: tar and gzip files

`tarj` makes and opens `.tar` / `.tar.gz` / `.tgz`, `gzj` packs one file with gzip. Written in J2K (library `deflate`). One program with two names: `jget tool tarj` installs it and a link `gzj`.

```
tarj c out.tar.gz src docs    make an archive (.gz or .tgz in the name: gzip too); folders go in with everything inside
tarj x out.tar.gz             open here (a gzip inside is found by itself)
tarj x out.tar -o dest        open into dest
tarj t out.tar                only list the names
gzj notes.txt                 make notes.txt.gz (the original is removed; -k keeps it)
gzj -d notes.txt.gz           open it again
gzj -c notes.txt | ...        write to a pipe
```
-q is quiet. File modes (the x bit) are kept. Links and special files are skipped with a message; names with `..` or a first `/` are refused.
License: MPL-2.0. Build: `JCMP=path sh build.sh` (the library: `jget -li install deflate`). Test: `sh test.sh` (needs tar and gzip).

## Install
```
jget tool tarj                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s tarj     # with curl (no jget needed)
```
In jsh: `jc install tarj`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Pack a folder: `tarj c backup.tar.gz src docs`.
2. List it: `tarj t backup.tar.gz`. Open it: `tarj x backup.tar.gz -o restore`.
3. One file with gzip: `gzj notes.txt` (makes `notes.txt.gz`, `-k` keeps the original); back with `gzj -d notes.txt.gz`.
4. Into a pipe: `gzj -c big.log > big.log.gz`; `-q` makes tarj quiet.
