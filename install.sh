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
        W="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"; [ "$W" -ge 40 ] 2>/dev/null || W=80
        TRY=0
        while [ "$TRY" -lt 3 ] && [ -z "${NAMES# }" ]; do
            TRY=$((TRY+1))
            echo "Jcmp-Tools:" > /dev/tty
            i=1
            # one short line per tool: the name and the text up to the first ':' or '(' , cut to the width of the screen
            grep -v '^#' "$TMP/tools.txt" | while IFS='|' read -r n d; do
                d="$(echo "$d" | sed 's/ *[:(].*//' | cut -c1-$((W-16)))"
                printf '%3d) %-8s %s\n' "$i" "$n" "$d" > /dev/tty; i=$((i+1))
            done
            printf '  a) all   q) quit      numbers or names, e.g. 1 3 mujic   [Enter = 1] ? ' > /dev/tty
            read -r ANSWER < /dev/tty || ANSWER=""
            case "$ANSWER" in
                q|Q) echo "nothing installed"; exit 0 ;;
                a|A|all) NAMES="$ALLNAMES" ;;
                "") NAMES="$(echo "$ALLNAMES" | head -1)" ;;
                *) PICK=""; BAD=""
                   for w in $ANSWER; do
                       case "$w" in
                           *[!0-9]*) if echo "$ALLNAMES" | grep -qx "$w"; then PICK="$PICK $w"; else BAD="$BAD $w"; fi ;;
                           *) T="$(echo "$ALLNAMES" | sed -n "${w}p")"; if [ -n "$T" ]; then PICK="$PICK $T"; else BAD="$BAD $w"; fi ;;
                       esac
                   done
                   if [ -n "$BAD" ]; then echo "not a tool:$BAD  (type the number or the name from the list)" > /dev/tty; else NAMES="$PICK"; fi ;;
            esac
        done
        [ -n "${NAMES# }" ] || { echo "install: nothing chosen; run again, or  install.sh jget mujic"; exit 1; }
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
    case "$N" in jbox|zipj|tarj) "$BINDIR/$N" --install "$BINDIR" 2>/dev/null || true ;; esac
    # the files that belong to the tool (the library of the compiler): NAME-files.tar, when the release has it
    FW="$(grep " $N-files.tar\$" "$TMP/SHA256SUMS.$N" | cut -d' ' -f1 || true)"
    if [ -n "$FW" ]; then
        fetch "$BASE/$N-files.tar" "$TMP/$N-files.tar"
        [ "$(sha256sum "$TMP/$N-files.tar" | cut -d' ' -f1)" = "$FW" ] || { echo "install: the checksum of the files of $N does not match"; exit 1; }
        tar xf "$TMP/$N-files.tar" -C "$BINDIR"
        echo "installed the files of $N in $BINDIR"
    fi      # jbox links its commands (dir cat cp ...) next to itself
done
case ":$PATH:" in *":$BINDIR:"*) ;; *) echo "add the folder to your PATH:  export PATH=\"$BINDIR:\$PATH\"" ;; esac
