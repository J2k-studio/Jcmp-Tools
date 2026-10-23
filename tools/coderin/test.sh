#!/bin/sh
# builds coderin and jpty, and drives the editor through a pseudo terminal with keys: typing with auto indent, select + copy + paste, find, save, quit
set -eu
cd "$(dirname "$0")"
sh build.sh >/dev/null
[ "$(./_out/coderin --version)" = "coderin $(cat VERSION)" ] || { echo "coderin test: --version differs from VERSION"; exit 1; }
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
# the extensions: undo and redo, a snippet of J2K, the completion of a word
rm -f u.txt r.txt s.jk w.jk
( sleep 0.3; printf 'abc'; sleep 1.2; printf '\032'; sleep 0.2; printf 'x'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" u.txt > /dev/null
[ "$(cat u.txt)" = 'x' ] || { echo "coderin test: undo"; cat -A u.txt; exit 1; }
( sleep 0.3; printf 'abc'; sleep 1.2; printf '\032'; sleep 0.2; printf '\031'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" r.txt > /dev/null
[ "$(cat r.txt)" = 'abc' ] || { echo "coderin test: redo"; cat -A r.txt; exit 1; }
( sleep 0.3; printf 'main\t'; sleep 0.3; printf 'x'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" s.jk > /dev/null
[ "$(cat s.jk)" = 'void main() {
    x
}' ] || { echo "coderin test: a snippet"; cat -A s.jk; exit 1; }
( sleep 0.3; printf 'String\r'; sleep 0.2; printf 'Str\t'; sleep 0.3; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" w.jk > /dev/null
[ "$(sed -n 2p w.jk)" = 'String' ] || { echo "coderin test: the completion of a word"; cat -A w.jk; exit 1; }
# an extension that you write: a snippet, a word, a command
mkdir -p .config/coderin/extensions/mine
printf 'hi = hello |!\n' > .config/coderin/extensions/mine/snippets
printf 'zebrafish\n' > .config/coderin/extensions/mine/words
printf 'mark = echo marked > %%f.mark\n' > .config/coderin/extensions/mine/commands
rm -f e.txt e.txt.mark
( sleep 0.3; printf 'hi\t'; sleep 0.3; printf 'Z'; sleep 0.2; printf '\r'; sleep 0.2; printf 'zeb\t'; sleep 0.3; printf '\023'; sleep 0.3; printf '\005'; sleep 0.2; printf 'run mark\r'; sleep 0.5; printf '\021' ) | HOME="$T" $PTY -w 80 -h 24 "$ED" e.txt > /dev/null
[ "$(cat e.txt)" = 'hello Z
zebrafish!' ] || { echo "coderin test: extension snippet and word"; cat -A e.txt; exit 1; }
[ "$(cat e.txt.mark 2>/dev/null)" = 'marked' ] || { echo "coderin test: extension command"; exit 1; }
# the errors of the compiler: saving a .jk file with a mistake shows the error and marks the line
rm -f bad.jk
( sleep 0.3; printf 'void main() { int a = ; }'; sleep 0.3; printf '\023'; sleep 1.5; printf '\021'; sleep 0.3; printf '\021' ) | PATH="$(dirname "${JCMP:-$(command -v jcmp)}"):$PATH" $PTY -w 80 -h 24 "$ED" bad.jk > frames
grep -aq 'error 1/' frames || { echo "coderin test: the errors of the compiler"; exit 1; }
# the list of words under the cursor: typing whi shows it, Enter takes the word
rm -f p.jk
( sleep 0.3; printf 'whi'; sleep 0.3; printf '\r'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" p.jk > /dev/null
[ "$(cat p.jk)" = 'while' ] || { echo "coderin test: the list of words"; cat -A p.jk; exit 1; }
echo "coderin test: ok"
