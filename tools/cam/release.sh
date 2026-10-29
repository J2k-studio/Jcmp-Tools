#!/bin/sh
# release.sh [JCMP]: test, build dist/cam and write SHA256SUMS. Then: gh release create cam-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/cam_test.txt" 2>&1 < /dev/null || { tail -5 "${TMPDIR:-/tmp}/cam_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/cam dist/cam
( cd dist && sha256sum cam > SHA256SUMS && ls -l )
