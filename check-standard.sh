#!/bin/sh
# check-standard.sh [NAME...]: every tool of tools/ is checked against docs/STANDARD.md. Prints a line for each thing that is wrong;
# the exit code is the number of tools with problems. Run it before a release (and it is run by the tests of the repository).
cd "$(dirname "$0")" || exit 1
WAIVE_BUILD="jcmp python yt-dlp"          # tools that are made from other things (no build.sh / test.sh of their own)
OTHERS="python yt-dlp jcmp"                # programs that are not ours: their --version is their own (no check of dist)
bad=0
names="$*"
all=0; [ -n "$names" ] || all=1
[ -n "$names" ] || names=$(ls tools)
for n in $names; do
    case "$n" in _*) continue ;; esac
    d="tools/$n"; [ -d "$d" ] || continue
    err=""
    add() { err="$err\n  $n: $1"; }
    for f in README.md CHANGELOG.md VERSION LATEST; do [ -f "$d/$f" ] || add "missing $f"; done
    case " $WAIVE_BUILD " in *" $n "*) ;; *) for f in build.sh test.sh release.sh; do [ -f "$d/$f" ] || add "missing $f"; done ;; esac
    ver=$(cat "$d/VERSION" 2>/dev/null | tr -d ' \n')
    [ -n "$ver" ] || add "VERSION is empty"
    [ "$(cat "$d/LATEST" 2>/dev/null | tr -d ' \n')" = "$ver" ] || add "LATEST is not the same as VERSION ($ver)"
    top=$(grep -m1 '^## ' "$d/CHANGELOG.md" 2>/dev/null | sed 's/^## *//; s/ .*//')
    [ "$top" = "$ver" ] || add "the newest section of CHANGELOG.md is '$top', VERSION is '$ver'"
    if [ -f "$d/README.md" ]; then
        grep -q '^## Install' "$d/README.md" || add "README.md has no section '## Install'"
        grep -q "jc install .*$n" "$d/README.md" || add "README.md does not show  jc install $n"
        grep -q "install.sh | sh -s .*$n" "$d/README.md" || add "README.md does not show the curl install of $n"
        grep -q '^## A short lesson' "$d/README.md" || add "README.md has no section '## A short lesson'"
        # a tool with several commands needs a guide: a section '## Commands' or a file docs/GUIDE.md (only a note for now: the older tools are being written)
        if ! grep -q '^## Commands' "$d/README.md" && [ ! -f "$d/docs/GUIDE.md" ]; then echo "note  $n: no '## Commands' section and no docs/GUIDE.md (every command and option with an example)"; fi
        grep -qi 'license' "$d/README.md" || add "README.md does not name the license"
    fi
    grep -q "^$n|" tools.txt || add "not in tools.txt"
    [ -f "install-$n.sh" ] || add "no install-$n.sh"
    grep -q "(tools/$n/README.md)" README.md || add "not in the table of README.md"
    # the program itself, when it is built: --version says NAME X.Y.Z and --help works without a terminal
    if [ -x "$d/dist/$n" ] && ! echo " $OTHERS " | grep -q " $n "; then
        v=$("$d/dist/$n" --version 2>/dev/null | head -n 1)
        [ "$v" = "$n $ver" ] || add "dist/$n --version says '$v', wanted '$n $ver'"
        "$d/dist/$n" --help > /dev/null 2>&1 < /dev/null || add "dist/$n --help does not exit 0"
    fi
    if [ -n "$err" ]; then bad=$((bad+1)); printf "%b\n" "$err"; else echo "ok   $n $ver"; fi
done
# versions.txt (NAME VERSION per line): what  jc update  compares with; written when every tool was checked
if [ "$all" = 1 ]; then
    for n in $(ls tools); do case "$n" in _*) continue ;; esac; [ -f "tools/$n/VERSION" ] && echo "$n $(tr -d ' \n' < tools/$n/VERSION)"; done > versions.txt
fi
exit $bad
