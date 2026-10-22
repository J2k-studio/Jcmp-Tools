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
( sleep 0.3; printf 'void main() {\r'; sleep 0.3; printf 'cout << "hi";\r'; sleep 0.3; printf '}'; sleep 0.3; printf '\023'; sleep 0.4; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'void main() {
    cout << "hi";
}' ] || { echo "coderin test: typing"; cat -A "$F"; exit 1; }
rm -f "$F"
( sleep 0.3; printf 'hello world'; sleep 0.2; printf '\033[1;2D\033[1;2D\033[1;2D\033[1;2D\033[1;2D'; sleep 0.2; printf '\003'; sleep 0.2; printf '\033[F'; sleep 0.2; printf '\026'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'hello worldworld' ] || { echo "coderin test: copy and paste"; cat -A "$F"; exit 1; }
( sleep 0.3; printf '\006'; sleep 0.2; printf 'world\r'; sleep 0.2; printf 'Z'; sleep 0.2; printf '\021'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > frames
grep -aq 'unsaved changes' frames || { echo "coderin test: the quit asks when there are changes"; exit 1; }
[ "$(cat "$F")" = 'hello worldworld' ] || { echo "coderin test: a quit without saving must not change the file"; exit 1; }
echo "coderin test: ok"
