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

## Install
```
jget tool zipj                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s zipj     # with curl (no jget needed)
```
In jsh: `install zipj`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Pack: `zipj out.zip file1 folder` (folders go in with everything inside).
2. Look inside first: `unj out.zip -l`.
3. Open: `unj out.zip` (here), `unj out.zip -f` (into a folder named like the file) or `unj out.zip -o dest`.
4. A password: `zipj out.zip secret.txt -p` asks for it (nothing is shown while you type); `unj out.zip -p word` or leave `-p` out and it asks. The old ZIP password is not strong.
5. A `.gz` file opens with `unj file.gz`. A name with `..` or a first `/` is skipped on purpose.
