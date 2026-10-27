#!/bin/sh
# drive: list, new (with and without a folder), info, remove (-d), the names that are refused
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/drive"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME" "$T/music"
[ "$("$J" --version)" = "drive 0.1.0" ] || { echo "drive test: version"; exit 1; }
"$J" | grep -q "^f:/  $HOME" || { echo "drive test: list shows f"; exit 1; }
"$J" new songs "$T/music" | grep -q "songs:/ is $T/music" || { echo "drive test: new with a folder"; exit 1; }
"$J" new work >/dev/null; [ -d "$HOME/drives/work" ] || { echo "drive test: new makes a folder"; exit 1; }
"$J" | grep -q "^work:/  $HOME/drives/work" || { echo "drive test: list shows work"; exit 1; }
"$J" work | grep -q "0 entries" || { echo "drive test: info"; exit 1; }
"$J" new work >/dev/null 2>&1 && { echo "drive test: a second work must be refused"; exit 1; }
"$J" new f >/dev/null 2>&1 && { echo "drive test: f must be refused"; exit 1; }
"$J" new "bad name" >/dev/null 2>&1 && { echo "drive test: a bad name"; exit 1; }
"$J" new x relative >/dev/null 2>&1 && { echo "drive test: a relative path"; exit 1; }
"$J" new y "$T/nothing" >/dev/null 2>&1 && { echo "drive test: a missing folder"; exit 1; }
"$J" remove songs -d >/dev/null 2>&1 && { echo "drive test: -d must not delete a folder that drive did not make"; exit 1; }
"$J" remove songs >/dev/null; [ -d "$T/music" ] || { echo "drive test: remove keeps the folder"; exit 1; }
"$J" remove work -d >/dev/null; [ ! -e "$HOME/drives/work" ] || { echo "drive test: remove -d"; exit 1; }
"$J" | grep -q "songs\|work" && { echo "drive test: the list must be empty of made drives"; exit 1; }
echo "drive tests: ok"
