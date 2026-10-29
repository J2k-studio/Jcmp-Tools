#!/bin/sh
# builds authj into _out/authj (needs jcmp 1.2.2.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" authj.jk -o _out/authj
echo "built _out/authj"
