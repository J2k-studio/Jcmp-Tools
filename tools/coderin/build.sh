#!/bin/sh
# coderin is the old name of fcode: it is built from the sources of fcode (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
here=$PWD
( cd ../fcode && "${JCMP:-jcmp}" fcode.jk -o "$here/_out/coderin" )
echo "built _out/coderin"
