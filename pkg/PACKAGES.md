# The list of packages planned for Jaric (2026-10-29)

How: each package is built from the recipes of termux-packages with the prefix of Jaric, on GitHub Actions (aarch64 first, arm later), then put in a release with a SHA-256 and listed in `index.json`. `jc install NAME` installs it and its dependencies. Sizes are guesses; big ones are downloaded only when asked for.

| Package | What | Why for Jaric | Size | Order |
|---|---|---|---|---|
| **git** (done) | the real git | the owner's workflows; jgit stays the small one | ~15 MB | 1 |
| **clang** (done: clang 21.1.8, lld, llvm, ndk-sysroot) | C/C++ compiler (+ lld, libc++) | build C code, compare speed with J2K (`bench/`), build other packages | ~150 MB | 2 |
| **python** (done; pip = python-pip) | Python 3 + pip | scripts, data tools, test helpers | ~40 MB | 3 |
| **dropbear** (done) | ssh client and server (and scp) | log in and copy files | ~1 MB | 4 |
| **openjdk** (java) | the JDK 17+ and `jar` | Java and Kotlin apps, Gradle later; the owner asked for java | ~120 MB | 5 |
| **rust** | rustc + cargo + std | Rust programs; the owner asked for rust | ~700 MB (large; optional) | 6 |
| **nodejs** | node + npm | web tools, scripts | ~40 MB | 7 |
| **sqlite** | the database | data apps, until our own `jsql` | ~2 MB | 8 |
| **make / cmake / ninja** | build tools | C projects | ~20 MB | 9 |
| **ffmpeg** | video and audio tools | convert media, till our own decoders | ~30 MB | 10 |
| **vim / nano / micro** | editors | those who like them | ~5 MB each | 11 |
| **ripgrep, fd, jq, htop, tmux, curl, wget, unzip, xz, zstd** | the usual small tools | work in the terminal | 1-5 MB each | 12 |
| **go, ruby, lua, php, perl** | other languages | on request | 10-100 MB | later |
| **ollama-like runner / llama.cpp** | a model runner in C++ (until `neuron` has GGUF) | a local assistant early; the owner wants local | ~10 MB + models | after clang |

Rules: free licences only (the licence file travels in the package); one package = one archive + one line in `index.json`; a recipe may be a `.sh` in `recipes/`; every package has a test (`NAME --version` runs on the phone); a page of the list in the README of this repo.
Hard parts: the prefix path is inside the binaries (rebuilding everything with the Jaric prefix is a must); Android 10 needs targetSdk 28 for running them (Jaric has it); rust and java build for hours (GitHub Actions has 6 hours a job: split into steps); some packages need Android-specific patches (termux has them).
