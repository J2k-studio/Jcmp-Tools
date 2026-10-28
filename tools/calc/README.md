# calc: a calculator for the terminal

Do sums, bit operations (xor, and, or, shifts), conversions between decimal, hex, binary and octal, and the usual functions. Whole numbers are 64 bit.

```
calc "1 + 2 * 3"           7
calc 0xff xor 0x0f         240   and the same number in hex, binary, octal
calc "7/2"                 3.5   (8/2 is 4, 7//2 is 3)
calc "sqrt(2) * pi"
calc                       a prompt: x = 5, x * 2, ans + 1; exit, quit or Ctrl-D leaves (an empty line only shows the prompt again)
calc -q "255 & 0x0f"       only the value (for scripts)
```
Numbers: `255 0xff 0b1111_1111 0o377 16#ff 3.14 1e3 1_000`. Operators: `+ - * / // % mod **` (power), `<< >>`, `< <= > >= == !=`, `and &`, `or |`, `xor`, `not ~`. In J2K `^` is a pointer, so the bit xor is the word `xor`. Names: `pi e tau ans` and your own (`x = 5`). Functions: `sqrt cbrt sin cos tan asin acos atan atan2 sinh cosh tanh exp ln log log2 abs floor ceil round trunc min max pow hypot gcd lcm fact popcount bswap deg rad` (`calc --help` lists them).

A whole number is shown as `255`, `hex 0xff`, `bin 0b1111_1111`, `oct 0o377`; a negative one is shown as 64 bit in hex and binary.

## Install
```
jc install calc                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s calc     # with curl
```
In jsh: `jc install calc`.

## A short lesson
1. Add things up: `calc "12 * (3 + 4)"`.
2. Bits: `calc "0b1100 xor 0b1010"` shows 6 and `0b0110`; `calc "1 << 12"` is 4096 (`0x1000`).
3. Change a base: `calc 0xff` shows decimal, binary and octal; `calc 16#ff` and `calc 2#1010` read other bases.
4. Use the prompt: type `calc`, then `r = 3`, `pi * r ** 2`, `ans / 2`.
5. In a script: `n=$(calc -q "fact(5)")`.

License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.2.0.0 or newer). Test: `sh test.sh`.
