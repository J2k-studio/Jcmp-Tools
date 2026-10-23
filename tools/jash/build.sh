#!/bin/sh
# builds jash into _out/jash (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jash.jk -o _out/jash
echo "built _out/jash"
