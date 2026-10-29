#!/bin/sh
# jintent: a pretend app answers; apps prints the list, errors give a failure, no app gives a failure, notify sends its message
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jintent --version)" = "jintent $(cat VERSION)" ] || { echo "jintent test: --version"; exit 1; }
J="$PWD/_out/jintent"; F="$PWD/fake_app.py"
out=$(python3 -I "$F" "$J" ok apps 2>&1) || { echo "jintent test: apps: $out"; exit 1; }
echo "$out" | grep -q "com.jaric.app" || { echo "jintent test: apps list: $out"; exit 1; }
out=$(python3 -I "$F" "$J" ok view https://example.org/a 2>&1) || { echo "jintent test: view: $out"; exit 1; }
echo "$out" | grep -q "intent;view;https://example.org/a" || { echo "jintent test: view message: $out"; exit 1; }
out=$(python3 -I "$F" "$J" ok send hello world 2>&1) || { echo "jintent test: send: $out"; exit 1; }
echo "$out" | grep -q "intent;send;hello world" || { echo "jintent test: send message: $out"; exit 1; }
if python3 -I "$F" "$J" error app nothing > /dev/null 2>&1; then echo "jintent test: an error must fail"; exit 1; fi
out=$(python3 -I "$F" "$J" ok notify Title some text 2>&1) || { echo "jintent test: notify: $out"; exit 1; }
echo "$out" | grep -q "notify;Title;some text" || { echo "jintent test: notify message: $out"; exit 1; }
echo "jintent test: ok"
