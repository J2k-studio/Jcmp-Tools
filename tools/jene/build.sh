#!/bin/sh
# builds jene into _out/jene (needs jcmp and the library gamej for the games it makes; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jene.jk -o _out/jene
echo "built _out/jene"
