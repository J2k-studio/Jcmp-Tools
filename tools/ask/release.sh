#!/bin/sh
# release.sh [JCMP]: test, build dist/ask and write SHA256SUMS. Then: gh release create ask-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/ask_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/ask_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/ask dist/ask
( cd dist && sha256sum ask > SHA256SUMS && ls -l )
