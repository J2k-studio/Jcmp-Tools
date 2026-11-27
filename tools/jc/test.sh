#!/bin/sh
# jc is the same program as ex (its own tests are in ../ex): here only that it builds and answers with the version of ex
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jc --version)" = "ex $(cat VERSION)" ] || { echo "jc test: --version differs from VERSION"; exit 1; }
[ "$(cat VERSION)" = "$(cat ../ex/VERSION)" ] || { echo "jc test: jc and ex must have one version"; exit 1; }
echo "jc test: ok"
