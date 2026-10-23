#!/bin/sh
# builds jvp4 into _out/jvp4 (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jvp4.jk -o _out/jvp4
echo "built _out/jvp4"
