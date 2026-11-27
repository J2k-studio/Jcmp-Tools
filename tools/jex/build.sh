#!/bin/sh
# builds jex into _out/jex (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jex.jk -o _out/jex
echo "built _out/jex"
