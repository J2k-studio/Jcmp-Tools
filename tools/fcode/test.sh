#!/bin/sh
# builds fcode and jpty, and drives the editor through a pseudo terminal with keys: typing with auto indent, select + copy + paste, find, save, quit
set -eu
cd "$(dirname "$0")"
HERE=$PWD
sh build.sh >/dev/null
[ "$(./_out/fcode --version)" = "fcode $(cat VERSION)" ] || { echo "fcode test: --version differs from VERSION"; exit 1; }
sh ../jpty/build.sh >/dev/null
PTY="$PWD/../jpty/_out/jpty"
ED="$PWD/_out/fcode"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"                          # a short name of the file: the status line is not cut
F=t.jk
( sleep 0.3; printf 'void main() {\r'; sleep 0.3; printf 'jout << "hi";'; sleep 0.3; printf '\023'; sleep 0.4; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'void main() {
    jout << "hi";
}' ] || { echo "fcode test: typing"; cat -A "$F"; exit 1; }
rm -f "$F"
( sleep 0.3; printf 'hello world'; sleep 0.2; printf '\033[1;2D\033[1;2D\033[1;2D\033[1;2D\033[1;2D'; sleep 0.2; printf '\003'; sleep 0.2; printf '\033[F'; sleep 0.2; printf '\026'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'hello worldworld' ] || { echo "fcode test: copy and paste"; cat -A "$F"; exit 1; }
( sleep 0.3; printf '\006'; sleep 0.2; printf 'world\r'; sleep 0.2; printf 'Z'; sleep 0.2; printf '\021'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > frames
grep -aq 'unsaved changes' frames || { echo "fcode test: the quit asks when there are changes"; exit 1; }
[ "$(cat "$F")" = 'hello worldworld' ] || { echo "fcode test: a quit without saving must not change the file"; exit 1; }
# brackets and quotes are closed, Enter between { and } opens a block
rm -f "$F"
( sleep 0.3; printf 'void main('; sleep 0.2; printf ')'; sleep 0.2; printf ' {'; sleep 0.2; printf '\r'; sleep 0.2; printf 'jout << "hi";'; sleep 0.3; printf '\023'; sleep 0.4; printf '\021' ) | $PTY -w 80 -h 24 "$ED" "$F" > /dev/null
[ "$(cat "$F")" = 'void main() {
    jout << "hi";
}' ] || { echo "fcode test: closing brackets"; cat -A "$F"; exit 1; }
# a narrow screen (a phone, 40 columns): the keys line and the status line must fit the width, or they wrap and scroll the text off the screen
rm -f "$F"
( sleep 0.3; printf 'hello'; sleep 0.3; printf '\021'; sleep 0.3; printf '\021' ) | $PTY -w 40 -h 30 "$ED" "$F" > narrow
python3 - narrow <<'PY' || { echo "fcode test: a narrow screen"; exit 1; }
import re, sys
b = open(sys.argv[1], 'rb').read().decode('utf8', 'replace')
parts = re.split(r'(\x1b\[\d+;\d+H)', b)
bad = []
for i in range(1, len(parts) - 1, 2):
    text = re.sub(r'\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07', '', parts[i + 1]).replace('\r', '').replace('\n', '')
    if len(text) > 40: bad.append((parts[i][2:-1], len(text)))
if bad: print('text longer than the screen at (row;col, length):', sorted(set(bad))[:6]); sys.exit(1)
PY
# the mouse: a click puts the cursor there; a double click and copy and paste
printf 'first line\nhello world\nlast\n' > m.txt
( sleep 0.3; printf '\033[<0;10;2M\033[<0;10;2m'; sleep 0.2; printf 'Z'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" m.txt > /dev/null
[ "$(sed -n 2p m.txt)" = 'hello Zworld' ] || { echo "fcode test: a click"; cat -A m.txt; exit 1; }
( sleep 0.3; printf '\033[<0;5;1M\033[<0;5;1m'; sleep 0.1; printf '\033[<0;5;1M\033[<0;5;1m'; sleep 0.2; printf '\003'; sleep 0.2; printf '\033[<0;3;3M\033[<0;3;3m'; sleep 0.2; printf '\026'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" m.txt > /dev/null
[ "$(sed -n 3p m.txt)" = 'firstlast' ] || { echo "fcode test: a double click, copy and paste"; cat -A m.txt; exit 1; }
# settings: no pairs, a small tab
mkdir -p .config/fcode; printf 'autopair = off\ntabsize = 2\n' > .config/fcode/settings
rm -f s.txt
( sleep 0.3; printf '(\t'; sleep 0.3; printf '\023'; sleep 0.3; printf '\021' ) | HOME="$T" $PTY -w 80 -h 24 "$ED" s.txt > /dev/null
[ "$(cat s.txt)" = '(  ' ] || { echo "fcode test: settings"; cat -A s.txt; exit 1; }
# the extensions: undo and redo, a snippet of J2K, the completion of a word
rm -f u.txt r.txt s.jk w.jk
( sleep 0.3; printf 'abc'; sleep 1.2; printf '\032'; sleep 0.2; printf 'x'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" u.txt > /dev/null
[ "$(cat u.txt)" = 'x' ] || { echo "fcode test: undo"; cat -A u.txt; exit 1; }
( sleep 0.3; printf 'abc'; sleep 1.2; printf '\032'; sleep 0.2; printf '\031'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" r.txt > /dev/null
[ "$(cat r.txt)" = 'abc' ] || { echo "fcode test: redo"; cat -A r.txt; exit 1; }
( sleep 0.3; printf 'main\t'; sleep 0.3; printf 'x'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" s.jk > /dev/null
[ "$(cat s.jk)" = 'void main() {
    x
}' ] || { echo "fcode test: a snippet"; cat -A s.jk; exit 1; }
( sleep 0.3; printf 'String\r'; sleep 0.2; printf 'Str\t'; sleep 0.3; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" w.jk > /dev/null
[ "$(sed -n 2p w.jk)" = 'String' ] || { echo "fcode test: the completion of a word"; cat -A w.jk; exit 1; }
# an extension that you write: a snippet, a word, a command
mkdir -p .config/fcode/extensions/mine
printf 'hi = hello |!\n' > .config/fcode/extensions/mine/snippets
printf 'zebrafish\n' > .config/fcode/extensions/mine/words
printf 'mark = echo marked > %%f.mark\n' > .config/fcode/extensions/mine/commands
rm -f e.txt e.txt.mark
( sleep 0.3; printf 'hi\t'; sleep 0.3; printf 'Z'; sleep 0.2; printf '\r'; sleep 0.2; printf 'zeb\t'; sleep 0.3; printf '\023'; sleep 0.3; printf '\005'; sleep 0.2; printf 'run mark\r'; sleep 0.5; printf '\021' ) | HOME="$T" $PTY -w 80 -h 24 "$ED" e.txt > /dev/null
[ "$(cat e.txt)" = 'hello Z
zebrafish!' ] || { echo "fcode test: extension snippet and word"; cat -A e.txt; exit 1; }
[ "$(cat e.txt.mark 2>/dev/null)" = 'marked' ] || { echo "fcode test: extension command"; exit 1; }
# the errors of the compiler: saving a .jk file with a mistake shows the error and marks the line
rm -f bad.jk
( sleep 0.3; printf 'void main() { int a = ; }'; sleep 0.3; printf '\023'; sleep 1.5; printf '\021'; sleep 0.3; printf '\021' ) | PATH="$(dirname "${JCMP:-$(command -v jcmp)}"):$PATH" $PTY -w 80 -h 24 "$ED" bad.jk > frames
grep -aq 'error 1/' frames || { echo "fcode test: the errors of the compiler"; exit 1; }
# the list of words under the cursor: typing whi shows it, Enter takes the word
rm -f p.jk
( sleep 0.3; printf 'whi'; sleep 0.3; printf '\r'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 80 -h 24 "$ED" p.jk > /dev/null
[ "$(cat p.jk)" = 'while' ] || { echo "fcode test: the list of words"; cat -A p.jk; exit 1; }
# the menu bar and the keys F9 / F11 (scheme devcpp): compile, run, errors; the examples compile
JC="$(command -v "${JCMP:-jcmp}")"
BT=$(mktemp -d)
PATH="$(dirname "$JC"):$PATH" python3 "$HERE/build_test.py" "$ED" "$BT" > /dev/null || { echo "fcode test: the menu / compile / run"; rm -rf "$BT"; exit 1; }
# every example of the menu compiles and runs
for n in 1 2 3 5; do
    "$ED" --example $n > "$BT/ex$n.jk"
    "${JCMP:-jcmp}" "$BT/ex$n.jk" -o "$BT/ex$n" > "$BT/ex$n.log" 2>&1 || { echo "fcode test: the example $n does not compile"; cat "$BT/ex$n.log"; rm -rf "$BT"; exit 1; }
    "$BT/ex$n" > /dev/null || { echo "fcode test: the example $n does not run"; rm -rf "$BT"; exit 1; }
done
"$ED" --example 4 > "$BT/ex4.jk"
"${JCMP:-jcmp}" "$BT/ex4.jk" -o "$BT/ex4" > "$BT/ex4.log" 2>&1 || { echo "fcode test: the example 4 does not compile"; cat "$BT/ex4.log"; rm -rf "$BT"; exit 1; }
rm -rf "$BT"
# the settings of the old name are still read when there are none of the new name
mkdir -p old/.config/coderin; printf 'autopair = off\n' > old/.config/coderin/settings
( cd old && ( sleep 0.3; printf '('; sleep 0.2; printf '\023'; sleep 0.4; printf '\021' ) | HOME="$PWD" $PTY -w 80 -h 24 "$ED" o.txt > /dev/null )
[ "$(cat old/o.txt)" = '(' ] || { echo "fcode test: the settings of coderin"; cat -A old/o.txt; exit 1; }
# several files: Alt+Right goes to the next one; each keeps its text, cursor and undo; a quit asks when a file that is not shown has changes
mkdir -p many && cd many && printf '1\n' > a.txt && printf '2\n' > b.txt
( sleep 0.3; printf '\033[F'; sleep 0.1; printf 'x'; sleep 0.2; printf '\033[1;3C'; sleep 0.2; printf '\033[F'; sleep 0.1; printf 'y'; sleep 0.2; printf '\023'; sleep 0.3
  printf '\033[1;3C'; sleep 0.2; printf 'z'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 40 -h 30 "$ED" a.txt b.txt > /dev/null
[ "$(cat a.txt)" = '1xz' ] && [ "$(cat b.txt)" = '2y' ] || { echo "fcode test: two files: a=$(cat a.txt) b=$(cat b.txt)"; exit 1; }
printf '1\n' > a.txt && printf '2\n' > b.txt
( sleep 0.3; printf 'q'; sleep 0.2; printf '\033[1;3C'; sleep 0.2; printf 'w'; sleep 0.2; printf '\032'; sleep 0.2; printf '\023'; sleep 0.3; printf '\033[1;3D'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 40 -h 30 "$ED" a.txt b.txt > /dev/null
[ "$(cat a.txt)" = 'q1' ] && [ "$(cat b.txt)" = '2' ] || { echo "fcode test: undo belongs to its file: a=$(cat a.txt) b=$(cat b.txt)"; exit 1; }
printf '1\n' > a.txt && printf '2\n' > b.txt
( sleep 0.3; printf 'k'; sleep 0.2; printf '\033[1;3C'; sleep 0.2; printf '\021'; sleep 0.5; printf '\033[1;3C'; sleep 0.2; printf '\023'; sleep 0.3; printf '\021' ) | $PTY -w 40 -h 30 "$ED" a.txt b.txt > frames
grep -aq 'unsaved' frames || { echo "fcode test: a hidden file with changes: the quit must ask"; exit 1; }
[ "$(cat a.txt)" = 'k1' ] || { echo "fcode test: the quit lost a hidden file: $(cat a.txt)"; exit 1; }
cd ..
echo "fcode test: ok"
