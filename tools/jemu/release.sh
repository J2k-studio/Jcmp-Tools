#!/bin/sh
# release.sh [JCMP]: test, build dist/jemu and write SHA256SUMS. Then: gh release create jemu-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jemu_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jemu_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jemu dist/jemu
cp _out/jemu-kernel _out/jemu-mkfs dist/
tar cf dist/jemu-files.tar -C dist jemu-kernel jemu-mkfs; rm dist/jemu-kernel dist/jemu-mkfs
( cd dist && sha256sum jemu jemu-files.tar > SHA256SUMS && ls -l )
