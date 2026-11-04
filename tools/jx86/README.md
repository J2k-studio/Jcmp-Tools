# jx86

An **x86_64 emulator for Linux programs**, written in J2K. It runs a static x86_64 ELF (a freestanding program, or the output of the x86 backend of `jcmp` when it exists)
on any machine: this ARM64 phone, a Raspberry Pi, a PC. One program of 800 lines, no libraries.

```
jx86 PROGRAM [ARGS...]          run the program; its output and its exit code are the ones of the program
jx86 --count PROGRAM            at the end: how many instructions ran, and the commonest opcodes
jx86 --limit N PROGRAM          stop after N instructions (exit code 124): for a program that does not end
jx86 --version
```
**What it is for.** (1) To test the x86_64 backend of `jcmp` (version 1.4) on the phone where it is written. (2) A tool that can *measure*: instruction counts now; later a trace, a simulated cache and an
estimate of cycles for a CPU model (step E5 of `design 29` in the compiler repository), which is what the tuning of 1.5 needs. (3) The CPU of an x86_64 Jaric OS.

## What it runs (step E1: the integer core)
Prefixes (66, F2, F3, segment FS, REX), the instructions that compilers use for integers: `mov lea add or adc sbb and sub xor cmp test inc dec neg not mul imul div idiv shl shr sar rol ror shld shrd
bt bts btr btc bsf bsr tzcnt lzcnt bswap cmpxchg xadd xchg movzx movsx movsxd cmovcc setcc jcc jmp call ret push pop leave cbw cwde cdqe cwd cdq cqo pushf popf` with the right flags, the string
instructions (`movs stos lods cmps scas` with `rep`), `cpuid` (a plain x86_64 with SSE2), and the Linux system calls `read write writev exit exit_group brk mmap` (anonymous) `munmap mprotect madvise
arch_prctl clock_gettime getpid gettid uname getrandom futex`. A program that uses something else stops with the address and the bytes of the instruction (`unknown instruction`).
Not yet: floating point and SIMD (E2, E3), threads (E4), a dynamic loader, files (`open`), AVX (E6).

## How it is tested
`sh test.sh` builds freestanding C programs for x86_64 with `clang` at -O0, -O1, -O2 and -Os (arithmetic of every size and sign, calls, structs, switch tables, function pointers, arrays, sorting,
bit tricks) and requires the same output and exit code from `jx86` and from `qemu-x86_64` (`pkg install qemu-user-x86-64` in Termux): 16 runs. Needs clang with lld, and qemu.

## Speed (honest)
A plain interpreter that decodes every instruction again: about 4.5 million instructions per second on this phone (fib(30), 27 million instructions, takes 6 s; qemu takes 0.2 s). Enough for tests
and counting; a decoded-block cache is the next step (target 30 to 100 million per second).

License: MPL-2.0.
