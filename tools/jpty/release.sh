#!/bin/sh
# release.sh [JCMP]: test, build dist/jpty and write SHA256SUMS. Then: gh release create jpty-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jpty_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jpty_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jpty dist/jpty
( cd dist && sha256sum jpty > SHA256SUMS && ls -l )
