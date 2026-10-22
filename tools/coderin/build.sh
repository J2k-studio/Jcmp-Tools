#!/bin/sh
# builds coderin into _out/coderin (needs jcmp 1.0.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" coderin.jk -o _out/coderin
echo "built _out/coderin"
