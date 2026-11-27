#!/bin/sh
# builds ascode into _out/ascode (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" ascode.jk -o _out/ascode
echo "built _out/ascode"
