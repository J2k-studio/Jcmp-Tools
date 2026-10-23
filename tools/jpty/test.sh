#!/bin/sh
# builds jpty and checks: the program sees a terminal of the size asked for, the size can change, the exit code comes back
set -eu
cd "$(dirname "$0")"
sh build.sh >/dev/null
[ "$(./_out/jpty --version)" = "jpty $(cat VERSION)" ] || { echo "jpty test: --version differs from VERSION"; exit 1; }
SHELL_BIN=$(command -v sh)
OUT=$( (printf 'stty size\nexit 3\n') | _out/jpty -w 100 -h 30 "$SHELL_BIN" | tr -d '\r' || true)
echo "$OUT" | grep -q '30 100' || { echo "jpty test: the size 30 100 was not seen"; exit 1; }
OUT=$( (printf '\033]jpty;120;40\007'; sleep 0.3; printf 'stty size\nexit\n') | _out/jpty -w 80 -h 24 "$SHELL_BIN" | tr -d '\r' || true)
echo "$OUT" | grep -q '40 120' || { echo "jpty test: the new size 40 120 was not seen"; exit 1; }
set +e
printf 'exit 3\n' | _out/jpty "$SHELL_BIN" >/dev/null
[ $? = 3 ] || { echo "jpty test: exit code"; exit 1; }
echo "jpty test: ok"
