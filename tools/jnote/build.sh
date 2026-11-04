#!/bin/sh
# builds jnote into _out/jnote (needs jcmp 1.2.12.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jnote.jk -o _out/jnote
echo "built _out/jnote"
