#!/bin/sh
# install-jash.sh -- install jash only (the same as  install.sh jash):
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install-jash.sh | sh
#   (options after `sh -s --`:  --dir DIR   --version X.Y.Z)
set -eu
RAW="${JCMPTOOLS_RAW:-https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main}"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW/install.sh" | sh -s -- jash "$@"; else wget -qO- "$RAW/install.sh" | sh -s -- jash "$@"; fi
