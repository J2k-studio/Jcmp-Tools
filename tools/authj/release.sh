#!/bin/sh
# release.sh [JCMP]: test, build dist/authj and write SHA256SUMS. Then: gh release create authj-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/authj_test.txt" 2>&1 < /dev/null || { tail -5 "${TMPDIR:-/tmp}/authj_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/authj dist/authj
( cd dist && sha256sum authj > SHA256SUMS && ls -l )
