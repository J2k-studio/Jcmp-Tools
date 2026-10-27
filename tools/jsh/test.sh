#!/bin/sh
# the shell reads commands from a pipe (no terminal) and its output is compared with the expected text
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null; ROOT=$(pwd)
[ "$(./_out/jsh --version)" = "jsh $(cat VERSION)" ] || { echo "jsh test: --version differs from VERSION"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
SH="$OLDPWD/_out/jsh"
OUT=$(printf 'echo hello world\necho "a  b" | cat\necho one > f.txt\necho two >> f.txt\ncat < f.txt\nfalse\necho status $?\necho x | tr x y | cat\nnosuchprog\ncd /\npwd\nexit 7\n' | "$SH" 2>&1) && rc=0 || rc=$?
WANT='jsh 0.1 (the shell of Jaric): help shows the commands
hello world
a  b
one
two
status 1
y
jsh: nosuchprog: command not found
r:/'
[ "$OUT" = "$WANT" ] || { echo "shell test: the output differs"; echo "$OUT"; exit 1; }
[ "$rc" = 7 ] || { echo "shell test: exit code $rc, wanted 7"; exit 1; }
echo "shell test: ok"
# step 5: variables, aliases, ; && ||, globs, scripts, -c
T2=$(mktemp -d); trap 'rm -rf "$T" "$T2"' EXIT
cd "$T2"; touch a.txt b.txt c.log
printf 'echo "echo in the script"\nexport K=5\necho k=$K\n' > s.jsh
OUT2=$(printf 'NAME=jao\necho hi $NAME\nalias say=echo\nsay aliased\necho *.txt\nfalse || echo second\ntrue && echo third\necho a ; echo b\nunset NAME\necho [$NAME]\ntype cd\nexit 0\n' | HOME="$T2" "$SH" 2>&1)
WANT2='jsh 0.1 (the shell of Jaric): help shows the commands
hi jao
aliased
a.txt b.txt
second
third
a
b
[]
cd is a jsh built-in'
[ "$OUT2" = "$WANT2" ] || { echo "shell test (step 5): the output differs"; echo "$OUT2"; exit 1; }
[ "$(HOME="$T2" "$SH" -c 'echo one; echo two')" = "one
two" ] || { echo "shell test: -c failed"; exit 1; }
[ "$(HOME="$T2" "$SH" s.jsh)" = "echo in the script
k=5" ] || { echo "shell test: script failed"; exit 1; }
echo "shell test (step 5): ok"
# step 6: if / elif / else, while, until, for, functions, $( ), test and [ ]
T3=$(mktemp -d); trap 'rm -rf "$T" "$T2" "$T3"' EXIT
cd "$T3"; touch a.txt b.txt
cp "$OLDPWD/_out/jbox" . 2>/dev/null || cp "$(dirname "$SH")/jbox" .
check6() { got=$(HOME="$T3" PATH="$T3:$PATH" "$SH" -c "$1" 2>&1); [ "$got" = "$2" ] || { echo "shell test (step 6): '$1' gave '$got', wanted '$2'"; exit 1; }; }
check6 'if [ -f zzz ]; then echo yes; elif [ 3 -gt 2 ]; then echo elif; else echo no; fi' 'elif'
check6 'if false; then echo A; else echo B; fi' 'B'
check6 'x=5; if [ $x -eq 5 ]; then echo five; fi' 'five'
check6 'for i in a b c; do echo i=$i; done' 'i=a
i=b
i=c'
check6 'for f in *.txt; do echo $f; done' 'a.txt
b.txt'
check6 'greet() { echo hi $1 and $2; }; greet jao ploy' 'hi jao and ploy'
check6 'y=$(echo captured | cat); echo got $y' 'got captured'
check6 'echo $(echo nested $(echo deep))' 'nested deep'
check6 'f() { echo in f; return 3; echo not; }; f; echo status $?' 'in f
status 3'
check6 'while false; do echo no; done; echo after' 'after'
check6 'until true; do echo no; done; echo after' 'after'
check6 'test -d . && echo dir; test -f nosuch || echo nofile' 'dir
nofile'
echo "shell test (step 6): ok"
# step 7: break, continue, $(( )), &, jobs, wait, read
check6 'i=0; while [ $i -lt 5 ]; do i=$((i+1)); if [ $i -eq 2 ]; then continue; fi; if [ $i -eq 4 ]; then break; fi; echo i=$i; done; echo end $i' 'i=1
i=3
end 4'
check6 'echo $((2+3*4)) $(((2+3)*4)) $((10/3)) $((10%3)) $((7-10)) $((3<5)) $((3>5))' '14 20 3 1 -3 1 0'
check6 'n=10; echo $((n*n))' '100'
check6 'for a in 1 2; do for b in x y; do if [ $b = y ]; then break; fi; echo $a$b; done; done' '1x
2x'
got=$(HOME="$T3" PATH="$T3:$PATH" "$SH" -c 'sleep 0 & wait; echo waited' 2>&1 | tail -n 1); [ "$got" = "waited" ] || { echo "shell test (step 7): wait"; exit 1; }
echo "shell test (step 7): ok"
# step 8: stderr redirects, here-documents, here-strings
check6 'ls /nonexistent_dir_x 2> e8.txt; cat e8.txt | wc -l' '1'
check6 'echo hi > o8.txt 2>&1; cat o8.txt' 'hi'
check6 'ls /nonexistent_dir_x &> b8.txt; cat b8.txt | wc -l' '1'
check6 'echo err 1>&2 2> /dev/null; echo done' 'err
done'
check6 'cat <<<"from a string"' 'from a string'
printf 'cat <<EOT\nline one\nline two\nEOT\necho after\n' > h8.jsh
got=$(HOME="$T3" PATH="$T3:$PATH" "$SH" h8.jsh 2>&1 | tr '\n' '|'); [ "$got" = "line one|line two|after|" ] || { echo "shell test (step 8): here-document: $got"; exit 1; }
echo "shell test (step 8): ok"
python3 "$ROOT/setting_test.py" "$SH" 2>/dev/null || { echo "shell test (step 9): jaric setting"; exit 1; }
echo "shell test (step 9): ok"
python3 "$ROOT/wrap_test.py" "$SH" >/dev/null 2>&1 || { echo "shell test (step 10): a long line and the arrows"; exit 1; }
echo "shell test (step 10): ok"
# step 11: the first line of a script ([#jsh], #jsh, #!jsh, none), the arguments $1 $# $0, a settings file of jash is not run
printf '[#jsh]\necho "a=$1 n=$# s=$0"\n' > h11a.jsh; printf '#jsh\necho hash\n' > h11b.jsh; printf '#!jsh\necho shebang\n' > h11c.jsh; printf 'echo plain\n' > h11d.jsh; printf '[#jash]\n[jsh]\ncolor = red\n' > h11e.jash
got=$(HOME="$T3" PATH="$T3:$PATH" "$SH" h11a.jsh ana bob 2>&1 | tr '\n' '|'); [ "$got" = "a=ana n=2 s=h11a.jsh|" ] || { echo "shell test (step 11): [#jsh] and arguments: $got"; exit 1; }
for f in b:hash c:shebang d:plain; do got=$(HOME="$T3" PATH="$T3:$PATH" "$SH" h11${f%%:*}.jsh 2>&1); [ "$got" = "${f##*:}" ] || { echo "shell test (step 11): header $f: $got"; exit 1; }; done
got=$(HOME="$T3" PATH="$T3:$PATH" "$SH" h11e.jash 2>&1 || true); case "$got" in *"settings file of jash"*) ;; *) echo "shell test (step 11): a jash file must not run: $got"; exit 1 ;; esac
echo "shell test (step 11): ok"
# step 12: with xr_learn = on in config.local every typed command is written to ~/.neuron/events.txt (a line with "password" is not); off: nothing
T12=$(mktemp -d); mkdir -p "$T12/usr/etc"; printf 'xr_learn = on\n' > "$T12/usr/etc/config.local"
HOME="$T12" PREFIX="$T12/usr" SH="$SH" python3 - <<'PY' || { echo "shell test (step 12): the pty"; exit 1; }
import pty, os, time, select
pid, fd = pty.fork()
if pid == 0:
    os.environ['TERM'] = 'xterm'
    os.execv(os.environ['SH'], ['jsh'])
def rd(t):
    end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: os.read(fd, 65536)
            except OSError: break
rd(1.0)
for c in [b'gti status\r', b'echo hello\r', b'echo my password is x\r', b'exit\r']:
    os.write(fd, c); rd(0.6)
PY
[ "$(grep -c "" "$T12/.neuron/events.txt")" = 3 ] && grep -q "gti status.127.command not found" "$T12/.neuron/events.txt" && ! grep -q password "$T12/.neuron/events.txt" || { echo "shell test (step 12): events"; cat "$T12/.neuron/events.txt"; exit 1; }
echo "shell test (step 12): ok"
# step 13: the drives (the owner's design): f:/ is home, :/ is home too, 0:/ the phone storage, r:/ the root; "drive new" makes more; a URL or an unknown name is left alone
T13=$(mktemp -d); mkdir -p "$T13/files/home/jaric" "$T13/ext"
cat > "$T13/d.jsh" <<EOT
echo :/ :/x f:/jaric f: f:/ http://a:/b zz:/q a:b
drive new ext $T13/ext
echo ext:/z
drive remove ext
echo ext:/z
EOT
got=$(HOME="$T13/files/home" PREFIX="$T13/usr" "$SH" "$T13/d.jsh" 2>&1 | tr '\n' '|')
H="$T13/files/home"
[ "$got" = "$H $H/x $H/jaric $H $H http://a:/b zz:/q a:b|ext:/ is $T13/ext|$T13/ext/z|removed the drive ext|ext:/z|" ] || { echo "shell test (step 13): drives: $got"; exit 1; }
# the prompt says the drive and the folder: f:/ at home, f:/jaric inside, r:/... outside the drives
HOME="$H" PREFIX="$T13/usr" T13="$T13" SH="$SH" python3 - <<'PY' || { echo "shell test (step 13): the prompt"; exit 1; }
import pty, os, time, select, re, sys
home = os.environ['HOME']
pid, fd = pty.fork()
if pid == 0:
    os.environ['TERM'] = 'xterm'
    os.chdir(home)
    os.execv(os.environ['SH'], ['jsh'])
def rd(t):
    out = b''; end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: out += os.read(fd, 65536)
            except OSError: break
    return out.decode(errors='ignore')
rd(1.0); got = []
for c in [b'\r', b'cd jaric\r', b'cd :/\r', ('cd ' + os.environ['T13'] + '\r').encode(), b'exit\r']:
    os.write(fd, c); o = rd(0.6)
    t = re.sub(r'\x1b\[[0-9;]*[A-Za-z]|\x1b\][^\x07]*\x07', '', o)
    m = re.findall(r'jc (\S+)>', t)
    got.append(m[-1] if m else '?')
if got[:3] != ['f:/', 'f:/jaric', 'f:/'] or not got[3].startswith('r:/'):
    print(got); sys.exit(1)
PY
printf 'pwd\ncd f:/jaric\npwd\npwd -P\ncd :/\npwd\n' > "$T13/p.jsh"
got=$(HOME="$H" PREFIX="$T13/usr" "$SH" "$T13/p.jsh" 2>&1 | tr '\n' '|')
case "$got" in *"f:/jaric|$H/jaric|f:/|") ;; *) echo "shell test (step 13): pwd: $got"; exit 1 ;; esac
echo "shell test (step 13): ok"
# step 14: HOME given as a link (on Android /data/data is a link of /data/user/0 and getcwd gives the real form): the prompt still says f:/
T14=$(mktemp -d); mkdir -p "$T14/real/files/home/jaric"; ln -s "$T14/real" "$T14/alias"
HOME="$T14/alias/files/home" PREFIX="$T14/usr" SH="$SH" python3 - <<'PY' || { echo "shell test (step 14): HOME as a link"; exit 1; }
import pty, os, time, select, re, sys
home = os.environ['HOME']
pid, fd = pty.fork()
if pid == 0:
    os.environ['TERM'] = 'xterm'
    os.chdir(home)
    os.execv(os.environ['SH'], ['jsh'])
