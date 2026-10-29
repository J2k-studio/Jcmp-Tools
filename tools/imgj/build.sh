#!/bin/sh
# builds imgj into _out/imgj (needs jcmp 1.2.2.0 or newer and the libraries deflate and png: jc lib install deflate png; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" imgj.jk -o _out/imgj
echo "built _out/imgj"
