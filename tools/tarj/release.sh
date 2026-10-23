#!/bin/sh
# release.sh [JCMP]: test, build dist/tarj and write SHA256SUMS. Then: gh release create tarj-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/tarj_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/tarj_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/tarj dist/tarj
( cd dist && sha256sum tarj > SHA256SUMS && ls -l )
