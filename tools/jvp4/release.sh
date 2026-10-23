#!/bin/sh
# release.sh [JCMP]: test, build dist/jvp4 and write SHA256SUMS. Then: gh release create jvp4-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jvp4_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jvp4_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jvp4 dist/jvp4
( cd dist && sha256sum jvp4 > SHA256SUMS && ls -l )
