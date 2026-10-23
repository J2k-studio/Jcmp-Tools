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
MKJ="$OLDPWD/dist/makej"
out=$("$MKJ" run 2>&1); echo "$out" | grep "hello from makej" >/dev/null || { echo "run: $out"; exit 1; }
sleep 1.1
out=$("$MKJ" -v 2>&1); echo "$out" | grep "up to date" >/dev/null || { echo "up to date: $out"; exit 1; }
out=$("$MKJ" -j 4 2>&1); echo "$out" | grep "done" >/dev/null || { echo "jobs: $out"; exit 1; }
if "$OLDPWD/dist/makej" nosuch 2>/dev/null; then echo "bad target"; exit 1; fi
MK="$ROOT/dist/makej"
mkdir "$T/ai" && cd "$T/ai"
"$MK" init -ai >/dev/null || { echo "init -ai"; exit 1; }
mkdir -p "$ROOT/_neuron" ; cp "$ROOT/../../../Jcmp/build/libs/neuron.j" "$ROOT/_neuron/" 2>/dev/null || cp "$HOME/Jcmp/build/libs/neuron.j" "$ROOT/_neuron/"
J2K_PATH="$ROOT/_neuron" "$MK" train | grep "trained on 4 rows" >/dev/null || { echo "ai train"; exit 1; }
rm -rf "$ROOT/_neuron"
echo "makej tests: ok"
# list, clean, -n, install
T2=$(mktemp -d); cp -r "$ROOT/example/." "$T2/"; cd "$T2"
"$ROOT/dist/makej" list | grep "hello" >/dev/null || { echo "list"; exit 1; }
"$ROOT/dist/makej" -n | grep "hello" >/dev/null || { echo "dry run"; exit 1; }
[ ! -f _out/hello ] || { echo "-n must not build"; exit 1; }
"$ROOT/dist/makej" > /dev/null && [ -f _out/hello ] || { echo "build"; exit 1; }
"$ROOT/dist/makej" install "$T2/bin" | grep -q installed && [ -f "$T2/bin/hello" ] || { echo "install"; exit 1; }
"$ROOT/dist/makej" clean | grep -q removed && [ ! -d _out ] || { echo "clean"; exit 1; }
rm -rf "$T2"
echo "makej tests (more): ok"

# an Android app from a game project, when the Android tools and android.jar are here (otherwise this part is skipped)
if command -v aapt2 >/dev/null 2>&1 && command -v ecj >/dev/null 2>&1 && command -v d8 >/dev/null 2>&1 && command -v apksigner >/dev/null 2>&1 && command -v zipalign >/dev/null 2>&1 && command -v jpty >/dev/null 2>&1 && { [ -n "${ANDROID_JAR:-}" ] || [ -f "$HOME/Jaric/android.jar" ] || [ -f "$HOME/android.jar" ]; } && [ -f "$HOME/Jcmp/build/libs/gamej.j" ]; then
    mkdir "$T/game" && cd "$T/game"
    "$MK" init -game >/dev/null || { echo "init -game"; exit 1; }
    J2K_PATH="$HOME/Jcmp/build/libs" "$MK" apk >/dev/null 2>&1 || { echo "apk"; exit 1; }
    [ -f _out/My_Game.apk ] || { echo "apk file"; exit 1; }
    unzip -l _out/My_Game.apk | grep "assets/bin/game" >/dev/null || { echo "apk holds the game"; exit 1; }
    cd "$ROOT"
fi
echo "makej tests (game): ok"
