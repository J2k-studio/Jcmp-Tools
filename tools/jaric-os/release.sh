#!/bin/sh
# release.sh [JCMP]: test, build dist/jaric-os and write SHA256SUMS. Then: gh release create jemu-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/jaric-os_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/jaric-os_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/jaric-os dist/jaric-os
cp _out/jaric-os-kernel _out/jaric-os-mkfs _out/jaric-os-font dist/
tar cf dist/jaric-os-files.tar -C dist jaric-os-kernel jaric-os-mkfs jaric-os-font; rm dist/jaric-os-kernel dist/jaric-os-mkfs dist/jaric-os-font
( cd dist && sha256sum jaric-os jaric-os-files.tar > SHA256SUMS && ls -l )
