#!/bin/sh
# the small commands of Jaric: each result is compared with the expected text
set -eu
cd "$(dirname "$0")"; ROOT_DIR="$PWD"; sh build.sh >/dev/null
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
# rm -r: a folder with everything in it; a symbolic link is removed, not followed; / . .. refused; a folder without -r refused
mkdir -p "$T/rr/a/b" "$T/rr/real/keep"; echo x > "$T/rr/a/b/f"; ln -s "$T/rr/real" "$T/rr/a/lnk"
( cd "$T/rr" && "$J" rm a 2>/dev/null && { echo "jbox test: rm of a folder without -r must fail"; exit 1; } || true )
( cd "$T/rr" && "$J" rm -rf a )
[ ! -e "$T/rr/a" ] && [ -d "$T/rr/real/keep" ] || { echo "jbox test: rm -r (the link must not be followed)"; exit 1; }
"$J" rm -r / >/dev/null 2>&1 && { echo "jbox test: rm -r / must be refused"; exit 1; } || true
( cd "$T/rr" && "$J" rm -r . >/dev/null 2>&1 && { echo "jbox test: rm -r . must be refused"; exit 1; } || true )
"$J" rm -rf "$T/rr/nothing" || { echo "jbox test: rm -rf of nothing must succeed"; exit 1; }
# the commands of the system are changed by root only (JC_ROOT=1)
mkdir -p "$T/app/home" "$T/app/usr/bin"; echo x > "$T/app/usr/bin/tool"
( export PREFIX="$T/app/usr" HOME="$T/app/home"; unset JC_ROOT
  "$J" rm "$T/app/usr/bin/tool" 2>/dev/null && { echo "jbox test: rm in usr/bin must need root"; exit 1; }
  "$J" mv "$T/app/usr/bin/tool" "$T/app/home/t" 2>/dev/null && { echo "jbox test: mv out of usr/bin must need root"; exit 1; }
  "$J" cp "$T/app/home/../usr/bin/tool" "$T/app/usr/bin/tool2" 2>/dev/null && { echo "jbox test: cp into usr/bin must need root"; exit 1; }
  [ -f "$T/app/usr/bin/tool" ] || { echo "jbox test: the file must be there"; exit 1; }
  export JC_ROOT=1; "$J" cp "$T/app/usr/bin/tool" "$T/app/usr/bin/tool2" && "$J" rm "$T/app/usr/bin/tool2" || { echo "jbox test: root may change usr/bin"; exit 1; }
  unset JC_ROOT; echo y > "$T/app/home/f"; "$J" rm "$T/app/home/f" || { echo "jbox test: home is free"; exit 1; }
)
# df, ps, hex
"$J" df | grep -q "FOLDER" || { echo "jbox test: df"; exit 1; }
"$J" df -h / | grep -q "/$" || { echo "jbox test: df of a folder"; exit 1; }
"$J" ps | grep -q "PID" || { echo "jbox test: ps"; exit 1; }
"$J" ps | grep -q "jbox" || { echo "jbox test: ps lists itself"; exit 1; }
printf 'ABC\n' > "$T/x.txt"
check "$("$J" hex "$T/x.txt")" "00000000: 4142 430a                                ABC." hex
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
check "$(printf 'abc\n' | "$J" rev)" "cba" rev
check "$(printf 'abc' | "$J" sha256sum | cut -d ' ' -f 1)" "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" sha256sum
check "$(printf 'Man' | "$J" base64)" "TWFu" base64
check "$(printf 'TWFu\n' | "$J" base64 -d)" "Man" base64-d
printf 'a\nb\n' > pa.txt; printf '1\n2\n' > pb.txt
check "$("$J" paste pa.txt pb.txt | tr '\t' ,)" "a,1
b,2" paste
check "$(echo abcdefgh | "$J" fold -w 3 | tr '\n' ,)" "abc,def,gh," fold
check "$("$J" printf '%s=%d %x\n' a 5 255)" "a=5 ff" printf
check "$("$J" realpath /a/./b/../c)" "/a/c" realpath
check "$("$J" cmp pa.txt pb.txt | cut -c1-7)" "pa.txt " cmp
# dir: one name on a line into a pipe, sorted without regard to capitals, folders with a /, -a shows the dot names, -l the rights and the size
mkdir -p dirt/Sub dirt/.hid; : > dirt/b.txt; : > dirt/A.txt; printf 'x' > dirt/c.sh; chmod 755 dirt/c.sh
check "$("$J" dir dirt | tr '\n' ,)" "A.txt,b.txt,c.sh,Sub/," dir-sorted
check "$("$J" dir -a dirt | tr '\n' ,)" ".hid/,A.txt,b.txt,c.sh,Sub/," dir-all
check "$("$J" dir -l dirt | grep c.sh | cut -c1-10)" "-rwxr-xr-x" dir-rights
# dir in columns at a terminal (a pseudo terminal of 40 columns): more than one name on a line
cols=$(python3 - "$J" <<'PY'
import pty, os, sys, time, select, struct, fcntl, termios
j = sys.argv[1]
pid, fd = pty.fork()
if pid == 0:
    os.chdir('dirt'); os.environ['TERM'] = 'xterm'
    os.execv(j, ['jbox', 'dir'])
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 40, 0, 0))
out = b''; end = time.time() + 3
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 0.2)
    if r:
        try: d = os.read(fd, 65536)
        except OSError: break
        if not d: break
        out += d
