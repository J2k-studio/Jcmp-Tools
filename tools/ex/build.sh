#!/bin/sh
# builds ex into _out/ex (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" ex.jk -o _out/ex
echo "built _out/ex"
