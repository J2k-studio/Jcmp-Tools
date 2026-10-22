#!/bin/sh
# builds coderin and jpty, and drives the editor through a pseudo terminal with keys: typing with auto indent, select + copy + paste, find, save, quit
set -eu
cd "$(dirname "$0")"
sh build.sh >/dev/null
sh ../jpty/build.sh >/dev/null
PTY="$PWD/../jpty/_out/jpty"
ED="$PWD/_out/coderin"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"                          # a short name of the file: the status line is not cut
F=t.jk
( sleep 0.3; printf 'void main() {\r'; sleep 0.3; printf 'cout << "hi";'; sleep 0.3; printf '\023'; sleep 0.4; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'void main() {
    cout << "hi";
}' ] || { echo "coderin test: typing"; cat -A "$F"; exit 1; }
rm -f "$F"
( sleep 0.3; printf 'hello world'; sleep 0.2; printf '\033[1;2D\033[1;2D\033[1;2D\033[1;2D\033[1;2D'; sleep 0.2; printf '\003'; sleep 0.2; printf '\033[F'; sleep 0.2; printf '\026'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'hello worldworld' ] || { echo "coderin test: copy and paste"; cat -A "$F"; exit 1; }
( sleep 0.3; printf '\006'; sleep 0.2; printf 'world\r'; sleep 0.2; printf 'Z'; sleep 0.2; printf '\021'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > frames
grep -aq 'unsaved changes' frames || { echo "coderin test: the quit asks when there are changes"; exit 1; }
[ "$(cat "$F")" = 'hello worldworld' ] || { echo "coderin test: a quit without saving must not change the file"; exit 1; }
# brackets and quotes are closed, Enter between { and } opens a block
rm -f "$F"
( sleep 0.3; printf 'void main('; sleep 0.2; printf ')'; sleep 0.2; printf ' {'; sleep 0.2; printf '\r'; sleep 0.2; printf 'cout << "hi";'; sleep 0.3; printf '\023'; sleep 0.4; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'void main() {
    cout << "hi";
}' ] || { echo "coderin test: closing brackets"; cat -A "$F"; exit 1; }
# the mouse: a click puts the cursor there; a double click and copy and paste
printf 'first line\nhello world\nlast\n' > m.txt
( sleep 0.3; printf '\033[<0;10;2M\033[<0;10;2m'; sleep 0.2; printf 'Z'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" m.txt > /dev/null
[ "$(sed -n 2p m.txt)" = 'hello Zworld' ] || { echo "coderin test: a click"; cat -A m.txt; exit 1; }
( sleep 0.3; printf '\033[<0;5;1M\033[<0;5;1m'; sleep 0.1; printf '\033[<0;5;1M\033[<0;5;1m'; sleep 0.2; printf '\003'; sleep 0.2; printf '\033[<0;3;3M\033[<0;3;3m'; sleep 0.2; printf '\026'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" m.txt > /dev/null
[ "$(sed -n 3p m.txt)" = 'firstlast' ] || { echo "coderin test: a double click, copy and paste"; cat -A m.txt; exit 1; }
# settings: no pairs, a small tab
mkdir -p .config/coderin; printf 'autopair = off\ntabsize = 2\n' > .config/coderin/settings
rm -f s.txt
( sleep 0.3; printf '(\t'; sleep 0.3; printf '\023'; sleep 0.3; printf '\021' ) | HOME="$T" $PTY -w 80 -h 24 "$ED" s.txt > /dev/null
[ "$(cat s.txt)" = '(  ' ] || { echo "coderin test: settings"; cat -A s.txt; exit 1; }
echo "coderin test: ok"
