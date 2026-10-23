#!/bin/sh
# zipj and unj: zips made here are read by Python and by unj, zips made by Python are read by unj, passwords, -f, -o
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/zipj --version)" = "zipj $(cat VERSION)" ] || { echo "zipj test: --version differs from VERSION"; exit 1; }
Z="$PWD/_out/zipj"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
ln -s "$Z" zipj; ln -s "$Z" unj
mkdir -p src/sub
echo "hello zip hello zip hello zip" > src/a.txt
head -c 20000 /dev/urandom > src/sub/rand.bin
seq 1 3000 > src/sub/nums.txt
./zipj out.zip src > /dev/null
python3 -c "
import zipfile;z=zipfile.ZipFile('out.zip');assert z.testzip() is None;assert len(z.namelist())==5"  || { echo "zipj test: python cannot read our zip"; exit 1; }
mkdir r1; ( cd r1 && ../unj ../out.zip > /dev/null && cmp src/sub/rand.bin ../src/sub/rand.bin && cmp src/sub/nums.txt ../src/sub/nums.txt ) || { echo "zipj test: unj of our zip"; exit 1; }
mkdir r2; ( cd r2 && ../unj ../out.zip -f > /dev/null && [ -f out/src/a.txt ] ) || { echo "zipj test: -f makes a folder named like the zip"; exit 1; }
mkdir r3; ( cd r3 && ../unj ../out.zip -o dest > /dev/null && [ -f dest/src/a.txt ] ) || { echo "zipj test: -o"; exit 1; }
python3 -c "
import zipfile
z=zipfile.ZipFile('py.zip','w',zipfile.ZIP_DEFLATED);z.write('src/sub/nums.txt');z.write('src/a.txt');z.close()"
mkdir r4; ( cd r4 && ../unj ../py.zip > /dev/null && cmp src/sub/nums.txt ../src/sub/nums.txt ) || { echo "zipj test: a zip made by Python"; exit 1; }
./zipj enc.zip src/a.txt -P secret > /dev/null
python3 -c "
import zipfile;z=zipfile.ZipFile('enc.zip');assert z.read('src/a.txt',pwd=b'secret').startswith(b'hello zip')" || { echo "zipj test: python reads our password"; exit 1; }
mkdir r5; ( cd r5 && ../unj ../enc.zip -p secret > /dev/null && grep -q hello src/a.txt ) || { echo "zipj test: password"; exit 1; }
if ( cd r5 && ../unj ../enc.zip -p wrong -o w > /dev/null 2>&1 < /dev/null ); then echo "zipj test: a wrong password must fail"; exit 1; fi
mkdir r6; ( cd r6 && echo secret | ../unj ../enc.zip -o p > /dev/null 2>&1 && grep -q hello p/src/a.txt ) || { echo "zipj test: the password is asked"; exit 1; }
printf 'gz test line\n' > g.txt; gzip -k g.txt
mkdir r7; ( cd r7 && ../unj ../g.txt.gz > /dev/null && grep -q 'gz test' g.txt ) || { echo "zipj test: gz"; exit 1; }
echo "zipj tests: ok"
