# jemu: a machine for programs and for Jaric OS

`jemu` runs programs written for a processor of the ARM64 kind inside itself, and in *system mode* it is a whole small computer on which a kernel can run: that is how Jaric OS (the operating system of the Jaric project, written in J2K) is built and tried on the phone.

```
jemu os                      start Jaric OS (the files of ~/.jemu-os are its disk)
jemu os FOLDER               the same, with the files of FOLDER as the disk
jemu PROGRAM [arguments]     run a Linux ARM64 program (jcmp makes them); the host answers its system calls
jemu --system KERNEL.elf [--disk IMAGE] [--shift N] [--steps N]    run a kernel of your own
jemu --version | --help
```

## Jaric OS in `jemu os`
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
In jsh: `jc install jemu`. The kernel `jemu-kernel` and the disk maker `jemu-mkfs` are put next to `jemu`.

## A short lesson
1. `jemu os`, then `ls`, `cat hello.txt`, `echo hello`, `exit`.
2. Put your own files on the disk: `mkdir ~/disk; echo notes > ~/disk/notes.txt; jemu os ~/disk`, then `cat notes.txt`.
3. Run a program of your own in the machine: `jcmp hello.jk -o hello; jemu hello`.
4. Write a kernel: see `os/kernel/k1_exceptions.jk` in the Jaric repository (a raw file starting with `#!library`); `jemu --system k1.elf` runs it.

License: MPL-2.0. Build: `JCMP=path sh build.sh` (needs a jcmp that allows functions with a value in a `#!library` file; the kernel is built with it, the released tool brings the result). Test: `sh test.sh`.
