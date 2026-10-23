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
