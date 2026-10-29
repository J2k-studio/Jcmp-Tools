#!/bin/sh
# builds mulap into _out/mulap (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" mulap.jk -o _out/mulap
echo "built _out/mulap"
