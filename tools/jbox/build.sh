#!/bin/sh
# builds jbox into _out/jbox (needs jcmp 1.0.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jbox.jk -o _out/jbox
echo "built _out/jbox"
