#!/bin/sh
# release.sh [JCMP]: test, build dist/jrawser and write SHA256SUMS. Then: gh release create jrawser-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jrawser_test.txt" 2>&1 < /dev/null || { tail -5 "${TMPDIR:-/tmp}/jrawser_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jrawser dist/jrawser
( cd dist && sha256sum jrawser > SHA256SUMS && ls -l )
