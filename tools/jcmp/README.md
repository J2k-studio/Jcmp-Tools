# jcmp: the J2K compiler, as a tool

The compiler of [github.com/J2k-studio/Jcmp](https://github.com/J2k-studio/Jcmp) (Linux ARM64) and its library, so that a machine that has only `jget` can get the language:

```
jget tool jcmp            # or, in jsh:  install jcmp
```

It puts `jcmp` next to `jget` and the folder `Library` (the pair of the compiler: the compiler reads its library from there) in the same place, after a check of their SHA-256. Then `jcmp hello.jk -o hello && ./hello` works. A new compiler needs its own library, so `jget tool jcmp` always installs both.

Licence: the licence of the compiler (see its repository); this folder only carries the files of a release.
