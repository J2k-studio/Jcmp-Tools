#!/bin/sh
# the small commands of Jaric: each result is compared with the expected text
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
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
echo "jbox test: ok"
