#!/bin/sh
# release.sh [JCMP]: test, build dist/neuron and write SHA256SUMS. Then: gh release create neuron-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
export JCMP=${1:-${JCMP:-jcmp}}
sh ./test.sh > "${TMPDIR:-/tmp}/neuron_test.txt" 2>&1 || { tail -5 "${TMPDIR:-/tmp}/neuron_test.txt"; echo "release: the tests fail"; exit 1; }
rm -rf dist; mkdir dist
cp _out/neuron dist/neuron
# the same program under the names xr and xaiorin (the assistant): they come with the files of the tool
mkdir -p _work; cp _out/neuron _work/xr; cp _out/neuron _work/xaiorin; chmod 755 _work/xr _work/xaiorin
tar cf dist/neuron-files.tar -C _work xr xaiorin; rm -rf _work
( cd dist && sha256sum neuron neuron-files.tar > SHA256SUMS && ls -l )
