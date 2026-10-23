#!/bin/sh
# install-jvp4.sh -- install jvp4 only (the same as  install.sh jvp4):
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install-jvp4.sh | sh
#   (options after `sh -s --`:  --dir DIR   --version X.Y.Z)
set -eu
RAW="${JCMPTOOLS_RAW:-https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main}"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW/install.sh" | sh -s -- jvp4 "$@"; else wget -qO- "$RAW/install.sh" | sh -s -- jvp4 "$@"; fi
