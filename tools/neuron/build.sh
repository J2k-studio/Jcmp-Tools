#!/bin/sh
# builds neuron into _out/neuron (needs jcmp 1.1.0.0 or newer; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}" "${JCMP:-jcmp}" neuron.jk -o _out/neuron
echo "built _out/neuron"