def rd(t):
    out = b''; end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: out += os.read(fd, 65536)
            except OSError: break
    return out.decode(errors='ignore')
rd(1.0); got = []
for c in [b'\r', b'cd jaric\r', b'exit\r']:
    os.write(fd, c); o = rd(0.6)
    t = re.sub(r'\x1b\[[0-9;]*[A-Za-z]|\x1b\][^\x07]*\x07', '', o)
    m = re.findall(r'jc (\S+)>', t); got.append(m[-1] if m else '?')
if got[:2] != ['f:/', 'f:/jaric']:
    print(got); sys.exit(1)
PY
echo "shell test (step 14): ok"
# step 15: pwd options: -p the real path, -d the drive, -help; an unknown option is an error
T15=$(mktemp -d); mkdir -p "$T15/files/home/jaric"
printf 'cd jaric\npwd\npwd -p\npwd -d\npwd -help\npwd -x\necho rc=$?\n' > "$T15/p.jsh"
got=$(cd "$T15/files/home" && HOME="$T15/files/home" PREFIX="$T15/usr" "$SH" "$T15/p.jsh" 2>"$T15/err.txt" | tr '\n' '|')
case "$got" in *"f:/jaric|"*"/files/home/jaric|f|pwd "*"where you are"*"rc=2|"*) ;; *) echo "shell test (step 15): pwd options: $got"; exit 1 ;; esac
grep -q "pwd: unknown option -x" "$T15/err.txt" || { echo "shell test (step 15): the error of an unknown option"; exit 1; }
echo "shell test (step 15): ok"

