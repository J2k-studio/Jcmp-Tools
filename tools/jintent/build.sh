#!/bin/sh
# builds jintent into _out/jintent (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jintent.jk -o _out/jintent
echo "built _out/jintent"
