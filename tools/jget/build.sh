#!/bin/sh
# builds jget into _out/jget (needs jcmp 1.2.0.0 or newer; the library deflate: J2K_PATH=folder, or jc lib install deflate)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}" "${JCMP:-jcmp}" jget.jk -o _out/jget
echo "built _out/jget"
