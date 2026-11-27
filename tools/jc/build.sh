#!/bin/sh
# jc is the old name of ex: it is built from the sources of ex (JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
here=$PWD
( cd ../ex && "${JCMP:-jcmp}" ex.jk -o "$here/_out/jc" )
echo "built _out/jc"
