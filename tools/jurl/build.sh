#!/bin/sh
# builds jurl into _out/jurl (needs jcmp 1.2.0.0 or newer; the library deflate: J2K_PATH=folder, or jex lib install deflate)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}" "${JCMP:-jcmp}" jurl.jk -o _out/jurl
echo "built _out/jurl"
