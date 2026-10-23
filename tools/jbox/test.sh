#!/bin/sh
# the small commands of Jaric: each result is compared with the expected text
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jbox --version)" = "jbox $(cat VERSION)" ] || { echo "jbox test: --version differs from VERSION"; exit 1; }
J="$PWD/_out/jbox"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf 'one\ntwo\nthree\nfour\n' > f.txt
check() { [ "$1" = "$2" ] || { echo "jbox test: $3"; echo "got:    $1"; echo "wanted: $2"; exit 1; }; }
check "$("$J" head -n 2 f.txt)" "one
two" head
check "$("$J" tail -n 1 f.txt)" "four" tail
check "$("$J" wc f.txt)" "4 4 19 f.txt" wc
check "$("$J" grep -n o f.txt)" "1:one
2:two
4:four" grep
check "$("$J" grep -v o f.txt)" "three" grep-v
check "$(printf 'b\na\nb\n' | "$J" sort | "$J" uniq)" "a
b" sort-uniq
check "$("$J" seq 3)" "1
2
3" seq
"$J" mkdir -p d/e; "$J" touch d/x; "$J" cp f.txt d/g.txt; "$J" mv d/g.txt d/h.txt
check "$("$J" dir d)" "e/
h.txt
x" dir
"$J" rm d/h.txt d/x; "$J" rmdir d/e d
check "$("$J" dir)" "f.txt" dir-after
check "$("$J" basename /x/y.txt)" "y.txt" basename
check "$(echo hi | "$J" tee out.txt; "$J" cat out.txt)" "hi
hi" tee
"$J" false && { echo "jbox test: false must fail"; exit 1; } || true
check "$(printf 'a\n\nb\n' | "$J" nl | tr -d ' ' | tr '\n' ,)" "1a,,2b," nl
check "$(printf 'a\nb\nc\n' | "$J" tac | tr '\n' ,)" "c,b,a," tac
echo "jbox test: ok"
check "$(echo 'a b a' | "$J" sed 's/a/X/g')" "X b X" sed-g
check "$(echo 'a b a' | "$J" sed 's/a/X/')" "X b a" sed-first
check "$(printf 'x y\n' | "$J" xargs echo got)" "got x y" xargs
check "$("$J" stat f.txt)" "f.txt: file, 19 bytes" stat
check "$("$J" du f.txt)" "19	f.txt" du
check "$("$J" date +%s | wc -c | tr -d ' ')" "11" date
check "$(seq 1 5 | "$J" less | wc -l | tr -d ' ')" "5" less-pipe
check "$("$J" find . -name 'f.*')" "./f.txt" find
check "$(printf 'a:b\n' | "$J" cut -d : -f 2)" "b" cut
check "$(echo hello | "$J" tr l L)" "heLLo" tr
printf 'one\nTWO\n' > g.txt; printf 'one\ntwo\n' > h.txt
check "$("$J" diff g.txt h.txt)" "< TWO
> two" diff
