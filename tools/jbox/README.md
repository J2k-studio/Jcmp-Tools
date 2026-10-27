# jbox: the small commands in one program

`jbox NAME args`, or a link / copy of `jbox` called NAME. One J2K program with the usual small commands, built on the J2K library only (no libc), so it runs on the same machines as `jcmp`.

Commands: `dir` (also `ls`: columns at a terminal; -a -l -h -1), `cat`, `head` / `tail` (-n N), `wc` (-l -w -c), `mkdir` (-p), `rmdir`, `rm` (-f), `touch`, `cp`, `mv`, `grep` (-n -v -i; the regular expressions of the library), `sort` (-r), `uniq`, `tee` (-a), `seq`, `basename`, `dirname`, `sleep`, `clear`, `env`, `kill`, `true`, `false`. `jbox help` lists them.

```
sh build.sh            # needs jcmp 1.0.0.0 or newer (JCMP=path chooses the compiler)
sh test.sh
```

[jsh](../jsh/README.md) runs jbox for the commands that are not in the PATH.

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder): use it, change it, share it; if you distribute a changed version of these files, you publish the changed files under the same licence.

## Install
```
jget tool jbox                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jbox     # with curl (no jget needed)
```
In jsh: `jc install jbox`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. `jbox help` lists the commands. Use one: `jbox ls -l`, or make links so the plain names work: `jbox --install DIR` (jsh does this for you).
2. Look at text: `cat file`, `head -n 5 file`, `tail -n 5 file`, `wc -l file`.
3. Find: `grep -n word file`, `grep -i -v word file` (the patterns are the regular expressions of the library).
4. Change files: `mkdir -p a/b`, `cp x y`, `mv y z`, `rm -f z`, `touch new`.
5. Combine: `cat names.txt | sort | uniq`, `seq 5`, `ls | wc -l`. More: `rev`, `sha256sum`, `base64`, `uname`, `free`, `nproc`, `tree -d -s`.
