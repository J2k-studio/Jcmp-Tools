#!/bin/sh
# release.sh [JCMP]: test, build dist/ex and write SHA256SUMS. Then: gh release create ex-vX.Y.Z dist/* --repo J2k-studio/ex-pkg --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jc_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jc_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/ex dist/ex
( cd dist && sha256sum ex > SHA256SUMS && ls -l )
