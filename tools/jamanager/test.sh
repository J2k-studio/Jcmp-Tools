#!/bin/sh
# jamanager: the commands run and say the right things (a program we start is listed, then stopped)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jamanager"
[ "$("$J" --version)" = "jamanager 0.2.1" ] || { echo "jamanager test: version"; exit 1; }
"$J" ps | grep -q "PID" || { echo "jamanager test: ps header"; exit 1; }
"$J" ps | grep -q "jamanager" || { echo "jamanager test: ps does not list itself"; exit 1; }
"$J" mem | grep -q "MB used" || { echo "jamanager test: mem"; exit 1; }
"$J" drives | grep -q "FOLDER" || { echo "jamanager test: drives"; exit 1; }
"$J" cache | grep -q "KB\|not there" || { echo "jamanager test: cache"; exit 1; }
"$J" top -n 1 | grep -q "jamanager top" || { echo "jamanager test: top"; exit 1; }
sleep 30 & P=$!
"$J" ps | grep -q "^ *$P " || { kill $P; echo "jamanager test: a started program is listed"; exit 1; }
"$J" kill $P > /dev/null || { kill $P; echo "jamanager test: kill"; exit 1; }
wait $P 2>/dev/null || true
if kill -0 $P 2>/dev/null; then echo "jamanager test: the program is still there"; exit 1; fi
"$J" kill 1 2>/dev/null && { echo "jamanager test: pid 1 must be refused"; exit 1; }
# the screen: the other name (a link) shows tabs, the programs with cpu, a filter, stops a program
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
"$J" --install "$T" > /dev/null 2>&1 || true
ln -sf "$J" "$T/jmanager"
python3 -I ui_test.py "$T/jmanager" || { echo "jmanager test: the screen"; exit 1; }
echo "jamanager tests: ok"
