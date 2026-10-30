#!/bin/sh
# builds island into _out/island (needs jcmp 1.2.5.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" island.jk -o _out/island
echo "built _out/island"
