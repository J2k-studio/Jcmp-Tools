#!/bin/sh
# build.sh: writes dist/makej, the whole tool in one file (the library inside)
set -eu
cd "$(dirname "$0")"
V=$(cat VERSION)
mkdir -p dist
python3 - "$V" <<'PY'
import sys
v=sys.argv[1]
t=open('makej.sh.in').read()
t=t.replace('@VERSION@',v).replace('@LIB_J@',open('lib/makej.j').read().rstrip('\n')).replace('@LIB_JK@',open('lib/makej_file.jk').read().rstrip('\n')).replace('@GAMEACTIVITY@',open('android/GameActivity.java').read().rstrip('\n')).replace('@GAMELIB@',open('android/GameLib.java').read().rstrip('\n')).replace('@GLGAMEACTIVITY@',open('android/GlGameActivity.java').read().rstrip('\n'))
open('dist/makej','w').write(t)
PY
chmod 755 dist/makej
