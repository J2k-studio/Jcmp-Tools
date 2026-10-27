# calc changelog

## 0.1.1
* **Fixed:** an empty line (a press of Enter) left the prompt; now it only shows the prompt again. `exit`, `quit`, `q` or Ctrl-D leave. The binary form is written in whole groups of four (`0b0001_0110`, not `0b1_0110`).

## 0.1.0
* **Added:** the tool `calc`, a calculator for the terminal: `calc "1 + 2 * 3"`, or `calc` for a prompt (an empty line leaves). Whole numbers are 64 bit and are shown in decimal, hex, binary and octal; numbers with a point are doubles (12 digits). Number forms `255 0xff 0b1111_1111 0o377 16#ff 3.14 1e3`; operators `+ - * / // % mod **`, `<< >>`, `< <= > >= == !=`, bit operations `and &`, `or |`, `xor`, `not ~`; functions `sqrt cbrt sin cos tan asin acos atan atan2 sinh cosh tanh exp ln log log2 abs floor ceil round trunc min max pow hypot gcd lcm fact popcount bswap deg rad`; names `pi e tau ans` and your own (`x = 5`). `-q` prints only the value.
