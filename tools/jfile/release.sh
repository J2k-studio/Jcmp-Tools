#!/bin/sh
# release.sh [JCMP]: test, build dist/jfile and write SHA256SUMS. Then: gh release create jfile-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jfile_test.txt" 2>&1 < /dev/null || { tail -5 "${TMPDIR:-/tmp}/jfile_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jfile dist/jfile
( cd dist && sha256sum jfile > SHA256SUMS && ls -l )
