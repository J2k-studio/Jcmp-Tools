#!/bin/sh
# builds jamanager into _out/jamanager (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jamanager.jk -o _out/jamanager
echo "built _out/jamanager"
