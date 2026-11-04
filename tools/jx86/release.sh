#!/bin/sh
# release.sh [JCMP]: test, build dist/jx86 and write SHA256SUMS. Then: gh release create jx86-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jx86_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jx86_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jx86 dist/jx86
( cd dist && sha256sum jx86 > SHA256SUMS && ls -l )
