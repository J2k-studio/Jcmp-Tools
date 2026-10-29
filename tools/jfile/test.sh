#!/bin/sh
# jfile: the commands (ls, cp, mv, rm, mkdir, places) and the screen on a pseudo terminal (keys in, the folder and the text out)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jfile --version)" = "jfile $(cat VERSION)" ] || { echo "jfile test: --version differs from VERSION"; exit 1; }
./_out/jfile --help > /dev/null || { echo "jfile test: --help"; exit 1; }
J="$PWD/_out/jfile"; ROOT="$PWD"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p a/inner; echo "one" > a/f1.txt; echo "two" > a/inner/f2.txt; head -c 3000 /dev/zero > big.bin
"$J" ls . | grep -q "^a/	" || { echo "jfile test: ls shows a folder with /"; exit 1; }
"$J" ls . | grep -q "^big.bin	3000	" || { echo "jfile test: ls shows the size"; exit 1; }
"$J" places | grep -q "Downloads" || { echo "jfile test: places"; exit 1; }
"$J" cp a b > /dev/null || { echo "jfile test: cp of a folder"; exit 1; }
[ "$(cat b/inner/f2.txt)" = "two" ] || { echo "jfile test: the copy of a folder is not complete"; exit 1; }
"$J" cp big.bin a > /dev/null && [ "$(wc -c < a/big.bin)" = "3000" ] || { echo "jfile test: cp of a file into a folder"; exit 1; }
"$J" mv b c > /dev/null || { echo "jfile test: mv"; exit 1; }
[ ! -e b ] && [ -f c/f1.txt ] || { echo "jfile test: mv left the old name"; exit 1; }
"$J" mkdir d > /dev/null && [ -d d ] || { echo "jfile test: mkdir"; exit 1; }
"$J" rm c > /dev/null || { echo "jfile test: rm"; exit 1; }
[ ! -e c ] || { echo "jfile test: rm of a folder with files"; exit 1; }
if "$J" rm / > /dev/null 2>&1; then echo "jfile test: rm / must be refused"; exit 1; fi
if "$J" cp nothere x > /dev/null 2>&1; then echo "jfile test: cp of a missing file must fail"; exit 1; fi
cd "$ROOT"
python3 -I ui_test.py "$J" "$T/ui" || { echo "jfile test: the screen"; exit 1; }
echo "jfile tests passed"
