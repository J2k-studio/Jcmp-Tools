#!/bin/sh
# calc: numbers in every base, the operators, bit operations, functions, variables, the prompt, errors
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/calc"
chk() { [ "$("$J" -q "$1" 2>&1)" = "$2" ] || { echo "calc test: $1 gave '$("$J" -q "$1" 2>&1)', wanted '$2'"; exit 1; }; }
[ "$("$J" --version)" = "calc 0.1.1" ] || { echo "calc test: version"; exit 1; }
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
echo "calc tests: ok"
