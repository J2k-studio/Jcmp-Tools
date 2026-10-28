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
[ ! -e src ] || { echo "init -ai must not write src/ (a bare makej would build it)"; exit 1; }
out=$("$MK" 2>&1); case "$out" in *error*) echo "a bare makej in an -ai project must build nothing: $out"; exit 1 ;; esac
# the language model step needs the tool neuron: build it here and put it on the PATH
NB="$ROOT/../neuron"
if [ -f "$NB/neuron.jk" ]; then
    mkdir -p "$ROOT/_neuronbin"; ( cd "$NB" && J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}" "${JCMP:-jcmp}" neuron.jk -o "$ROOT/_neuronbin/neuron" ) >/dev/null 2>&1 || { echo "ai: neuron does not build"; exit 1; }
    PATH="$ROOT/_neuronbin:$PATH" "$MK" train | grep "saved assistant.jw" >/dev/null || { echo "ai train (neuron)"; exit 1; }
    [ -f assistant.jw ] || { echo "ai: assistant.jw is missing"; exit 1; }
    rm -rf "$ROOT/_neuronbin"
fi
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
printf 'itf X { void f(self); }\nstruct S impl X { void init(self) { } void f(self) { } }\nvoid main() { S s; s.init(); }\n' > "$T/itf_probe.jk"
if jcmp "$T/itf_probe.jk" -o "$T/itf_probe" >/dev/null 2>&1 && command -v aapt2 >/dev/null 2>&1 && command -v ecj >/dev/null 2>&1 && command -v d8 >/dev/null 2>&1 && command -v apksigner >/dev/null 2>&1 && command -v zipalign >/dev/null 2>&1 && command -v jpty >/dev/null 2>&1 && { [ -n "${ANDROID_JAR:-}" ] || [ -f "$HOME/Jaric/android.jar" ] || [ -f "$HOME/android.jar" ]; } && [ -f "$HOME/Jcmp/build/libs/gamej.j" ]; then
    mkdir "$T/game" && cd "$T/game"
    "$MK" init -game >/dev/null || { echo "init -game"; exit 1; }
    J2K_PATH="$HOME/Jcmp/build/libs" "$MK" apk >/dev/null 2>&1 || { echo "apk"; exit 1; }
    [ -f _out/My_Game.apk ] || { echo "apk file"; exit 1; }
    unzip -l _out/My_Game.apk | grep "assets/bin/game" >/dev/null || { echo "apk holds the game"; exit 1; }
    cd "$ROOT"
fi
# the structure of a project (init -pro) builds and its tests pass; the systems (targets, dist -os jaric)
mkdir "$T/pro" && cd "$T/pro"
"$MK" init -pro demo >/dev/null || { echo "init -pro"; exit 1; }
cd demo
out=$("$MK" test 2>&1); echo "$out" | grep "all tests passed" >/dev/null || { echo "pro tests: $out"; exit 1; }
out=$("$MK" run 2>&1); echo "$out" | grep "welcome to project" >/dev/null || { echo "pro run: $out"; exit 1; }
[ -f VERSION ] && [ -f manifest.toml ] && [ -d docs ] && [ -d tests ] && [ -d scripts ] || { echo "pro layout"; exit 1; }
"$MK" targets | grep "android" >/dev/null || { echo "targets"; exit 1; }
mkdir "$T/alias" && cd "$T/alias" && "$MK" -pro >/dev/null && [ -d src ] && [ -f manifest.toml ] || { echo "makej -pro (the same as makej init -pro)"; exit 1; }
cd "$T/pro/demo"
if command -v zipj >/dev/null 2>&1 && [ -f "$HOME/Jcmp/build/libs/gamej.j" ]; then
    cd "$T" && mkdir jg && cd jg
    "$MK" init -game -os jaric >/dev/null || { echo "init -game -os"; exit 1; }
    J2K_PATH="$HOME/Jcmp/build/libs" "$MK" dist >/dev/null 2>&1 || { echo "dist jaric"; exit 1; }
    [ -f _out/game.jc ] && [ ! -f _out/My_Game.apk ] || { echo "dist makes only the jc package"; exit 1; }
fi
# makej init -apk: an Android app project (os = android), and  makej -apk  is the same
cd "$T" && mkdir ap && cd ap && "$MK" init -apk 2>&1 | grep -q "Android app project" || { echo "init -apk"; exit 1; }
[ -f makej ] && [ -f manifest.toml ] && [ -f src/main.jk ] && grep -q '^os = "android"' manifest.toml || { echo "init -apk makes the project with os = android"; exit 1; }
cd "$T" && mkdir ap2 && cd ap2 && "$MK" -apk >/dev/null && grep -q '^os = "android"' manifest.toml || { echo "makej -apk"; exit 1; }
# makej doc: the comment at the top of a library
J2K_PATH="$HOME/Jcmp/build/libs" "$MK" doc | grep -q "^gamej" || { echo "doc list"; exit 1; }
J2K_PATH="$HOME/Jcmp/build/libs" "$MK" doc gamej | grep -q "Game" || { echo "doc NAME"; exit 1; }
"$MK" doc no_such_lib_xyz >/dev/null 2>&1 && { echo "doc of a missing library must fail"; exit 1; }
# render = "gl": a game that is a shared library in an app with a GLSurfaceView (needs the apk tools, android.jar, and the libraries of jcmp 1.2.3: canvas2d, glcanvas, glapp)
if command -v aapt2 >/dev/null 2>&1 && command -v ecj >/dev/null 2>&1 && command -v d8 >/dev/null 2>&1 && command -v zipalign >/dev/null 2>&1 && command -v apksigner >/dev/null 2>&1 && [ -f "$HOME/Jaric/android.jar" ] && [ -f "$HOME/Jcmp/build/libs/glapp.j" ]; then
    cd "$T" && mkdir glapk && cd glapk && mkdir src
    printf 'name = "GL Test"\nid = "com.example.gltest"\nversion = "0.1.0"\nrender = "gl"\nmain = "src/main.jk"\n' > manifest.toml
    printf '#import <stdlib>\n#import <glapp>\nvoid game_init(int w, int h) { }\nvoid game_resize(int w, int h) { }\nvoid game_frame(int ms) { Canvas2d^ c = glapp_canvas(); c^.begin(); c^.clear(Color::rgb(0, 0, 64)); c^.end(); }\nvoid game_touch(int a, int x, int y, int id) { }\n' > src/main.jk
    ANDROID_JAR="$HOME/Jaric/android.jar" J2K_PATH="$HOME/Jcmp/build/libs" "$MK" apk >/dev/null 2>&1 || { echo "apk render gl: the build failed"; exit 1; }
    [ -f _out/GL_Test.apk ] || { echo "apk render gl: no apk"; exit 1; }
    unzip -l _out/GL_Test.apk | grep -q "lib/arm64-v8a/libgame.so" || { echo "apk render gl: no libgame.so in the apk"; exit 1; }
    aapt2 dump badging _out/GL_Test.apk 2>/dev/null | grep -q "launchable-activity: name='com.j2k.gamerun.GlGameActivity'" || { echo "apk render gl: wrong activity"; exit 1; }
fi
cd "$ROOT"
echo "makej tests (game): ok"
