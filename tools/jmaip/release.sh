#!/bin/sh
# release.sh [JCMP]: test, build dist/jmaip and write SHA256SUMS. Then: gh release create jmaip-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jmaip_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jmaip_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jmaip dist/jmaip
( cd dist && sha256sum jmaip > SHA256SUMS && ls -l )
