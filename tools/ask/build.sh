#!/bin/sh
# builds ask into _out/ask (needs jcmp 1.2.7.0 or newer and the library retrieve (jc lib install retrieve); JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" ask.jk -o _out/ask
echo "built _out/ask"
