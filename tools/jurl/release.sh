#!/data/data/com.termux/files/usr/bin/bash
# release.sh [JCMP] -- build dist/jurl with the compiler, test it, write SHA256SUMS. Then:  gh release create NAME-vX.Y.Z dist/* (the tag is jurl-vX.Y.Z) --title ... --notes ...
set -eu
cd "$(dirname "$0")"
JCMP=${1:-jcmp}
V=$(cat VERSION)
./test.sh "$JCMP" > ${TMPDIR:-/tmp}/jurl_test.txt 2>&1 || { tail -5 ${TMPDIR:-/tmp}/jurl_test.txt; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
"$JCMP" jurl.jk -o dist/jurl; chmod 755 dist/jurl
[ "$(dist/jurl --version)" = "jurl $V" ] || { echo "release: dist/jurl says $(dist/jurl --version), VERSION says $V"; exit 1; }
( cd dist && sha256sum jurl > SHA256SUMS && ls -l )
