#!/bin/sh
# jnote: add, list, show, todo + check, append, find, rm, and the errors
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jnote"
[ "$($J --version)" = "jnote $(cat VERSION)" ] || { echo "jnote test: --version differs from VERSION"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export JNOTE_DIR="$T/notes"
ok=0; bad=0
rc() { r=0; "$@" >/dev/null 2>&1 || r=$?; echo $r; }
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); echo "PASS  $1"; else bad=$((bad+1)); echo "FAIL  $1"; fi; }
$J list | grep -q "no notes yet"; check "empty list" $?
[ "$($J add 'Shopping\nmilk')" = "note 1" ]; check "add gives the number" $?
[ -f "$JNOTE_DIR/note-0001.txt" ]; check "the note is a plain file" $?
[ "$(head -1 "$JNOTE_DIR/note-0001.txt")" = "Shopping" ]; check "the first line is the title" $?
[ "$($J todo 'To do' write test)" = "note 2" ]; check "todo" $?
$J show 2 | grep -q '^\[ \] write$'; check "show prints the items" $?
[ "$($J check 2 2)" = "[x] test" ]; check "check toggles item 2" $?
$J show 2 | grep -q '^\[x\] test$'; check "the change is in the file" $?
[ "$($J check 2 2)" = "[ ] test" ]; check "check toggles back" $?
$J append 1 eggs; $J show 1 | grep -q '^eggs$'; check "append" $?
$J find EGGS | grep -q Shopping; check "find ignores case" $?
[ "$(rc $J find nothing_here_xyz)" = 1 ]; check "find: no hit gives 1" $?
[ "$(rc $J show 9)" = 1 ]; check "show: a missing note gives 1" $?
[ "$(rc $J show abc)" = 2 ]; check "show: not a number gives 2" $?
[ "$(rc $J check 2 7)" = 1 ]; check "check: a missing item gives 1" $?
$J rm 1 >/dev/null; [ ! -f "$JNOTE_DIR/note-0001.txt" ]; check "rm" $?
[ "$($J add again)" = "note 3" ]; check "numbers never go back" $?
[ "$($J path)" = "$JNOTE_DIR" ]; check "path" $?
[ "$(rc $J nonsense)" = 2 ]; check "unknown command gives 2" $?
echo "passed $ok, failed $bad"; [ $bad = 0 ]
