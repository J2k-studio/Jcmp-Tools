#!/bin/sh
# jaric-os: version, help, and Jaric OS from  jaric-os  (a disk made of a folder; ls, cat, echo, exit typed to the console)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
B="$PWD/_out"
[ "$("$B/jaric-os" --version)" = "jaric-os 0.2.0" ] || { echo "jaric-os test: version"; exit 1; }
"$B/jaric-os" --help | grep -q "start Jaric OS" || { echo "jaric-os test: help"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T/home" TMPDIR="$T"; mkdir -p "$HOME" "$T/disk"
printf 'first file\n' > "$T/disk/a.txt"; printf 'second\n' > "$T/disk/b.txt"
OUT=$(printf 'ls\ncat a.txt\necho hello there\nexit\n' | "$B/jaric-os" "$T/disk" 2>&1)
case "$OUT" in *"Jaric OS K7"*"j> ls"*"a.txt"*"b.txt"*"first file"*"hello there"*"bye"*) ;; *) echo "jaric-os test: jemu os: $OUT"; exit 1 ;; esac
# no folder given: ~/.jaric-os is made with two small files
OUT2=$(printf 'ls\nexit\n' | "$B/jaric-os" 2>&1)
case "$OUT2" in *"hello.txt"*"readme.txt"*) ;; *) echo "jaric-os test: the default folder: $OUT2"; exit 1 ;; esac
[ -f "$HOME/.jaric-os/hello.txt" ] || { echo "jaric-os test: ~/.jaric-os"; exit 1; }
# the emulator itself (a Linux program) is for the developers: JARIC_OS_DEV=1; without it jaric-os says no

printf '#import <stdlib>\nint main() { cout << "from jemu\\n"; return 5; }\n' > "$T/p.jk"
"${JCMP:-jcmp}" "$T/p.jk" -o "$T/p" >/dev/null 2>&1
set +e; JARIC_OS_DEV=1 "$B/jaric-os" "$T/p" > "$T/p.out"; rc=$?; "$B/jaric-os" --system "$T/p" >/dev/null 2>&1; rc2=$?; set -e
[ "$rc2" = 2 ] || { echo "jaric-os test: --system must be refused ($rc2)"; exit 1; }
[ "$rc" = 5 ] && [ "$(cat "$T/p.out")" = "from jemu" ] || { echo "jaric-os test: a Linux program ($rc)"; exit 1; }
# jemu boot: the start screen is sent to the app (OSC gfx open / present) and the picture file has the size of the screen
OUTB=$("$B/jaric-os" boot 2>&1 | tr -d '\033\007')
case "$OUTB" in *"]7777;gfx;open;360;640;"*"]7777;gfx;present"*) ;; *) echo "jaric-os test: jemu boot"; exit 1 ;; esac
[ "$(wc -c < "$T/jaric-os-screen.bgra")" = 921600 ] || { echo "jaric-os test: the screen file"; exit 1; }
# in the Jaric app (JARIC is set) the system has a text screen of its own: the picture is sent to the app and the letters of the kernel are on it
OUTT=$(printf 'ls\nexit\n' | JARIC=1 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007')
case "$OUTT" in *"]7777;gfx;open;540;960;"*) ;; *) echo "jaric-os test: the text screen"; exit 1 ;; esac
[ "$(wc -c < "$T/jaric-os-screen.bgra")" = 2073600 ] || { echo "jaric-os test: the text screen file"; exit 1; }
echo "jaric-os tests: ok"
