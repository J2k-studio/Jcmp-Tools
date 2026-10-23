#!/bin/sh
# builds jc into _out/jc (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jc.jk -o _out/jc
echo "built _out/jc"
