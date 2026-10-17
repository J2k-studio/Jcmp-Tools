#!/data/data/com.termux/files/usr/bin/bash
# test.sh [JCMP] -- build jget with the compiler JCMP (default: jcmp) and test it. Prints PASS or FAIL lines; the exit code is the number of failures.
# Needs: jcmp with its Library (JCMP_LIB if the library is not next to it), python3 (a local web server for the http:// tests), sha256sum.
cd "$(dirname "$0")" || exit 1
JCMP=${1:-jcmp}
W=${TMPDIR:-/tmp}/jget_test.$$
mkdir -p "$W/src" "$W/lib" "$W/out" "$W/www" || exit 1
FAILS=0
ok()  { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; FAILS=$((FAILS+1)); }
t()   { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
$JCMP jget.jk -o "$W/jget" >"$W/build.txt" 2>&1 || { cat "$W/build.txt"; echo "FAIL  jget does not build"; exit 1; }
J="$W/jget"
head -c 300000 /dev/urandom > "$W/www/big.bin"
printf 'hello jget\n' > "$W/www/page.txt"
printf 'int twice(int x) { return x * 2; }\n' > "$W/www/twice.j"
H=$(sha256sum "$W/www/twice.j" | cut -d' ' -f1)
PORT=$((20000 + $$ % 20000))
(cd "$W/www" && python3 -m http.server $PORT --bind 127.0.0.1 >/dev/null 2>&1) &
SRV=$!
sleep 1
printf '# index\ntwice 1.0 http://127.0.0.1:%s/nothing_here.j|http://127.0.0.1:%s/twice.j %s\nbad 1.0 http://127.0.0.1:%s/twice.j 0000\n' $PORT $PORT "$H" $PORT > "$W/index.txt"
cd "$W/out" || exit 1
t "version" '[ "$($J --version)" = "jget 0.2.0" ]'
t "download: the name of the file is the last part of the address" '$J -q http://127.0.0.1:$PORT/big.bin && cmp -s big.bin ../www/big.bin'
t "download: -o names the file" '$J -q http://127.0.0.1:$PORT/page.txt -o mine.txt && [ "$(cat mine.txt)" = "hello jget" ]'
t "download: -o - writes to the screen" '[ "$($J http://127.0.0.1:$PORT/page.txt -o - 2>/dev/null)" = "hello jget" ]'
t "download: -h URL is the same" '$J -q -h http://127.0.0.1:$PORT/page.txt -o h.txt && [ "$(cat h.txt)" = "hello jget" ]'
t "download: no .part file is left" '[ -z "$(ls | grep part)" ]'
t "download: an error status fails and leaves no file" '! $J -q http://127.0.0.1:$PORT/missing.bin 2>/dev/null && [ ! -e missing.bin ]'
t "download: file:// goes to curl" '$J -q file://$W/www/page.txt -o f.txt && [ "$(cat f.txt)" = "hello jget" ]'
t "download: a bad address" '! $J -q nosuch://x/y 2>/dev/null; true'
export JGET_INDEX="http://127.0.0.1:1/none http://127.0.0.1:$PORT/../index.txt file://$W/index.txt" JGET_LIB="$W/lib"
t "libraries: list (the first index is down, the mirror is used)" '$J -li list 2>/dev/null | grep -q "twice 1.0"'
t "libraries: install (the first address of the file is 404, the mirror works)" '$J -q -li install twice >/dev/null 2>&1 && cmp -s "$W/lib/twice.j" "$W/www/twice.j"'
t "libraries: list marks the installed one" '$J -li list 2>/dev/null | grep -q "^\* twice"'
t "libraries: a wrong checksum installs nothing" '! $J -q -li install bad >/dev/null 2>&1 && [ ! -f "$W/lib/bad.j" ]'
t "libraries: a bad name" '! $J -li install ../x >/dev/null 2>&1'
t "libraries: the standard ones need no install" '$J -li install cpu 2>&1 | grep -q "standard library" && [ ! -f "$W/lib/cpu.j" ]'
t "libraries: installed lists the folder" '$J -li installed | grep -q twice'
printf '#import <twice>\nvoid main(){ cout << twice(21) << nl; }\n' > "$W/use.jk"
t "libraries: the installed library can be imported" 'J2K_PATH="$W/lib" $JCMP "$W/use.jk" -o "$W/use" >/dev/null 2>&1 && [ "$($W/use)" = "42" ]'
t "libraries: uninstall" '$J -li uninstall twice >/dev/null 2>&1 && [ ! -f "$W/lib/twice.j" ]'
unset JGET_INDEX JGET_LIB
kill $SRV 2>/dev/null
cd / ; rm -rf "$W"
echo "jget: $FAILS failures"
exit $FAILS
