# zipj and unj: zip files

`zipj` makes a .zip, `unj` opens one (and a .gz). Written in J2K (the library is `zipcore.j`: CRC-32, DEFLATE, ZIP, and the old ZIP password). One program with two names: `jget tool zipj` installs it and a link `unj`.

```
unj test.zip                 open here, without a folder
unj test.zip -f              open into a folder named like the file (test)
unj test.zip -o dest         open into dest
unj test.zip -l              only list (a * marks the files with a password)
unj test.zip a.txt sub       only these files or folders
unj test.zip -p secret       the password on the line; without it a field asks for it (nothing is shown while you type)
unj file.gz                  a gzip file

zipj out.zip file1 folder    make a zip; folders go in with everything inside
zipj out.zip a.txt -p        ask for a password (twice);   -P secret   give it on the line;   -q  quiet
```

* The old password of ZIP (ZipCrypto) is used, the one every program knows; it is **not strong**. A stronger one (AES) may come.
* A name with `..` or a path from the root is skipped (nothing is written outside the folder).
* Zips made here are read by `unzip` and Python; zips made by them are read here (tested).
* Not yet: tar, zip64 (files over 4 GB), AES.

```
sh build.sh      # needs jcmp 1.1.0.0 or newer (JCMP=path chooses the compiler)
sh test.sh       # needs python3 and gzip
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).
