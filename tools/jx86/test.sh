#!/bin/sh
# jx86: every test program (freestanding C, built for x86_64 with clang at several optimisation levels) must give the same output and exit code in jx86 as in qemu-x86_64
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jx86"
[ "$($J --version)" = "jx86 $(cat VERSION)" ] || { echo "jx86 test: --version differs from VERSION"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ok=0; bad=0
for src in tests/t*.c; do
    name=$(basename "$src" .c)
    for opt in -O0 -O1 -O2 -Os; do
        clang --target=x86_64-linux-gnu -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -mno-sse -mno-mmx -mno-avx -nostdlib -static -fuse-ld=lld $opt -Itests "$src" -o "$T/p" 2>"$T/cc.err" || { echo "FAIL  $name $opt (compile)"; head -3 "$T/cc.err"; bad=$((bad+1)); continue; }
        e=0; qemu-x86_64 "$T/p" > "$T/q.out" 2>/dev/null || e=$?
        g=0; timeout 120 "$J" "$T/p" > "$T/j.out" 2> "$T/j.err" || g=$?
        if [ "$e" = "$g" ] && cmp -s "$T/q.out" "$T/j.out"; then ok=$((ok+1)); echo "PASS  $name $opt ($(wc -l < "$T/q.out") lines, exit $e)"; else bad=$((bad+1)); echo "FAIL  $name $opt: qemu exit $e, jx86 exit $g"; head -2 "$T/j.err"; diff "$T/q.out" "$T/j.out" | head -4; fi
    done
done
echo "passed $ok, failed $bad"; [ $bad = 0 ]
