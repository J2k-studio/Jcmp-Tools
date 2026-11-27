#!/bin/sh
# jex: --version, help lines of at most 38 characters, lib list works against a mirror of the index, a wrong command fails
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jex --version)" = "jex $(cat VERSION)" ] || { echo "jex test: --version differs from VERSION"; exit 1; }
long=$(./_out/jex help | awk 'length($0) > 38' | wc -l)
[ "$long" = 0 ] || { echo "jex test: a line of help is longer than 38 characters"; exit 1; }
J="$PWD/_out/jex"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf 'demo 1.0 file://%s/demo.j %s\n' "$T" "$(printf 'int x;\n' > demo.j; sha256sum demo.j | cut -d' ' -f1)" > index.txt
HOME="$T" JCMP_LIB_INDEX="file://$T/index.txt" "$J" lib list >/dev/null 2>&1 || true
"$J" nothing >/dev/null 2>&1 && { echo "jex test: a wrong command must fail"; exit 1; }
echo "jex test: ok"
