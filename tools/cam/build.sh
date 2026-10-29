#!/bin/sh
# builds cam into _out/cam (needs jcmp 1.2.2.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" cam.jk -o _out/cam
echo "built _out/cam"
