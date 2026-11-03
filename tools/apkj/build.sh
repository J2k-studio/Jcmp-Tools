#!/bin/sh
# builds apkj into _out/apkj: the zip code is the one of zipj (../zipj/zipcore.j)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" -I ../zipj apkj.jk -o _out/apkj
echo "built _out/apkj"
