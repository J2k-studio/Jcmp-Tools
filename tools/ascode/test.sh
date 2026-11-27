#!/bin/sh
# ascode with a scripted model: the tools, the modes ask / read / auto, the edit that must be unique, help lines of at most 38 characters
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/ascode --version)" = "ascode $(cat VERSION)" ] || { echo "ascode test: --version differs from VERSION"; exit 1; }
long=$(./_out/ascode --help | awk 'length($0) > 38' | wc -l)
[ "$long" = 0 ] || { echo "ascode test: a line of --help is longer than 38 characters"; exit 1; }
A="$PWD/_out/ascode"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
cat > s.txt <<'S'
tool write a.txt | one two\nthree two\n
tool edit a.txt | two | 2
tool edit a.txt | one | 1
tool run echo hi
done
S
# auto: the changes inside the folder are done; "two" is in the file twice, so that edit is refused as a guess
"$A" --model mock:s.txt --mode auto go > out.txt 2>&1 </dev/null
[ "$(cat a.txt)" = "$(printf '1 two\nthree two')" ] || { echo "ascode test: auto changed the file wrongly: $(cat a.txt)"; exit 1; }
grep -q "2 times" out.txt || { echo "ascode test: a second place must be refused"; exit 1; }
grep -q "^hi" out.txt || { echo "ascode test: run gave no output"; exit 1; }
# read: nothing is changed
rm a.txt
"$A" --model mock:s.txt --mode read go > out2.txt 2>&1 </dev/null
[ ! -f a.txt ] || { echo "ascode test: read mode wrote a file"; exit 1; }
grep -q "refused (mode read)" out2.txt || { echo "ascode test: no refusal in read mode"; exit 1; }
# ask: the person says y to the write and n to the next change
printf 'y\nn\nn\nn\n' | "$A" --model mock:s.txt --mode ask go > out3.txt 2>&1
[ -f a.txt ] || { echo "ascode test: ask y did not write"; exit 1; }
[ "$(cat a.txt)" = "$(printf 'one two\nthree two')" ] || { echo "ascode test: ask n changed the file: $(cat a.txt)"; exit 1; }
"$A" --mode auto >/dev/null 2>&1 && { echo "ascode test: no model must fail"; exit 1; }
echo "ascode test: ok"
