#!/bin/sh
# builds tarj (it is also gzj) into _out/tarj (needs jcmp 1.1.0.0 or newer and the library deflate: jc lib install deflate; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" tarj.jk -o _out/tarj
echo "built _out/tarj"
