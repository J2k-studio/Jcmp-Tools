#!/bin/sh
# mujic: the lists and the lyrics file, and the player screen driven through a pseudo terminal (the Jaric audio messages)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
M="$PWD/_out/mujic"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export MUJIC_DIR="$T/m"; mkdir -p "$MUJIC_DIR"
[ "$("$M" --version)" = "mujic 0.6.0" ] || { echo "mujic test: version"; exit 1; }
"$M" list | grep -q "no songs" || { echo "mujic test: an empty folder"; exit 1; }
"$M" catalog | grep -q "sneaky-snitch" || { echo "mujic test: catalog"; exit 1; }
printf 'ID3' > "$MUJIC_DIR/Song One.mp3"; printf 'ID3' > "$MUJIC_DIR/Song Two.mp3"
printf '[ar:Someone]\n[00:10.00]first line\n[00:20.50]We are no strangers\n[00:30.00][00:40.00]twice\n' > "$MUJIC_DIR/Song Two.lrc"
"$M" list | grep -q "2. Song Two  \[lyrics, synced\]" || { echo "mujic test: list shows lyrics"; exit 1; }
python3 ui_test.py "$M" "$MUJIC_DIR" || { echo "mujic test: the player screen"; exit 1; }
# /scan (mujic scan): songs of at least N seconds from every place; the length from the header (wav, mp3), a guess from the size for the others (~); hidden folders are skipped
S="$T/scan"; mkdir -p "$S/a/b" "$S/.hid"
python3 - "$S" <<'PY'
import struct, sys
s = sys.argv[1]
def wav(path, secs):
    rate = 16000; data = b'\0' * (rate * secs)
    open(path, 'wb').write(b'RIFF' + struct.pack('<I', 36 + len(data)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, 1, 8000, rate, 2, 16) + b'data' + struct.pack('<I', len(data)) + data)
wav(s + '/a/short.wav', 2); wav(s + '/a/b/long.wav', 70)
frame = bytes([0xFF, 0xFB, 0x90, 0x00]) + b'\0' * 413
open(s + '/a/song128.mp3', 'wb').write(b'ID3\x03\x00\x00\x00\x00\x00\x00' + frame * 3840)
open(s + '/a/b/x.flac', 'wb').write(b'\1' * 1600000)
open(s + '/.hid/h.wav', 'wb').write(b'\0' * 30000)
PY
O60=$("$M" scan -s 60 "$S" 2>/dev/null)
echo "$O60" | grep -q " 01:10  .*long.wav" || { echo "mujic test: scan: a wav of 70 s"; echo "$O60"; exit 1; }
echo "$O60" | grep -q " 01:40  .*song128.mp3" || { echo "mujic test: scan: an mp3 of 100 s"; echo "$O60"; exit 1; }
echo "$O60" | grep -q "~01:40  .*x.flac" || { echo "mujic test: scan: a guess for flac"; echo "$O60"; exit 1; }
echo "$O60" | grep -q "short.wav" && { echo "mujic test: scan: a song of 2 s is not 60 s"; exit 1; }
echo "$O60" | grep -q "h.wav" && { echo "mujic test: scan: a hidden folder must be skipped"; exit 1; }
"$M" scan -s 1 "$S" 2>/dev/null | grep -q "short.wav" || { echo "mujic test: scan -s 1 finds the short one"; exit 1; }
# the folder is hidden: ~/music is moved to ~/.music once
H2="$T/h2"; mkdir -p "$H2/music"; printf 'ID3' > "$H2/music/Old Song.mp3"
( unset MUJIC_DIR; HOME="$H2" "$M" list | grep -q "Old Song" ) || { echo "mujic test: the old folder music is moved"; exit 1; }
[ -d "$H2/.music" ] && [ ! -d "$H2/music" ] || { echo "mujic test: .music is the folder now"; exit 1; }
# --add puts the found songs into the list for good (.library); mujic remove takes one out (the file stays); -f deletes the file
H3="$T/h3"; mkdir -p "$H3/.music"
( unset MUJIC_DIR; export HOME="$H3"
  "$M" scan -s 60 --add "$S" 2>&1 | grep -q "3 added to the list" || { echo "mujic test: scan --add"; exit 1; }
  "$M" list | grep -q "long" || { echo "mujic test: the scanned song is in the list"; exit 1; }
  "$M" remove long | grep -q "removed long from the list" || { echo "mujic test: remove"; exit 1; }
  "$M" list | grep -q "long" && { echo "mujic test: long must be out of the list"; exit 1; }
  [ -f "$S/a/b/long.wav" ] || { echo "mujic test: remove must keep the file"; exit 1; }
  "$M" remove -f x | grep -q "deleted x" || { echo "mujic test: remove -f"; exit 1; }
  [ ! -e "$S/a/b/x.flac" ] || { echo "mujic test: remove -f deletes the file"; exit 1; }
) || exit 1
echo "mujic tests: ok"
