# jaric-os: Jaric OS in the Jaric app

`jaric-os` starts **Jaric OS**, a phone with a home screen (the .jc packages of the disk are the apps),, the operating system of the Jaric project (written in J2K), on a small machine inside the app. It is the internal tool of the app: the app brings a version, and `jc update` puts a newer one over it.

## Install

```
jget tool jaric-os                                                      # with jget
jc install jaric-os                                                     # with jc
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jaric-os     # with curl (no jget needed)
```

Inside Jaric OS the store is the app `jstore` on the home screen and the command `jstore list | install ID | remove ID` in its Terminal (it needs the tool `jstore`).

**Programs:** in the Terminal of the system `run NAME` runs a program of the disk (an ARM64 program made by `jcmp`); see `examples/hello.jk` and `examples/draw.jk` (a picture and the touch: calls 400 and 401).

The Jaric app already has it inside; `jc update` brings a newer one.

```
jaric-os                     the system looks at the machine, writes what it finds (CPU, timer, memory, disk, screen) and waits for your commands; the disk is ~/.jaric-os
jaric-os FOLDER              the same, with the files of FOLDER as the disk
jaric-os --version | --help
```

The machine (a processor of the ARM64 kind with a screen, a disk and a keyboard) is `jemu`, the emulator of the Jaric project; here it runs Jaric OS only. Developers of the system set `JARIC_OS_DEV=1` to run other programs and kernels on it.

## Jaric OS in `jaric-os`
```
Jaric OS: the disk is the files of /home/you/.jemu-os  (exit leaves, Ctrl-C stops the machine)
Jaric OS K7
j> ls
hello.txt
readme.txt
j> cat hello.txt
hello from the disk of Jaric OS
j> echo hi
hi
j> exit
bye
```
The kernel reads the keys from the keyboard of the machine and answers `ls`, `cat NAME`, `echo TEXT`, `help` and `exit`. The disk is a file system of its own (JFS: a flat list of files); it is made again from the folder every time, so what you put in the folder is there. A write that the kernel does to the disk is not kept (the image is made again).

## What the machine has (system mode)
Two levels (user and kernel), exception vectors, `svc` / `eret`, the system registers of a kernel, a timer with interrupts, the MMU (4 levels of tables, pages of 4 KB, blocks of 2 MB and 1 GB, read / write / run rights, the access flag), a UART at `0x0900_0000` (screen and keyboard), an exit device at `0x0910_0000`, a block device (the disk) at `0x0A00_0000`, 64 MB of RAM at `0x4000_0000`. `--shift N` loads the kernel N bytes higher than its file says. Not yet: the NEON instructions (a kernel must not use loops that the compiler turns into vector code), floating point in system mode, more than one processor.

The kernels of every step (exceptions, timer, MMU, tasks, user programs, separate memory, a disk, a console, a normal J2K program loaded from the disk) and their tests are in the Jaric repository (`os/kernel/`, `sh os/kernel/test.sh`); the plan is `docs/os-roadmap.md` there.

## Install
```
jget tool jemu                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jemu     # with curl
```
In jsh: `jc install jaric-os`. The kernel `jemu-kernel` and the disk maker `jemu-mkfs` are put next to `jaric-os`.

## A short lesson
1. `jaric-os`, then `ls`, `cat hello.txt`, `echo hello`, `exit`.
2. Put your own files on the disk: `mkdir ~/disk; echo notes > ~/disk/notes.txt; jaric-os ~/disk`, then `cat notes.txt`.
3. Run a program of your own in the machine: `jcmp hello.jk -o hello; jemu hello`.
4. Write a kernel: see `os/kernel/k1_exceptions.jk` in the Jaric repository (a raw file starting with `#!library`); `jemu --system k1.elf` runs it.

License: MPL-2.0. Build: `JCMP=path sh build.sh` (needs a jcmp that allows functions with a value in a `#!library` file; the kernel is built with it, the released tool brings the result). Test: `sh test.sh`.
