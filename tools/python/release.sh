#!/bin/sh
# release.sh JCMP ANDROID_TARBALL [CERT_PEM] : the tool python of Jcmp-Tools
#   dist/python (the launcher, python.jk built with -dyn), dist/python-files.tar (the folder python-android: the Python of the
#   Android build of python.org without its tests, idle, tkinter and C headers; etc/cert.pem), dist/SHA256SUMS.
#   ANDROID_TARBALL = python-3.14.0-aarch64-linux-android.tar.gz from https://www.python.org/ftp/python/3.14.0/
#   Then: gh release create python-vX.Y.Z dist/* --repo J2k-studio/Jcmp-Tools --title ...
set -eu
cd "$(dirname "$0")"
JCMP=$1; TARBALL=$2; CERT=${3:-/data/data/com.termux/files/usr/etc/tls/cert.pem}
export J2K_PATH="${J2K_PATH:-$HOME/Jaric-Engine/libs}"      # the library native (jc lib install native)
rm -rf dist _work; mkdir dist _work
"$JCMP" python.jk -dyn -o dist/python
tar xzf "$TARBALL" -C _work
mkdir -p _work/python-android/etc
cp -r _work/prefix/lib _work/python-android/lib
cp "$CERT" _work/python-android/etc/cert.pem
P=_work/python-android/lib/python3.14
rm -rf "$P/test" "$P/idlelib" "$P/tkinter" "$P/turtledemo" "$P/turtle.py" "$P/config-3.14-aarch64-linux-android" _work/python-android/lib/pkgconfig
find _work/python-android -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
for n in python3 pip pip3; do cp dist/python "_work/$n"; done            # the same launcher under other names (python3, pip = python -m pip)
tar cf dist/python-files.tar -C _work python-android python3 pip pip3      # plain tar: jget unpacks tars itself and does not read gzip yet
rm -rf _work
( cd dist && sha256sum python python-files.tar > SHA256SUMS && ls -l )
