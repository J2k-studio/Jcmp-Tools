#!/bin/sh
# builds jsh and its helper jbox into _out/ (needs jcmp 1.0.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jsh.jk -o _out/jsh
"${JCMP:-jcmp}" ../jbox/jbox.jk -o _out/jbox
echo "built _out/jsh and _out/jbox"
