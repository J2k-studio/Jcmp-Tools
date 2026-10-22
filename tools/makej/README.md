# makej

A build tool for [J2K](https://github.com/J2k-studio/Jcmp) projects. You write the build file in one of two ways (the owner chose both, 2026-10-22):

**1. A plain file, by hand: `nano makej`** (a simple TOML; `makej init` writes a starting one)

```
[makej]
out = "_out"

[program.jemu]
main = "core/jemu.jk"
flags = ""

[library.core]
main = "core/core.jk"
flags = "-l"

[step.test]
run = "sh tools/run_tests.sh"
needs = "jemu"
```

**2. A J2K program `makej.jk`** (when you need loops, conditions, reading files); it wins if both exist:

```jk
#import <stdlib>
#import <makej>

int main() {
    Build b = Build::make();
    b.program("jemu", "src/main.jk", "");          // jcmp src/main.jk -o _out/jemu
    b.library("core", "core/core.jk", "-l");       // _out/libcore.so   (needs jcmp 1.1: -l)
    b.step("test", "sh test.sh");
    b.needs("test", "jemu");
    return b.run();
}
```

* `makej list` shows the targets and what they need; `makej clean` removes the folder of the results; `makej -n` shows what would be built (nothing runs); `makej install FOLDER` builds and copies the results there; `makej init` writes a starting `makej`, `makej init -ai` an AI project. The end says how long it took.
* `makej -j 4` builds 4 things at once (the default is the number of cores); a target starts as soon as what it needs is done.
* `makej` builds every program and library (the target `all`); `makej test` builds `test` and what it needs first; `makej -v` shows the commands.
* A program or library is built again only when a `.jk` / `.j` file in the folder of its main file (and below) is newer than the result.
* A step is any shell command. `needs(a, b)`: b is made before a.
* Install: put this folder anywhere and link `makej` into your `PATH`; the library `lib/makej.j` is found next to the script (or in `MAKEJ_LIB`).

Status: a prototype (2026-10-22) written before the usage was designed; the design and its open questions are in [docs/usage-design.md](docs/usage-design.md). Nothing about the commands or the build file is final.
