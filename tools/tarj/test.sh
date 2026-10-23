#!/bin/sh
# tarj and gzj: archives made here are read by tar, archives made by tar are read here; gzip both ways
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
Z="$PWD/_out/tarj"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
ln -s "$Z" tarj; ln -s "$Z" gzj
mkdir -p src/sub
echo "hello tar hello tar" > src/a.txt
head -c 30000 /dev/urandom > src/sub/rand.bin
seq 1 3000 > src/sub/nums.txt
printf '#!/bin/sh\necho run\n' > src/run.sh; chmod 755 src/run.sh
./tarj c out.tar src > /dev/null
tar tf out.tar | grep -q src/sub/nums.txt || { echo "tarj test: tar cannot read our tar"; exit 1; }
mkdir r1; ( cd r1 && tar xf ../out.tar && cmp src/sub/rand.bin ../src/sub/rand.bin && [ -x src/run.sh ] ) || { echo "tarj test: tar extract of our tar"; exit 1; }
./tarj c out.tar.gz src -q
gzip -t out.tar.gz || { echo "tarj test: gzip rejects our .tar.gz"; exit 1; }
mkdir r2; ( cd r2 && tar xzf ../out.tar.gz && cmp src/sub/nums.txt ../src/sub/nums.txt ) || { echo "tarj test: tar xzf"; exit 1; }
mkdir r3; ./tarj x out.tar.gz -o r3 -q; cmp r3/src/sub/rand.bin src/sub/rand.bin || { echo "tarj test: tarj x of .tar.gz"; exit 1; }
[ -x r3/src/run.sh ] || { echo "tarj test: the mode is kept"; exit 1; }
tar cf gnu.tar src; mkdir r4; ./tarj x gnu.tar -o r4 -q; cmp r4/src/sub/nums.txt src/sub/nums.txt || { echo "tarj test: a tar made by tar"; exit 1; }
tar czf gnu.tgz src; mkdir r5; ./tarj x gnu.tgz -o r5 -q; cmp r5/src/a.txt src/a.txt || { echo "tarj test: a .tgz made by tar"; exit 1; }
[ "$(./tarj t gnu.tar | wc -l)" = "$(tar tf gnu.tar | wc -l)" ] || { echo "tarj test: t lists the same"; exit 1; }
D=$(printf 'd%.0s' $(seq 1 60)); mkdir -p "src/$D/$D"; echo deep > "src/$D/$D/f.txt"
./tarj c long.tar src -q; tar tf long.tar | grep -q "f.txt" || { echo "tarj test: long names"; exit 1; }
mkdir r6; ./tarj x long.tar -o r6 -q; [ -f "r6/src/$D/$D/f.txt" ] || { echo "tarj test: long names back"; exit 1; }
tar cf pax.tar --format=pax "src/$D/$D/f.txt"; mkdir r7; ./tarj x pax.tar -o r7 -q; [ -f "r7/src/$D/$D/f.txt" ] || { echo "tarj test: pax names"; exit 1; }
cp src/sub/nums.txt n.txt; ./gzj -k n.txt; gzip -t n.txt.gz; rm n.txt; ./gzj -d n.txt.gz; cmp n.txt src/sub/nums.txt || { echo "gzj test: round trip"; exit 1; }
gzip -k n.txt -c > g.gz; rm n.txt; ./gzj -d g.gz; cmp g src/sub/nums.txt || { echo "gzj test: gzip file"; exit 1; }
./gzj -c src/a.txt | gzip -dc | grep -q "hello tar" || { echo "gzj test: -c"; exit 1; }
echo "tarj tests: ok"
