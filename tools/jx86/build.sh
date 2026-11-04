#!/bin/sh
# builds jx86 into _out/jx86 (needs jcmp 1.2.12.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jx86.jk -o _out/jx86
echo "built _out/jx86"
