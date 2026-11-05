#!/bin/sh
# builds learnj into _out/learnj (needs jcmp 1.2.14.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" learnj.jk -o _out/learnj
echo "built _out/learnj"
