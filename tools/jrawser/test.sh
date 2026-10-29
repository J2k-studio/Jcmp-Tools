#!/bin/sh
# jrawser: in the app it sends the message with the address; outside the app it says so and fails
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jrawser"
[ "$("$J" --version)" = "jrawser $(cat VERSION)" ] || { echo "jrawser test: --version"; exit 1; }
out=$(JARIC=1 "$J" example.org)
printf '%s' "$out" | grep -q "web;open;example.org" || { echo "jrawser test: the message: $out"; exit 1; }
out=$(JARIC=1 "$J" how to cook rice)
printf '%s' "$out" | grep -q "web;open;how to cook rice" || { echo "jrawser test: words: $out"; exit 1; }
out=$(JARIC=1 "$J")
printf '%s' "$out" | grep -q "web;open;" || { echo "jrawser test: no address: $out"; exit 1; }
if env -u JARIC "$J" example.org > /dev/null 2>&1; then echo "jrawser test: outside the app it must fail"; exit 1; fi
echo "jrawser test: ok"
