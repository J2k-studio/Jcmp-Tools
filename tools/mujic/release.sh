#!/bin/sh
# release.sh [JCMP]: test, build dist/mujic and write SHA256SUMS. Then: gh release create mujic-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/mujic_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/mujic_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/mujic dist/mujic
( cd dist && sha256sum mujic > SHA256SUMS && ls -l )
