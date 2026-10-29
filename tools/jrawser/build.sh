#!/bin/sh
# builds jrawser into _out/jrawser (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jrawser.jk -o _out/jrawser
echo "built _out/jrawser"
