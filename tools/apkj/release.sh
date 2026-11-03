#!/bin/sh
# release.sh [JCMP]: build, test, write dist/apkj and SHA256SUMS. Then: gh release create apkj-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./build.sh > "${TMPDIR:-/tmp}/apkj_build.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/apkj_build.txt"; echo "release: the build fails"; exit 1; }
sh ./test.sh > "${TMPDIR:-/tmp}/apkj_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/apkj_test.txt"; echo "release: the tests fail"; exit 1; }
[ "$(_out/apkj --version)" = "apkj $(cat VERSION)" ] || { echo "release: version text differs from VERSION"; exit 1; }
rm -rf dist; mkdir dist
cp _out/apkj dist/apkj
( cd dist && sha256sum apkj > SHA256SUMS && ls -l )
