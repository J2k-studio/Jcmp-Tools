#!/bin/sh
# builds jearlink into _out/jearlink (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jearlink.jk -o _out/jearlink
echo "built _out/jearlink"
