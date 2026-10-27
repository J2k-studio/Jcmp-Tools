#!/bin/sh
# builds drive into _out/drive (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" drive.jk -o _out/drive
echo "built _out/drive"
