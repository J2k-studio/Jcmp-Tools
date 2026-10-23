#!/bin/sh
# builds mujic into _out/mujic (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" mujic.jk -o _out/mujic
echo "built _out/mujic"
