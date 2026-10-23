#!/bin/sh
# install-neuron.sh -- install neuron only (the same as  install.sh neuron):
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install-neuron.sh | sh
#   (options after `sh -s --`:  --dir DIR   --version X.Y.Z)
set -eu
RAW="${JCMPTOOLS_RAW:-https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main}"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW/install.sh" | sh -s -- neuron "$@"; else wget -qO- "$RAW/install.sh" | sh -s -- neuron "$@"; fi
