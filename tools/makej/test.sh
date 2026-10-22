#!/bin/sh
# test.sh [JCMP]: builds dist/makej and runs it on the example: the program is built, a second run says nothing is to be built, a step runs, a bad target fails
set -eu
cd "$(dirname "$0")"
JCMP=${1:-jcmp}
sh ./build.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cp -r example/. "$T/"
export PATH="$(dirname "$(command -v "$JCMP")"):$PATH" MAKEJ_HOME="$T/.home" JCMP_LIB="${JCMP_LIB:-}"
cd "$T"
[ "$("$OLDPWD/dist/makej" --version)" = "makej $(cat "$OLDPWD/VERSION")" ] || { echo "version"; exit 1; }
"$OLDPWD/dist/makej" run | grep -q "hello from makej" || { echo "run"; exit 1; }
sleep 1.1
"$OLDPWD/dist/makej" -v | grep -q "up to date" || { echo "up to date"; exit 1; }
if "$OLDPWD/dist/makej" nosuch 2>/dev/null; then echo "bad target"; exit 1; fi
echo "makej tests: ok"
