#!/bin/sh
# builds jpty into _out/jpty (needs jcmp 1.0.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jpty.jk -o _out/jpty
echo "built _out/jpty"
