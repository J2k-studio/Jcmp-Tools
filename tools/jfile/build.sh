#!/bin/sh
# builds jfile into _out/jfile (needs jcmp 1.2.2.0 or newer and the libraries deflate and png; JCMP=path chooses the compiler)
set -eu
cd "$(dirname "$0")"
mkdir -p _out
"${JCMP:-jcmp}" jfile.jk -o _out/jfile
echo "built _out/jfile"
