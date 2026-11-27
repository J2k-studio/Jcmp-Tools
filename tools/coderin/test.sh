#!/bin/sh
# coderin is the same program as fcode (its tests are in ../fcode): here only that it builds and answers with the version of fcode
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/coderin --version)" = "fcode $(cat VERSION)" ] || { echo "coderin test: --version differs from VERSION"; exit 1; }
[ "$(cat VERSION)" = "$(cat ../fcode/VERSION)" ] || { echo "coderin test: coderin and fcode must have one version"; exit 1; }
echo "coderin test: ok"
