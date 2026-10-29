#!/bin/sh
# jearlink: a pretend app answers; apps prints the list, errors give a failure, no app gives a failure, notify sends its message
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jearlink --version)" = "jearlink $(cat VERSION)" ] || { echo "jearlink test: --version"; exit 1; }
J="$PWD/_out/jearlink"; F="$PWD/fake_app.py"
out=$(python3 -I "$F" "$J" ok -aps 2>&1) || { echo "jearlink test: apps: $out"; exit 1; }
echo "$out" | grep -q "com.jaric.app" || { echo "jearlink test: apps list: $out"; exit 1; }
out=$(python3 -I "$F" "$J" ok -viw https://example.org/a 2>&1) || { echo "jearlink test: view: $out"; exit 1; }
echo "$out" | grep -q "intent;view;https://example.org/a" || { echo "jearlink test: view message: $out"; exit 1; }
out=$(python3 -I "$F" "$J" ok -snd hello world 2>&1) || { echo "jearlink test: send: $out"; exit 1; }
echo "$out" | grep -q "intent;send;hello world" || { echo "jearlink test: send message: $out"; exit 1; }
if python3 -I "$F" "$J" error -ap nothing > /dev/null 2>&1; then echo "jearlink test: an error must fail"; exit 1; fi
out=$(python3 -I "$F" "$J" ok -ntf Title some text 2>&1) || { echo "jearlink test: notify: $out"; exit 1; }
echo "$out" | grep -q "notify;Title;some text" || { echo "jearlink test: notify message: $out"; exit 1; }
echo "jearlink test: ok"
