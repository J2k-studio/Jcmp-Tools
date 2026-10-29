#!/bin/sh
# install-mulap.sh -- install mulap only (the same as  install.sh mulap):
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install-mulap.sh | sh
#   (options after `sh -s --`:  --dir DIR   --version X.Y.Z)
set -eu
RAW="${JCMPTOOLS_RAW:-https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main}"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW/install.sh" | sh -s -- mulap "$@"; else wget -qO- "$RAW/install.sh" | sh -s -- mulap "$@"; fi
