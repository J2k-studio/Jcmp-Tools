#!/bin/sh
# release.sh [JCMP]: test, build dist/drive and write SHA256SUMS. Then: gh release create drive-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/drive_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/drive_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/drive dist/drive
( cd dist && sha256sum drive > SHA256SUMS && ls -l )
