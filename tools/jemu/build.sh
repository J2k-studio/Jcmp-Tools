#!/bin/sh
# builds jemu, its kernel (kernel.jk, the console of Jaric OS) and its disk maker (mkfs.jk) into _out/ (needs a jcmp that has the fix "functions with a value in a #!library file": the dev compiler of Jcmp after 1.2.0.0; JCMP=path chooses it)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jemu.jk -o _out/jemu
"${JCMP:-jcmp}" kernel.jk -o _out/jemu-kernel
"${JCMP:-jcmp}" mkfs.jk -o _out/jemu-mkfs
echo "built _out/jemu _out/jemu-kernel _out/jemu-mkfs"
