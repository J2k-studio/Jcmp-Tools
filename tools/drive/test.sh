#!/bin/sh
# drive: list, new (with and without a folder), info, remove (-d), the names that are refused
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/drive"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME" "$T/music"
[ "$("$J" --version)" = "drive 0.3.1" ] || { echo "drive test: version"; exit 1; }
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
# help and unknown options
"$J" -help | grep -q "drive new NAME" || { echo "drive test: -help"; exit 1; }
"$J" --help | grep -q "drive -p" || { echo "drive test: --help"; exit 1; }
"$J" -nonsense >/dev/null 2>&1 && { echo "drive test: an unknown option must fail"; exit 1; }
# paths
[ "$("$J" -p :/bin)" = "$HOME/bin" ] || { echo "drive test: -p :/bin"; exit 1; }
[ "$("$J" -part f:/a/b)" = "$HOME/a/b" ] || { echo "drive test: -part f:"; exit 1; }
[ "$("$J" -p r:/usr)" = "/usr" ] || { echo "drive test: -p r:"; exit 1; }
"$J" new pp "$T/music" >/dev/null; [ "$("$J" -p pp:/x.mp3)" = "$T/music/x.mp3" ] || { echo "drive test: -p of a made drive"; exit 1; }
[ "$("$J" -d "$T/music/x.mp3")" = "pp:/x.mp3" ] || { echo "drive test: -d"; exit 1; }
[ "$("$J" -d "$HOME/bin")" = ":/bin" ] || { echo "drive test: -d of home"; exit 1; }
"$J" remove pp >/dev/null
# sizes
"$J" new big 2G | grep -q "limit 2.0 GB" || { echo "drive test: new with a size"; exit 1; }
"$J" | grep -q "^big:/ .*limit 2.0 GB" || { echo "drive test: list shows the limit"; exit 1; }
dd if=/dev/zero of="$HOME/drives/big/f" bs=1024 count=100 2>/dev/null
"$J" size big 50K >/dev/null; "$J" big | grep -q "over the limit" || { echo "drive test: over the limit"; exit 1; }
"$J" check >/dev/null 2>&1 && { echo "drive test: check must fail when a drive is over"; exit 1; }
"$J" size big 1.5M >/dev/null; "$J" big | grep -q "used 100 KB of 1.5 MB" || { echo "drive test: used of limit"; "$J" big; exit 1; }
"$J" check >/dev/null || { echo "drive test: check ok"; exit 1; }
"$J" size big none >/dev/null; "$J" big | grep -q "no limit" || { echo "drive test: no limit"; exit 1; }
"$J" size big 12x >/dev/null 2>&1 && { echo "drive test: a bad size"; exit 1; }
"$J" remove big -d >/dev/null; [ ! -s "$HOME/.jsh_drive_sizes" ] || { echo "drive test: remove clears the limit"; exit 1; }
echo "drive tests: ok"
