#!/bin/sh
# release.sh [JCMP]: test, build dist/jstore and write SHA256SUMS. Then: gh release create jstore-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jstore_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jstore_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jstore dist/jstore
( cd dist && sha256sum jstore > SHA256SUMS && ls -l )
