#!/bin/sh
# release.sh [JCMP]: test, build dist/island and write SHA256SUMS. Then: gh release create island-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/island_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/island_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/island dist/island
( cd dist && sha256sum island > SHA256SUMS && ls -l )
