#!/bin/sh
# builds jemu, its kernel (kernel.jk, the console of Jaric OS) and its disk maker (mkfs.jk) into _out/ (needs a jcmp that has the fix "functions with a value in a #!library file": the dev compiler of Jcmp after 1.2.0.0; JCMP=path chooses it)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jaric-os.jk -o _out/jaric-os
"${JCMP:-jcmp}" kernel.jk -o _out/jaric-os-kernel
"${JCMP:-jcmp}" mkfs.jk -o _out/jaric-os-mkfs
"${JCMP:-jcmp}" boot.jk -o _out/jaric-os-boot
cp jaric-os-font _out/jaric-os-font
echo "built _out/jaric-os _out/jaric-os-kernel _out/jaric-os-mkfs _out/jaric-os-boot"
