#!/bin/sh
# release.sh JCMP LIBRARY_FOLDER VERSION : the compiler of a release of github.com/J2k-studio/Jcmp as a tool of Jcmp-Tools:
#   dist/jcmp (the program), dist/jcmp-files.tar (its folder Library, the pair of the compiler) and SHA256SUMS.
#   Then: gh release create jcmp-vX.Y.Z.W dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
JCMP=$1; LIB=$2; VER=$3
[ "$("$JCMP" -version | cut -d' ' -f2)" = "$VER" ] || { echo "release: $JCMP is not jcmp $VER"; exit 1; }
[ "$(cat "$LIB/VERSION")" = "$VER" ] || { echo "release: the library is not $VER"; exit 1; }
rm -rf dist; mkdir dist
cp "$JCMP" dist/jcmp
( cd "$(dirname "$LIB")" && tar cf "$OLDPWD/dist/jcmp-files.tar" "$(basename "$LIB")" )
echo "$VER" > VERSION; echo "$VER" > LATEST
( cd dist && sha256sum jcmp jcmp-files.tar > SHA256SUMS && ls -l )
