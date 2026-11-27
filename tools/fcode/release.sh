#!/bin/sh
# release.sh [JCMP]: test, build dist/fcode and write SHA256SUMS. Then: gh release create fcode-vX.Y.Z dist/* --repo J2k-studio/ex-pkg --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/fcode_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/fcode_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/fcode dist/fcode
( cd dist && sha256sum fcode > SHA256SUMS && ls -l )
