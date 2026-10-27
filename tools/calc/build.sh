#!/bin/sh
# builds calc into _out/calc (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" calc.jk -o _out/calc
echo "built _out/calc"
