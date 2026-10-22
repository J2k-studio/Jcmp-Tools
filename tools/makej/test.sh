#!/bin/sh
# test.sh [JCMP]: builds dist/makej and runs it on the example: the program is built, a second run says nothing is to be built, a step runs, a bad target fails
set -eu
cd "$(dirname "$0")"
ROOT=$PWD
ROOT=$PWD
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
"$OLDPWD/dist/makej" -j 4 | grep -q "done" || { echo "jobs"; exit 1; }
if "$OLDPWD/dist/makej" nosuch 2>/dev/null; then echo "bad target"; exit 1; fi
MK="$ROOT/dist/makej"
mkdir "$T/ai" && cd "$T/ai"
"$MK" init -ai >/dev/null || { echo "init -ai"; exit 1; }
mkdir -p "$ROOT/_neuron" ; cp "$ROOT/../../../Jcmp/build/libs/neuron.j" "$ROOT/_neuron/" 2>/dev/null || cp "$HOME/Jcmp/build/libs/neuron.j" "$ROOT/_neuron/"
J2K_PATH="$ROOT/_neuron" "$MK" train | grep -q "trained on 4 rows" || { echo "ai train"; exit 1; }
rm -rf "$ROOT/_neuron"
echo "makej tests: ok"
# list, clean, -n, install
T2=$(mktemp -d); cp -r "$ROOT/example/." "$T2/"; cd "$T2"
"$ROOT/dist/makej" list | grep -q "hello" || { echo "list"; exit 1; }
"$ROOT/dist/makej" -n | grep -q "hello" || { echo "dry run"; exit 1; }
[ ! -f _out/hello ] || { echo "-n must not build"; exit 1; }
"$ROOT/dist/makej" > /dev/null && [ -f _out/hello ] || { echo "build"; exit 1; }
"$ROOT/dist/makej" install "$T2/bin" | grep -q installed && [ -f "$T2/bin/hello" ] || { echo "install"; exit 1; }
"$ROOT/dist/makej" clean | grep -q removed && [ ! -d _out ] || { echo "clean"; exit 1; }
rm -rf "$T2"
echo "makej tests (more): ok"
