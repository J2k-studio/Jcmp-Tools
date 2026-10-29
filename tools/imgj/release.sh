#!/bin/sh
# release.sh [JCMP]: test, build dist/imgj and write SHA256SUMS. Then: gh release create imgj-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/imgj_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/imgj_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/imgj dist/imgj
( cd dist && sha256sum imgj > SHA256SUMS && ls -l )
