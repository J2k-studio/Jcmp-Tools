#!/bin/sh
# jemu: version, help, and Jaric OS from  jemu os  (a disk made of a folder; ls, cat, echo, exit typed to the console)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
B="$PWD/_out"
[ "$("$B/jemu" --version)" = "jemu 0.1.0" ] || { echo "jemu test: version"; exit 1; }
"$B/jemu" --help | grep -q "jemu os" || { echo "jemu test: help"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T/home" TMPDIR="$T"; mkdir -p "$HOME" "$T/disk"
printf 'first file\n' > "$T/disk/a.txt"; printf 'second\n' > "$T/disk/b.txt"
OUT=$(printf 'ls\ncat a.txt\necho hello there\nexit\n' | "$B/jemu" os "$T/disk" 2>&1)
case "$OUT" in *"Jaric OS K7"*"j> ls"*"a.txt"*"b.txt"*"first file"*"hello there"*"bye"*) ;; *) echo "jemu test: jemu os: $OUT"; exit 1 ;; esac
# no folder given: ~/.jemu-os is made with two small files
OUT2=$(printf 'ls\nexit\n' | "$B/jemu" os 2>&1)
case "$OUT2" in *"hello.txt"*"readme.txt"*) ;; *) echo "jemu test: the default folder: $OUT2"; exit 1 ;; esac
[ -f "$HOME/.jemu-os/hello.txt" ] || { echo "jemu test: ~/.jemu-os"; exit 1; }
# a Linux program: the host answers its calls
printf '#import <stdlib>\nint main() { cout << "from jemu\\n"; return 5; }\n' > "$T/p.jk"
"${JCMP:-jcmp}" "$T/p.jk" -o "$T/p" >/dev/null 2>&1
set +e; "$B/jemu" "$T/p" > "$T/p.out"; rc=$?; set -e
[ "$rc" = 5 ] && [ "$(cat "$T/p.out")" = "from jemu" ] || { echo "jemu test: a Linux program ($rc)"; exit 1; }
echo "jemu tests: ok"