import re
txt = re.sub(r'\x1b\[[0-9;]*m', '', out.decode(errors='ignore'))
print(len([l for l in txt.replace('\r', '').split('\n') if l.strip()]))
PY
)
check "$cols" "1" dir-columns
# cp copies a file byte for byte (also a zero byte), into a folder, and keeps the right to run
head -c 3000 /dev/urandom > cpb.bin; printf 'a\0b' > cpz.bin
"$J" cp cpb.bin cpb2.bin; "$J" cp cpz.bin dirt; "$J" cp dirt/c.sh cpx.sh
check "$(cmp cpb.bin cpb2.bin && echo same)" "same" cp-bytes
check "$(cmp cpz.bin dirt/cpz.bin && echo same)" "same" cp-zero-byte-into-folder
check "$(test -x cpx.sh && echo exec)" "exec" cp-mode
# man: a manual from the phone (a Markdown file) is shown without the marks of Markdown; the pager finds, jumps, leaves
mkdir -p "$T/home/.jaric/man"
printf '# demo tool\n\nSee [the guide](https://x.org/g) and `code` and **bold**.\n\n## Commands\n\n```\ndemo run\n```\n* one\n- two\n' > "$T/home/.jaric/man/demo.md"
OUT=$(HOME="$T/home" "$J" man demo)
echo "$OUT" | grep -q "^DEMO TOOL$" || { echo "jbox test: man: the heading"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q "See the guide and code and bold" || { echo "jbox test: man: links and marks"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q "^    demo run$" || { echo "jbox test: man: code"; exit 1; }
echo "$OUT" | grep -q "^  - one$" || { echo "jbox test: man: lists"; exit 1; }
if HOME="$T/home" "$J" man nosuchtopicxyz > /dev/null 2>&1; then echo "jbox test: man of nothing must fail"; exit 1; fi
# cp -r copies a folder with what is in it (also bytes with zero), mv moves a folder, rm -r removes it; cp without -r refuses a folder
mkdir -p tree/sub/deep && printf 'a\n' > tree/one.txt && printf 'x\0y' > tree/sub/zero.bin && printf 'z' > tree/sub/deep/z.txt
"$J" cp -r tree tree2 || { echo "jbox test: cp -r"; exit 1; }
cmp tree/sub/zero.bin tree2/sub/zero.bin && cmp tree/sub/deep/z.txt tree2/sub/deep/z.txt || { echo "jbox test: cp -r contents"; exit 1; }
if "$J" cp tree treeX > /dev/null 2>&1; then echo "jbox test: cp of a folder without -r must fail"; exit 1; fi
mkdir mvdest && "$J" mv tree2 mvdest || { echo "jbox test: mv of a folder"; exit 1; }
[ -f mvdest/tree2/sub/deep/z.txt ] && [ ! -e tree2 ] || { echo "jbox test: mv of a folder moved nothing"; exit 1; }
"$J" rm -rf mvdest tree || { echo "jbox test: rm -rf"; exit 1; }
[ ! -e mvdest ] && [ ! -e tree ] || { echo "jbox test: rm -rf left something"; exit 1; }
if "$J" cp -r mvdest/x mvdest/x/y > /dev/null 2>&1; then echo "jbox test: cp of nothing must fail"; exit 1; fi
# several sources go into a folder (cp a b dir/, mv a b dir/); -n keeps a file that is there; -v says what it does
mkdir sdest && printf '1' > s1.txt && printf '2' > s2.txt
"$J" cp s1.txt s2.txt sdest || { echo "jbox test: cp of two files into a folder"; exit 1; }
[ "$(cat sdest/s1.txt)$(cat sdest/s2.txt)" = "12" ] || { echo "jbox test: cp of two files: contents"; exit 1; }
printf 'new' > s1.txt; "$J" cp -n s1.txt sdest; [ "$(cat sdest/s1.txt)" = "1" ] || { echo "jbox test: cp -n overwrote"; exit 1; }
[ "$("$J" cp -v s2.txt sdest/s3.txt)" = "s2.txt -> sdest/s3.txt" ] || { echo "jbox test: cp -v"; exit 1; }
mkdir sdest2 && "$J" mv s1.txt s2.txt sdest2 || { echo "jbox test: mv of two files"; exit 1; }
[ -f sdest2/s1.txt ] && [ -f sdest2/s2.txt ] && [ ! -e s1.txt ] || { echo "jbox test: mv of two files: result"; exit 1; }
if "$J" mv sdest2/s1.txt sdest2/s2.txt nofolder > /dev/null 2>&1; then echo "jbox test: mv of two files into a non-folder must fail"; exit 1; fi
# jq: paths, [] , select, length, keys, -r, -c
printf '{"name":"ann","tags":["a","b"],"items":[{"n":"x","v":1},{"n":"y","v":5}],"nest":{"k":[1,{"z":"deep"}]}}' > q.json
check "$("$J" jq .name q.json)" '"ann"' jq-name
check "$("$J" jq -r .name q.json)" "ann" jq-raw
check "$("$J" jq -c .tags q.json)" '["a","b"]' jq-compact
check "$("$J" jq '.nest.k[1].z' q.json)" '"deep"' jq-path
check "$("$J" jq -r '.items[] | select(.v > 2) | .n' q.json)" "y" jq-select
check "$("$J" jq '.items | length' q.json)" "2" jq-length
check "$("$J" jq -c keys q.json)" '["name","tags","items","nest"]' jq-keys
check "$("$J" jq .nothing q.json)" "null" jq-null
check "$(cat q.json | "$J" jq -c '.items[0]')" '{"n":"x","v":1}' jq-stdin
# --install: a stale link (to another program, or to nothing) is made again; a real file stays
mkdir "$T/lnk" && cd "$T/lnk" && ln -s /bin/sh cp && ln -s nowhere sort && printf 'mine' > uniq
"$J" --install . > /dev/null || { echo "jbox test: --install failed"; exit 1; }
[ "$(readlink cp)" = "jbox" ] && [ "$(readlink sort)" = "jbox" ] || { echo "jbox test: --install did not repair a stale link"; exit 1; }
[ "$(cat uniq)" = "mine" ] || { echo "jbox test: --install overwrote a real file"; exit 1; }
cd "$ROOT_DIR"
python3 -I "$ROOT_DIR/pager_test.py" "$J" "$T" || { echo "jbox test: the pager"; exit 1; }
