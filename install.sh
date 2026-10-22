#!/bin/sh
# install.sh -- install tools of Jcmp-Tools (github.com/J2k-studio/Jcmp-Tools): each is one file, checked with its SHA-256 before it is put in a folder.
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh                 asks which tools (a menu), or installs jget when there is no terminal
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s -- jget        the tools you name
#   curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s -- --all       every tool
# Options:  --dir DIR   the folder (default: $PREFIX/bin on Termux, else ~/.local/bin)      --version X.Y.Z   a version of the tool(s) named (one tool)
#           --list      the tools and what they are                                          --yes   never ask (install jget when no tool is named)
# One tool at a time: install-NAME.sh (install-jget.sh) does the same as  install.sh NAME.
# Environment for tests and mirrors: JCMPTOOLS_RAW=URL (the files of the repository), JCMPTOOLS_DL=URL (the folders NAME-vX.Y.Z of the releases; file:///folder works).
set -eu
REPO="J2k-studio/Jcmp-Tools"
RAW="${JCMPTOOLS_RAW:-https://raw.githubusercontent.com/$REPO/main}"
DL="${JCMPTOOLS_DL:-https://github.com/$REPO/releases/download}"
BINDIR=""; VERSION=""; ALL=0; LIST=0; YES=0; NAMES=""
while [ $# -gt 0 ]; do
    case "$1" in
        --dir) [ $# -ge 2 ] || { echo "install: --dir needs a folder"; exit 1; }; BINDIR="$2"; shift 2 ;;
        --version) [ $# -ge 2 ] || { echo "install: --version needs a number"; exit 1; }; VERSION="$2"; shift 2 ;;
        --all) ALL=1; shift ;;
        --list) LIST=1; shift ;;
        --yes|-y) YES=1; shift ;;
        -*) echo "install: unknown option '$1'"; exit 1 ;;
        *) NAMES="$NAMES $1"; shift ;;
    esac
done
case "$(uname -m)" in aarch64|arm64) ;; *) echo "install: the tools are made for Linux ARM64 (this machine is $(uname -m))"; exit 1 ;; esac
fetch() { if command -v curl >/dev/null 2>&1; then curl -fsSL -o "$2" "$1"; elif command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"; else echo "install: curl or wget is needed"; exit 1; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fetch "$RAW/tools.txt" "$TMP/tools.txt" || { echo "install: cannot read the list of tools"; exit 1; }
ALLNAMES="$(grep -v '^#' "$TMP/tools.txt" | cut -d'|' -f1)"
if [ "$LIST" = 1 ]; then grep -v '^#' "$TMP/tools.txt" | while IFS='|' read -r n d; do printf '  %-10s %s\n' "$n" "$d"; done; exit 0; fi
if [ "$ALL" = 1 ]; then NAMES="$ALLNAMES"; fi
if [ -z "${NAMES# }" ]; then
    if [ "$YES" = 0 ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
        echo "Tools of Jcmp-Tools:" > /dev/tty
        i=1
        grep -v '^#' "$TMP/tools.txt" | while IFS='|' read -r n d; do printf '  %d) %-10s %s\n' "$i" "$n" "$d" > /dev/tty; i=$((i+1)); done
        printf '  a) all     q) quit\nWhich ones (numbers or names, spaces between; Enter = 1)? ' > /dev/tty
        read -r ANSWER < /dev/tty || ANSWER=""
        case "$ANSWER" in
            q|Q) echo "nothing installed"; exit 0 ;;
            a|A|all) NAMES="$ALLNAMES" ;;
            "") NAMES="$(echo "$ALLNAMES" | head -1)" ;;
            *) for w in $ANSWER; do
                   case "$w" in
                       *[!0-9]*) NAMES="$NAMES $w" ;;
                       *) NAMES="$NAMES $(echo "$ALLNAMES" | sed -n "${w}p")" ;;
                   esac
               done ;;
        esac
    else
        NAMES="$(echo "$ALLNAMES" | head -1)"
    fi
fi
if [ -z "$BINDIR" ]; then if [ -n "${PREFIX:-}" ]; then BINDIR="$PREFIX/bin"; else BINDIR="$HOME/.local/bin"; fi; fi
mkdir -p "$BINDIR"; BINDIR="$(cd "$BINDIR" && pwd)"
COUNT=0; for n in $NAMES; do COUNT=$((COUNT+1)); done
if [ -n "$VERSION" ] && [ "$COUNT" != 1 ]; then echo "install: --version needs exactly one tool"; exit 1; fi
for N in $NAMES; do
    echo "$ALLNAMES" | grep -qx "$N" || { echo "install: there is no tool '$N' (install.sh --list shows them)"; exit 1; }
    V="$VERSION"
    if [ -z "$V" ]; then fetch "$RAW/tools/$N/LATEST" "$TMP/LATEST.$N" || { echo "install: cannot find the newest version of $N"; exit 1; }; V="$(tr -d ' \n\r' < "$TMP/LATEST.$N")"; fi
    BASE="$DL/$N-v$V"
    echo "downloading $N $V from $BASE ..."
    fetch "$BASE/SHA256SUMS" "$TMP/SHA256SUMS.$N"
    fetch "$BASE/$N" "$TMP/$N"
    WANT="$(grep " $N\$" "$TMP/SHA256SUMS.$N" | cut -d' ' -f1)"
    HAVE="$(sha256sum "$TMP/$N" | cut -d' ' -f1)"
    [ -n "$WANT" ] && [ "$WANT" = "$HAVE" ] || { echo "install: the checksum of $N does not match, nothing installed"; exit 1; }
    cp "$TMP/$N" "$BINDIR/.$N.new"; chmod +x "$BINDIR/.$N.new"; mv -f "$BINDIR/.$N.new" "$BINDIR/$N"
    echo "installed: $BINDIR/$N  ($("$BINDIR/$N" --version 2>/dev/null | head -1))"
    case "$N" in jbox) "$BINDIR/jbox" --install "$BINDIR" 2>/dev/null || true ;; esac      # jbox links its commands (dir cat cp ...) next to itself
done
case ":$PATH:" in *":$BINDIR:"*) ;; *) echo "add the folder to your PATH:  export PATH=\"$BINDIR:\$PATH\"" ;; esac
