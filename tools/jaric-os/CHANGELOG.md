# jaric-os changelog

## 0.8.0
* **Added (programs run in Jaric OS):** a program of the disk (an ARM64 ELF made by jcmp) runs under the console: `run NAME` in the Terminal. The system turns the MMU on, gives the program page tables of its own, starts it at EL0 and answers its calls (write, read, brk, mmap, clock, exit ...); the console goes on when it ends (`exit N`).
* **Added (the screen and the touch for programs):** call 400 shows a picture (blue, green, red, alpha; width, height) on the screen of the system; call 401 gives the last touch (seq, x, y, state, id). Samples: `examples/hello.jk`, `examples/draw.jk` (a gradient and a square that follows the finger).
* **Changed (inside):** the kernel is in several files (`kernel.jk` and `k_screen.j`, `k_proc.j`, `k_start.j`, `k_phone.j`, `k_store.j`, `k_term.j`, put together with `#import`); the kernel is loaded 256 MB higher so that programs can have the addresses from 4 MB; the host reads the input without waiting when a program asks for the touch.

## 0.7.0
* **Added (jstore in the system, as a command and as an app):** the console of Jaric OS has the command `jstore`: `jstore list` (the programs of the store, `*` = on the disk), `jstore install ID`, `jstore remove ID`; the app on the home screen is called `jstore` and uses the same store. On the terminal of the phone `jstore` is the tool of Jcmp-Tools (a command line), in Jaric OS it is the command and the app.
* **Added:** the host call `remove ID` (delete the package from the folder of the disk).

## 0.6.0
* **Added (the store):** the Store app (in the dock): it asks the host for the programs of jstore (`jstore lines`), shows them with a button (Install / Got it); a tap on Install downloads the package into the folder of the disk (`jstore get`, checked with its SHA-256), the disk is made again and read again, and the new app is on the home screen at once. The system reaches the host only through a host call device (`list`, `get ID`, `remount`; nothing else).
* **Changed:** the disk has room for packages: 4096 sectors (2 MB) at least. The apps of the system in the dock are Terminal, Files, Store and About; Clock moved to the home screen.
* **Needs:** the tool `jstore` 0.2.0 (`jc install jstore`; the Jaric app brings it).

## 0.5.0
* **Added (a phone, not a console):** after the log the system shows a home screen: a dark blue wallpaper, a status line with the uptime, a card about the machine, a grid of icons for the `.jc` packages found on the disk (name from the file, a coloured icon with its first letter) and the Power icon, a dock with Terminal, Files, Clock and About, and a home bar. A tap opens an app; `< Home` at the top (or a tap at the bottom edge) goes back.
* **Added (apps of the system):** Terminal (the console, with the keyboard that comes only here), Files (the files of the disk with their sizes), Clock (the time since start), About (what the start found), Power (turns the machine off). A `.jc` package opens a card with its name and size; running the program of a package comes next (the system must read the zip and start the program on the screen).
* **Added (devices):** the screen has a KEYBOARD register (the app shows or hides its keyboard); the back key of the app turns the machine off.

## 0.4.0
* **Changed (the log is on the terminal):** the start writes one line for each check on the terminal, like the start of Linux but short: `[ seconds ] [ OK ] CPU ... core 0`, counter, timer, memory (three places), UART, disk, files, font, screen, touch, input; green `[ OK ]`, red `[FAIL]`. When it is done the system moves to its own screen.
* **Fixed (full screen):** the picture is 540 dots wide and as high as the phone (the app says it in `JARIC_SCREEN`): no bars; the keyboard does not shrink it any more: the part that is seen is cut, the system is told the seen height (`gfx-view`) and keeps the cursor in sight.
* **Fixed:** code printed when a key was held (only plain letters go to the system).

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
