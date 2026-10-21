#!/data/data/com.termux/files/usr/bin/bash
# release.sh [JCMP] -- build dist/jget with the compiler, test it, write SHA256SUMS. Then:  gh release create NAME-vX.Y.Z dist/* (the tag is jget-vX.Y.Z) --title ... --notes ...
set -eu
cd "$(dirname "$0")"
JCMP=${1:-jcmp}
V=$(cat VERSION)
./test.sh "$JCMP" > ${TMPDIR:-/tmp}/jget_test.txt 2>&1 || { tail -5 ${TMPDIR:-/tmp}/jget_test.txt; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
"$JCMP" jget.jk -o dist/jget; chmod 755 dist/jget
[ "$(dist/jget --version)" = "jget $V" ] || { echo "release: dist/jget says $(dist/jget --version), VERSION says $V"; exit 1; }
( cd dist && sha256sum jget > SHA256SUMS && ls -l )
