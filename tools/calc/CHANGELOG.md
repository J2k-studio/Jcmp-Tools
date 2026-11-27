# calc changelog

## 0.3.0
* **Added:** logic (`&& || !`, `nand nor xnor`, `imp`), bit tools (`bit setbit clrbit togbit mask signed rotl rotr clz ctz parity`), science (`n!`, `ncr npr logb root asinh acosh atanh sign int frac`), constants (`c0 g0 G h hbar qe me mp NA kB Rgas phi`), `deg` / `rad`.
* **Added:** every result also in science form (`sci`); the screen shows dec, hex, bin, oct, sci and the character.
* **Changed:** the screen is typed on the keyboard, with a cursor in the line; the keys to tap are gone. `&&` and `||` now give true or false (the bit forms are `&` and `|`).
* **Fixed:** your variable `h` (and others) comes before a constant of the same name.

## 0.2.0
* **Added:** `calc` alone is a calculator on the whole screen: the history, the line with its result as you type, hex and binary, keys to tap or type. The old prompt is `calc -l` (pipes work as before).
* **Fixed:** none.

## 0.1.1
* **Fixed:** an empty line (a press of Enter) left the prompt; now it only shows the prompt again. `exit`, `quit`, `q` or Ctrl-D leave. The binary form is written in whole groups of four (`0b0001_0110`, not `0b1_0110`).

## 0.1.0
* **Added:** the tool `calc`, a calculator for the terminal: `calc "1 + 2 * 3"`, or `calc` for a prompt (an empty line leaves). Whole numbers are 64 bit and are shown in decimal, hex, binary and octal; numbers with a point are doubles (12 digits). Number forms `255 0xff 0b1111_1111 0o377 16#ff 3.14 1e3`; operators `+ - * / // % mod **`, `<< >>`, `< <= > >= == !=`, bit operations `and &`, `or |`, `xor`, `not ~`; functions `sqrt cbrt sin cos tan asin acos atan atan2 sinh cosh tanh exp ln log log2 abs floor ceil round trunc min max pow hypot gcd lcm fact popcount bswap deg rad`; names `pi e tau ans` and your own (`x = 5`). `-q` prints only the value.
