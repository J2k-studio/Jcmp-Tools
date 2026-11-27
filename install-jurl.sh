#!/bin/sh
# install-jurl.sh -- install jurl only (the same as  install.sh jurl):
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install-jurl.sh | sh
#   (options after `sh -s --`:  --dir DIR   --version X.Y.Z)
set -eu
RAW="${JCMPTOOLS_RAW:-https://raw.githubusercontent.com/J2k-studio/ex-pkg/main}"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW/install.sh" | sh -s -- jurl "$@"; else wget -qO- "$RAW/install.sh" | sh -s -- jurl "$@"; fi
