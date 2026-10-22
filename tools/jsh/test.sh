#!/bin/sh
# the shell reads commands from a pipe (no terminal) and its output is compared with the expected text
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
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
/'
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
