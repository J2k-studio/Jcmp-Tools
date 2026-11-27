#!/bin/sh
# release.sh [JCMP]: test, build dist/jex and write SHA256SUMS. Then: gh release create jex-vX.Y.Z dist/* --repo J2k-studio/ex-pkg --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jex_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jex_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jex dist/jex
( cd dist && sha256sum jex > SHA256SUMS && ls -l )
