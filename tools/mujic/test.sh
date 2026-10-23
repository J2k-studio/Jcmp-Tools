#!/bin/sh
# mujic: the lists and the lyrics file, and the player screen driven through a pseudo terminal (the Jaric audio messages)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
M="$PWD/_out/mujic"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export MUJIC_DIR="$T/m"; mkdir -p "$MUJIC_DIR"
[ "$("$M" --version)" = "mujic 0.2.0" ] || { echo "mujic test: version"; exit 1; }
"$M" list | grep -q "no songs" || { echo "mujic test: an empty folder"; exit 1; }
"$M" catalog | grep -q "sneaky-snitch" || { echo "mujic test: catalog"; exit 1; }
printf 'ID3' > "$MUJIC_DIR/Song One.mp3"; printf 'ID3' > "$MUJIC_DIR/Song Two.mp3"
printf '[ar:Someone]\n[00:10.00]first line\n[00:20.50]We are no strangers\n[00:30.00][00:40.00]twice\n' > "$MUJIC_DIR/Song Two.lrc"
"$M" list | grep -q "2. Song Two  \[lyrics, synced\]" || { echo "mujic test: list shows lyrics"; exit 1; }
python3 ui_test.py "$M" "$MUJIC_DIR" || { echo "mujic test: the player screen"; exit 1; }
echo "mujic tests: ok"
