#!/bin/sh
# builds fcode into _out/fcode (needs jcmp 1.0.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" fcode.jk -o _out/fcode
echo "built _out/fcode"
