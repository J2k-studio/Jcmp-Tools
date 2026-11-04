#!/bin/sh
# builds jmaip into _out/jmaip (needs jcmp 1.2.12.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jmaip.jk -o _out/jmaip
echo "built _out/jmaip"
