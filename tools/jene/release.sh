#!/bin/sh
# release.sh [JCMP]: test, build dist/jene and write SHA256SUMS. Then: gh release create jene-vX.Y.Z dist/* --repo J2k-studio/ex-pkg --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jene_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jene_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jene dist/jene
( cd dist && sha256sum jene > SHA256SUMS && ls -l )
