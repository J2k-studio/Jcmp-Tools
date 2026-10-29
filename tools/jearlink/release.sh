#!/bin/sh
# release.sh [JCMP]: test, build dist/jearlink and write SHA256SUMS. Then: gh release create jearlink-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jearlink_test.txt" 2>&1 < /dev/null || { tail -5 "${TMPDIR:-/tmp}/jearlink_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jearlink dist/jearlink
( cd dist && sha256sum jearlink > SHA256SUMS && ls -l )
