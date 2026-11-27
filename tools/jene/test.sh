#!/bin/sh
# jene: --version, help lines of at most 38 characters, jene -c makes the folder, the project file and the program
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jene --version)" = "jene $(cat VERSION)" ] || { echo "jene test: --version differs from VERSION"; exit 1; }
long=$(./_out/jene --help | awk 'length($0) > 38' | wc -l)
[ "$long" = 0 ] || { echo "jene test: a line of --help is longer than 38 characters"; exit 1; }
J="$PWD/_out/jene"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
"$J" -c demo >/dev/null
[ -f demo/demo.jene ] || { echo "jene test: no demo/demo.jene"; exit 1; }
[ -d demo/src ] || { echo "jene test: no demo/src"; exit 1; }
"$J" nothing >/dev/null 2>&1 && { echo "jene test: a wrong option must fail"; exit 1; }
echo "jene test: ok"
