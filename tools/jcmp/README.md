# jcmp: the J2K compiler, as a tool

The compiler of [github.com/J2k-studio/Jcmp](https://github.com/J2k-studio/Jcmp) (Linux ARM64) and its library, so that a machine that has only `jget` can get the language:

```
jget tool jcmp            # or, in jsh:  install jcmp
```

It puts `jcmp` next to `jget` and the folder `Library` (the pair of the compiler: the compiler reads its library from there) in the same place, after a check of their SHA-256. Then `jcmp hello.jk -o hello && ./hello` works. A new compiler needs its own library, so `jget tool jcmp` always installs both.

Licence: the licence of the compiler (see its repository); this folder only carries the files of a release.

## Install
```
jget tool jcmp                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jcmp     # with curl (no jget needed)
```
In jsh: `install jcmp`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Install the compiler and its library: `jget tool jcmp` (they come as a pair). Check: `jcmp -version`.
2. Write `hello.jk`:  `int main() { cout << "hello\n"; return 0; }`
3. Build and run: `jcmp hello.jk -o hello && ./hello`. Always give `-o`.
4. Faster builds: `jcmp big.jk -o big -j 4` uses four cores; `-progress FILE` writes the percent for a tool.
5. More: `jcmp -help`, the tutorial `docs/TUTORIAL.md` of the language repository, and `jget -li list` for libraries.
