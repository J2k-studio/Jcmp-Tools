#!/bin/sh
# builds jgit into _out/jgit (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jgit.jk -o _out/jgit
echo "built _out/jgit"
