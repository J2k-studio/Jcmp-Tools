#!/bin/sh
# jash: set / get / list / unset, a value with spaces, the header, the import of the older files, reset
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jash"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export JASH_FILE="$T/.jash" HOME="$T" PREFIX="$T/usr"
[ "$("$J" --version)" = "jash 0.1.0" ] || { echo "jash test: version"; exit 1; }
"$J" get jsh.color_mark && { echo "jash test: get of an unset key must fail"; exit 1; }
"$J" set jsh.color_mark sky; "$J" set app.theme black; "$J" set jsh.color_name "light blue"
[ "$("$J" get jsh.color_mark)" = "sky" ] || { echo "jash test: get"; exit 1; }
[ "$("$J" get jsh.color_name)" = "light blue" ] || { echo "jash test: a value with a space"; exit 1; }
"$J" set jsh.color_mark red
[ "$("$J" get jsh.color_mark)" = "red" ] || { echo "jash test: set again"; exit 1; }
[ "$(grep -c color_mark "$JASH_FILE")" = 1 ] || { echo "jash test: a key twice"; exit 1; }
[ "$(head -n 1 "$JASH_FILE")" = "[#jash]" ] || { echo "jash test: the header"; exit 1; }
[ "$("$J" list jsh | wc -l)" = 2 ] || { echo "jash test: list of a section"; exit 1; }
"$J" unset app.theme; "$J" get app.theme && { echo "jash test: unset"; exit 1; }
mkdir -p "$PREFIX/etc"; printf 'theme = soft\nfont = 13\n' > "$PREFIX/etc/config.local"; printf 'background = #101010\n' > "$PREFIX/etc/theme.toml"
printf 'export JSH_COLOR_PATH="green"\n' > "$HOME/.jshrc"
"$J" import > /dev/null
[ "$("$J" get app.theme)" = "soft" ] && [ "$("$J" get app.font)" = "13" ] || { echo "jash test: import of config.local"; exit 1; }
[ "$("$J" get theme.background)" = "#101010" ] || { echo "jash test: import of theme.toml"; exit 1; }
[ "$("$J" get jsh.color_path)" = "green" ] || { echo "jash test: import of .jshrc"; exit 1; }
"$J" reset > /dev/null; [ -f "$JASH_FILE.old" ] && [ "$("$J" list 2>&1 | grep -c nothing)" = 1 ] || { echo "jash test: reset"; exit 1; }
echo "jash tests: ok"
