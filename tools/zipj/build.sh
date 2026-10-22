#!/bin/sh
# builds zipj (it is also unj) into _out/zipj (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" zipj.jk -o _out/zipj
echo "built _out/zipj"
