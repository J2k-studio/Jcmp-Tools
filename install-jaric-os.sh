#!/bin/sh
# install-jaric-os.sh -- install jaric-os only (the same as  install.sh jaric-os):
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install-jaric-os.sh | sh
#   (options after `sh -s --`:  --dir DIR   --version X.Y.Z)
set -eu
RAW="${JCMPTOOLS_RAW:-https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main}"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW/install.sh" | sh -s -- jaric-os "$@"; else wget -qO- "$RAW/install.sh" | sh -s -- jaric-os "$@"; fi
