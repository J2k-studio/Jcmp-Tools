#!/bin/sh
# calc: numbers in every base, the operators, bit operations, functions, variables, the prompt, errors
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/calc"
chk() { [ "$("$J" -q "$1" 2>&1)" = "$2" ] || { echo "calc test: $1 gave '$("$J" -q "$1" 2>&1)', wanted '$2'"; exit 1; }; }
[ "$("$J" --version)" = "calc 0.3.0" ] || { echo "calc test: version"; exit 1; }
chk "1 + 2 * 3" 7
chk "(1 + 2) * 3" 9
chk "0xff xor 0x0f" 240
chk "0xdeadbeef xor 0xffffffff" 559038736
chk "255 & 0x0f | 0x100" 271
chk "1 << 40" 1099511627776
chk "~0" -1
chk "not 5" -6
chk "16#ff + 0b101 + 0o17" 275
chk "1_000 * 3" 3000
chk "7/2" 3.5
chk "8/2" 4
chk "7//2" 3
chk "-7//2" -4
chk "10 mod 3" 1
chk "10 % 4" 2
chk "2**10" 1024
chk "2**3**2" 512
chk "-2**2" -4
chk "0.1 + 0.2" 0.3
chk "sqrt(16)" 4
chk "gcd(12, 18)" 6
chk "lcm(4, 6)" 12
chk "fact(10)" 3628800
chk "popcount(255)" 8
chk "max(3, 9) + min(3, 9)" 12
chk "5 > 3" 1
chk "5 == 6" 0
chk "1e3 + 0.5" 1000.5
chk "abs(0 - 7)" 7
# logic: && || ! give 1 or 0; and or not are bit by bit; nand nor xnor
chk "5 && 2" 1
chk "5 && 0" 0
chk "0 || 7" 1
chk "!5" 0
chk "!0 && 1" 1
chk "5 != 4 && 3 > 1" 1
chk "5 & 2" 0
chk "0b1100 nand 0b1010" -9
chk "0b1100 nor 0b1010" -15
chk "0b1100 xnor 0b1010" -7
chk "nand(1, 1) & 1" 0
chk "imp(1, 0)" 0
chk "bit(0b100, 2)" 1
chk "setbit(0, 3)" 8
chk "clrbit(15, 0)" 14
chk "togbit(5, 1)" 7
chk "rotl(0x80000000, 1, 32)" 1
chk "rotr(1, 1, 8)" 128
chk "clz(1, 8)" 7
chk "ctz(8)" 3
chk "parity(7)" 1
chk "signed(0xff, 8)" -1
chk "mask(0x1234, 8)" 52
# science
chk "5!" 120
chk "3! + 1" 7
chk "ncr(5, 2)" 10
chk "npr(5, 2)" 20
chk "logb(8, 2)" 3
chk "root(27, 3)" 3
chk "sign(0 - 9)" -1
chk "int(7.9)" 7
chk "frac(2.5)" 0.5
chk "c0" 299792458
chk "g0" 9.80665
chk "qe" 1.602176634e-19
chk "h = 3" 3
# the answer shows every base for a whole number
"$J" 255 | grep -q "hex  0xff" || { echo "calc test: hex"; exit 1; }
"$J" 255 | grep -q "bin  0b1111_1111" || { echo "calc test: bin"; exit 1; }
"$J" -1 | grep -q "hex  0xffffffffffffffff" || { echo "calc test: negative in hex"; exit 1; }
"$J" 22 | grep -q "bin  0b0001_0110" || { echo "calc test: binary in whole groups of four"; exit 1; }
# errors
"$J" "1/0" >/dev/null 2>&1 && { echo "calc test: 1/0 must fail"; exit 1; }
"$J" "(1+2" >/dev/null 2>&1 && { echo "calc test: a missing ) must fail"; exit 1; }
"$J" "foo" >/dev/null 2>&1 && { echo "calc test: an unknown name must fail"; exit 1; }
"$J" "sqrt(0-1)" >/dev/null 2>&1 && { echo "calc test: sqrt of a negative must fail"; exit 1; }
# the prompt: variables and ans, an empty line leaves
[ "$(printf 'x = 5\nx * 2\nans + 1\n\n' | "$J" -q)" = "$(printf '5\n10\n11')" ] || { echo "calc test: variables and ans"; exit 1; }
# an empty line does not leave the prompt; exit does
[ "$(printf '1+1\n\n\n2+2\nexit\n9\n' | "$J" -q)" = "$(printf '2\n4')" ] || { echo "calc test: empty lines and exit"; exit 1; }
python3 ui_test.py "$J" || exit 1
echo "calc tests: ok"
