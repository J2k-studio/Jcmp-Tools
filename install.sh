#!/bin/sh
# install.sh -- download jget from the latest release of github.com/J2k-studio/Jget, check its SHA-256 and put it in a folder.
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jget/main/install.sh | sh
# Options (after `sh -s --` when the script comes through a pipe):  --dir DIR   the folder (default: $PREFIX/bin on Termux, else ~/.local/bin)
#                                                                   --version X.Y.Z   a specific release
# Environment: JGET_BASE=URL to download from another place (a mirror, or file:///folder).
set -eu
REPO="J2k-studio/Jget"
BINDIR=""
VERSION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --dir) [ $# -ge 2 ] || { echo "install: --dir needs a folder"; exit 1; }; BINDIR="$2"; shift 2 ;;
        --version) [ $# -ge 2 ] || { echo "install: --version needs a number"; exit 1; }; VERSION="$2"; shift 2 ;;
        *) echo "install: unknown option '$1'"; exit 1 ;;
    esac
done
case "$(uname -m)" in aarch64|arm64) ;; *) echo "install: jget is made for Linux ARM64 (this machine is $(uname -m))"; exit 1 ;; esac
fetch() { if command -v curl >/dev/null 2>&1; then curl -fsSL -o "$2" "$1"; elif command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"; else echo "install: curl or wget is needed"; exit 1; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if [ -n "${JGET_BASE:-}" ]; then BASE="$JGET_BASE"
elif [ -n "$VERSION" ]; then BASE="https://github.com/$REPO/releases/download/v$VERSION"
else BASE="https://github.com/$REPO/releases/latest/download"; fi
if [ -z "$BINDIR" ]; then if [ -n "${PREFIX:-}" ]; then BINDIR="$PREFIX/bin"; else BINDIR="$HOME/.local/bin"; fi; fi
mkdir -p "$BINDIR"; BINDIR="$(cd "$BINDIR" && pwd)"
echo "downloading from $BASE ..."
fetch "$BASE/SHA256SUMS" "$TMP/SHA256SUMS"
fetch "$BASE/jget" "$TMP/jget"
WANT="$(grep " jget\$" "$TMP/SHA256SUMS" | cut -d' ' -f1)"
HAVE="$(sha256sum "$TMP/jget" | cut -d' ' -f1)"
[ -n "$WANT" ] && [ "$WANT" = "$HAVE" ] || { echo "install: the checksum of jget does not match, nothing installed"; exit 1; }
cp "$TMP/jget" "$BINDIR/.jget.new"; chmod +x "$BINDIR/.jget.new"; mv -f "$BINDIR/.jget.new" "$BINDIR/jget"
echo "installed: $BINDIR/jget  ($("$BINDIR/jget" --version))"
case ":$PATH:" in *":$BINDIR:"*) ;; *) echo "add the folder to your PATH:  export PATH=\"$BINDIR:\$PATH\"" ;; esac
