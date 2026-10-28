# jemu changelog

## 0.2.0
* **Added (a screen):** the machine has a screen: a frame buffer at `0x0B000000` (ADDR, WIDTH, HEIGHT, FLUSH). `jemu --system KERNEL --screen FILE.ppm` saves the picture on every FLUSH; `--gfx FILE` shows it live in the Jaric app (about 25 pictures a second, through the `7777;gfx` messages the app already has).
* **Added:** `jemu boot`: the start screen of Jaric OS, live in the Jaric app: a ring of light, then "Jaric OS", then "powered by Jaric" (the kernel `jemu-boot` comes with the tool; the picture stays two seconds at the end).
* **Fixed:** none.

## 0.1.0
* **Added:** the tool `jemu`, a machine that runs programs for ARM64: `jemu PROGRAM` runs a Linux ARM64 program (the host answers its calls); `jemu --system KERNEL.elf [--disk IMAGE] [--shift N] [--steps N]` runs a kernel (exception levels, MMU, timer, a UART, a disk); **`jemu os [FOLDER]` starts Jaric OS**: the files of FOLDER (default `~/.jemu-os`, made with two small files the first time) are its disk, and a console answers `ls`, `cat NAME`, `echo TEXT`, `help`, `exit`. The kernel (`jemu-kernel`) and the disk maker (`jemu-mkfs`) come with the tool and sit next to it. On a terminal the keys go to the machine one by one without echo; Ctrl-C stops it.
