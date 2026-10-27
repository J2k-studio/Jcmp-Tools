# jemu changelog

## 0.1.0
* **Added:** the tool `jemu`, a machine that runs programs for ARM64: `jemu PROGRAM` runs a Linux ARM64 program (the host answers its calls); `jemu --system KERNEL.elf [--disk IMAGE] [--shift N] [--steps N]` runs a kernel (exception levels, MMU, timer, a UART, a disk); **`jemu os [FOLDER]` starts Jaric OS**: the files of FOLDER (default `~/.jemu-os`, made with two small files the first time) are its disk, and a console answers `ls`, `cat NAME`, `echo TEXT`, `help`, `exit`. The kernel (`jemu-kernel`) and the disk maker (`jemu-mkfs`) come with the tool and sit next to it. On a terminal the keys go to the machine one by one without echo; Ctrl-C stops it.
