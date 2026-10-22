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
