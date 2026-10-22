#!/bin/sh
# release.sh [JCMP]: test, build dist/jbox and write SHA256SUMS. Then: gh release create jbox-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jbox_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jbox_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jbox dist/jbox
( cd dist && sha256sum jbox > SHA256SUMS && ls -l )
