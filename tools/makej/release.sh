#!/bin/sh
# release.sh [JCMP]: test, build dist/makej and write SHA256SUMS. Then: gh release create makej-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
JCMP=${1:-jcmp}
sh ./test.sh "$JCMP" > "${TMPDIR:-/tmp}/makej_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/makej_test.txt"; echo "release: the tests fail"; exit 1; }
( cd dist && sha256sum makej > SHA256SUMS && ls -l )
