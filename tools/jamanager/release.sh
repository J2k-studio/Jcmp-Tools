#!/bin/sh
# release.sh [JCMP]: test, build dist/jamanager and write SHA256SUMS. Then: gh release create jamanager-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jamanager_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jamanager_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jamanager dist/jamanager
( cd dist && sha256sum jamanager > SHA256SUMS && ls -l )
