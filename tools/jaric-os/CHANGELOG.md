# jaric-os changelog

## 0.3.0
* **Changed (a real screen, like the screen of a virtual machine):** the system itself draws its letters on the screen (a picture of 540 x 960 dots, a smooth font read from the file `jaric-os-font` of its disk); the machine only shows the picture, as the screen of a virtual machine does. `ls` does not list the files of the system.
* **Changed (the start is a log, not a picture):** no drawn start screen any more; the system looks at the machine and writes what it finds, line by line, in colours: `[ OK ] CPU ARM64, exception level 1`, the counter, a timer tick (really waited for), memory (written and read back), the disk (sectors), the files (JFS), the screen, the input. A failed check shows `[FAIL]`. Then `Jaric OS is ready.` and the prompt.
* **Removed:** `jaric-os boot` and the file `jaric-os-boot`.
* **Fixed (jemu core):** the timer state bit (ISTATUS) is set when the time has come even when the interrupt is masked, as in the hardware.
* **Fixed:** a touch on the screen printed code (the messages of the app were taken for keys); they are dropped now.

## 0.2.0
* **Added (a screen of its own):** in the Jaric app (`JARIC` is set) Jaric OS has its own full screen: the letters the system writes are drawn with a smooth font (the file `jaric-os-font`, made by `mkfont.py` from a mono font of the phone) on a picture of 540 x 960 dots that the app shows over the terminal; the keys (screen keyboard, OTG keyboard) go to the system. A cursor shows where you type.
* **Fixed:** typing in the system did nothing in the app (the keys had no way in).

## 0.1.0 (the tool jemu 0.2.0 became jaric-os)
* **Changed:** the tool is Jaric OS only and its command is `jaric-os`: `jaric-os` (the start screen, then the system), `jaric-os FOLDER`, `jaric-os boot`. The emulator parts (`jemu PROGRAM`, `--system`) need `JARIC_OS_DEV=1` (for developers). The disk folder is `~/.jaric-os`; the files are `jaric-os-kernel`, `jaric-os-mkfs`, `jaric-os-boot`.
* **Added:** the Jaric app brings `jaric-os` inside (an internal tool): `jc update` puts a newer one over it.
* **Fixed:** none.

# history of jemu (before the rename)

## 0.2.0
* **Added (a screen):** the machine has a screen: a frame buffer at `0x0B000000` (ADDR, WIDTH, HEIGHT, FLUSH). `jemu --system KERNEL --screen FILE.ppm` saves the picture on every FLUSH; `--gfx FILE` shows it live in the Jaric app (about 25 pictures a second, through the `7777;gfx` messages the app already has).
* **Added:** `jemu boot`: the start screen of Jaric OS, live in the Jaric app: a ring of light, then "Jaric OS", then "powered by Jaric" (the kernel `jemu-boot` comes with the tool; the picture stays two seconds at the end).
* **Fixed:** none.

## 0.1.0
* **Added:** the tool `jemu`, a machine that runs programs for ARM64: `jemu PROGRAM` runs a Linux ARM64 program (the host answers its calls); `jemu --system KERNEL.elf [--disk IMAGE] [--shift N] [--steps N]` runs a kernel (exception levels, MMU, timer, a UART, a disk); **`jemu os [FOLDER]` starts Jaric OS**: the files of FOLDER (default `~/.jemu-os`, made with two small files the first time) are its disk, and a console answers `ls`, `cat NAME`, `echo TEXT`, `help`, `exit`. The kernel (`jemu-kernel`) and the disk maker (`jemu-mkfs`) come with the tool and sit next to it. On a terminal the keys go to the machine one by one without echo; Ctrl-C stops it.
