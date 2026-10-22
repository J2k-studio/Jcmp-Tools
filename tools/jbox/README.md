# jbox: the small commands in one program

`jbox NAME args`, or a link / copy of `jbox` called NAME. One J2K program with the usual small commands, built on the J2K library only (no libc), so it runs on the same machines as `jcmp`.

Commands: `ls` (-a -l), `cat`, `head` / `tail` (-n N), `wc` (-l -w -c), `mkdir` (-p), `rmdir`, `rm` (-f), `touch`, `cp`, `mv`, `grep` (-n -v -i; the regular expressions of the library), `sort` (-r), `uniq`, `tee` (-a), `seq`, `basename`, `dirname`, `sleep`, `clear`, `env`, `true`, `false`. `jbox help` lists them.

```
sh build.sh            # needs jcmp 1.0.0.0 or newer (JCMP=path chooses the compiler)
sh test.sh
```

[jsh](../jsh/README.md) runs jbox for the commands that are not in the PATH.

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder): use it, change it, share it; if you distribute a changed version of these files, you publish the changed files under the same licence.
