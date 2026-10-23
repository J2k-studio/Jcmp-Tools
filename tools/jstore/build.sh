#!/bin/sh
# builds jstore into _out/jstore (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jstore.jk -o _out/jstore
echo "built _out/jstore"
