#!/bin/sh
# release.sh [JCMP]: test, build dist/calc and write SHA256SUMS. Then: gh release create calc-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/calc_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/calc_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/calc dist/calc
( cd dist && sha256sum calc > SHA256SUMS && ls -l )
