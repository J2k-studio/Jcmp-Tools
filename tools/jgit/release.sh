#!/bin/sh
# release.sh [JCMP]: test, build dist/jgit and write SHA256SUMS. Then: gh release create jgit-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jgit_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jgit_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jgit dist/jgit
( cd dist && sha256sum jgit > SHA256SUMS && ls -l )
