# Changelog

## 1.2.0.0
* **Added (the compiler):** inheritance (`struct Dog : Animal`, `virtual` / `override`), `-dyn` dynamic executables (native GPU: OpenGL ES, Vulkan), `-j N` many cores and `-progress FILE`, `Fs::read.text / bytes / lines`, `Cpu::inst` with `s0 d0 w0 v0` register names, the loop rotation pass (`-norot` switches it off).
* **Fixed:** a `bool` field of a struct used 8 bytes instead of 1.
* **Why this release of the tool:** the tools makej, mujic, neuron, jamanager and jash need jcmp 1.2.0.0 or newer (the escape `\e`, `Fs::read_bytes`, `Option`/`switch` forms). The tool had stayed at 1.0.0.0 and many phones still have jcmp 0.9.x, which fails with "unknown escape sequence". `jget tool jcmp` now installs 1.2.0.0 with its Library.

## 1.0.0.0
* The compiler 1.0.0.0 and its library as a tool.

## Unreleased
* Brings the coderin extension `jcmp` (snippets, words, commands for J2K) in coderin-extensions/.
