#!/bin/sh
# ex: info, install (asks for the permissions; -y gives them; no terminal = refuse), run (JC_PERMS, JC_ASSETS), list, perm, remove, bad packages
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/ex"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export JC_ROOT="$T/root"
python3 - "$T" <<'PY'
import sys, zipfile
t = sys.argv[1]
def make(name, manifest, extra=None):
    z = zipfile.ZipFile(t + '/' + name, 'w', zipfile.ZIP_DEFLATED)
    z.writestr('manifest.toml', manifest)
    z.writestr('hello', "#!/bin/sh\necho \"hello perms=$JC_PERMS assets=$(ls $JC_ASSETS) home=$(basename $JC_HOME) args=$*\"\n")
    z.writestr('assets/logo.txt', 'logo')
    for n, d in (extra or {}).items(): z.writestr(n, d)
    z.close()
make('game.jc', 'name = "My Game"\nid = "game.mygame"\nversion = "1.0.0"\ntype = "game"\nentry = "hello"\npermissions = ["files", "audio"]\n')
make('plain.jc', 'name = "Plain"\nid = "plain.one"\nversion = "2"\nentry = "hello"\npermissions = []\n')
make('bad.jc', 'name = "Bad"\nid = "bad.one"\nversion = "1"\nentry = "hello"\npermissions = ["files", "rootkit"]\n')
make('noentry.jc', 'name = "X"\nid = "x.one"\nversion = "1"\nentry = "missing"\npermissions = []\n')
make('evil.jc', 'name = "Evil"\nid = "evil.one"\nversion = "1"\nentry = "hello"\npermissions = []\n', {'../escape.txt': 'x'})
open(t + '/notzip.jc', 'w').write('this is not a zip')
PY
[ "$("$J" --version)" = "ex $(cat VERSION)" ] || { echo "ex test: version"; exit 1; }
"$J" info "$T/game.jc" | grep -q "permissions:  files,audio" || { echo "ex test: info"; exit 1; }
"$J" info "$T/notzip.jc" > /dev/null 2>&1 && { echo "ex test: a file that is not a zip must fail"; exit 1; }
"$J" install "$T/game.jc" > /dev/null 2>&1 && { echo "ex test: permissions without a terminal and without -y must be refused"; exit 1; }
"$J" install "$T/plain.jc" > /dev/null || { echo "ex test: a package without permissions installs without asking"; exit 1; }
"$J" install "$T/game.jc" -y > /dev/null || { echo "ex test: install -y"; exit 1; }
"$J" list | grep -q "game.mygame  1.0.0  My Game   permissions: files,audio" || { echo "ex test: list"; exit 1; }
out=$("$J" run game.mygame a b)
[ "$out" = "hello perms=files,audio assets=logo.txt home=game.mygame args=a b" ] || { echo "ex test: run said: $out"; exit 1; }
"$J" perm game.mygame network on > /dev/null; "$J" run game.mygame | grep -q "perms=files,audio,network" || { echo "ex test: perm on"; exit 1; }
"$J" perm game.mygame audio off > /dev/null; "$J" run game.mygame | grep -q "perms=files,network " || { echo "ex test: perm off"; exit 1; }
"$J" perm game.mygame rootkit on > /dev/null 2>&1 && { echo "ex test: an unknown permission must be refused"; exit 1; }
"$J" install "$T/bad.jc" -y > /dev/null 2>&1 && { echo "ex test: an unknown permission in a manifest must be refused"; exit 1; }
"$J" install "$T/noentry.jc" -y > /dev/null 2>&1 && { echo "ex test: a missing entry must be refused"; exit 1; }
"$J" install "$T/evil.jc" -y > /dev/null 2>&1; [ ! -e "$T/escape.txt" ] && [ ! -e "$T/root/escape.txt" ] && [ ! -e "$T/root/apps/escape.txt" ] || { echo "ex test: a name with .. must be skipped"; exit 1; }
"$J" run "$T/game.jc" x | grep -q "args=x" || { echo "ex test: run of a package file"; exit 1; }
"$J" remove game.mygame > /dev/null; "$J" list | grep -q "game.mygame" && { echo "ex test: remove"; exit 1; }
"$J" run game.mygame > /dev/null 2>&1 && { echo "ex test: run of a removed program"; exit 1; }
# tools: jc installs them itself (a mirror on this machine: JCMPTOOLS_RAW / JCMPTOOLS_DL); STORE.ID goes to jstore (a fake program on the PATH records its words)
M="$T/mirror"; mkdir -p "$M/tools/foo" "$M/dl/foo-v1.0.0" "$T/tb" "$T/fb"
printf '# tools\nfoo|a tool\n' > "$M/tools.txt"; echo 1.0.0 > "$M/tools/foo/LATEST"
printf '#!/bin/sh\necho "foo 1.0.0"\n' > "$M/dl/foo-v1.0.0/foo"; ( cd "$M/dl/foo-v1.0.0" && sha256sum foo > SHA256SUMS )
cp "$J" "$T/tb/ex"
TE="JCMPTOOLS_RAW=file://$M JCMPTOOLS_DL=file://$M/dl"
( cd "$T/tb" && env $TE ./ex install foo >/dev/null 2>&1 ); [ "$("$T/tb/foo")" = "foo 1.0.0" ] || { echo "ex test: jc install foo"; exit 1; }
( cd "$T/tb" && env $TE ./ex tools ) | grep -q "foo" || { echo "ex test: jc tools"; exit 1; }
( cd "$T/tb" && env $TE ./ex unstall foo >/dev/null 2>&1 ); [ ! -e "$T/tb/foo" ] || { echo "ex test: jc unstall foo"; exit 1; }
( cd "$T/tb" && env $TE ./ex unstall ex >/dev/null 2>&1 ) && { echo "ex test: ex must not remove itself"; exit 1; }
[ -e "$T/tb/ex" ] || { echo "ex test: ex is gone"; exit 1; }
printf '#!/bin/sh\necho "jstore $*" >> "$FAKELOG"\n' > "$T/fb/jstore"; chmod 755 "$T/fb/jstore"
FAKELOG="$T/fake.log"; export FAKELOG; : > "$FAKELOG"
PATH="$T/fb:$PATH" "$J" install store.hello
[ "$(cat "$FAKELOG")" = "jstore install store.hello" ] || { echo "ex test: a program of the store goes to jstore:"; cat "$FAKELOG"; exit 1; }

# jc pkg: packages of ex-pkg (a .tar.gz of usr/ with links, an index.json with a dependency), install, list, search, remove, bad checksum
python3 - "$T" <<'PY'
import sys, io, tarfile, hashlib, json, os
t = sys.argv[1]
def pack(name, files, links=(), hard=()):
    p = t + '/' + name + '-1-aarch64.tar.gz'
    with tarfile.open(p, 'w:gz', format=tarfile.GNU_FORMAT) as z:
        d = tarfile.TarInfo('usr'); d.type = tarfile.DIRTYPE; d.mode = 0o755; z.addfile(d)
        for n, data, mode in files:
            i = tarfile.TarInfo(n); i.size = len(data); i.mode = mode; z.addfile(i, io.BytesIO(data))
        for n, target in links:
            i = tarfile.TarInfo(n); i.type = tarfile.SYMTYPE; i.linkname = target; z.addfile(i)
        for n, target in hard:
            i = tarfile.TarInfo(n); i.type = tarfile.LNKTYPE; i.linkname = target; z.addfile(i)
    return p, hashlib.sha256(open(p, 'rb').read()).hexdigest()
longdir = 'usr/share/' + 'x' * 120 + '/file.txt'
pa, sa = pack('alpha', [('usr/bin/alpha', b'#!/bin/sh\necho alpha\n', 0o755), ('usr/lib/libalpha.so.1', b'lib', 0o644), (longdir, b'long', 0o644)],
              links=[('usr/lib/libalpha.so', 'libalpha.so.1')], hard=[('usr/bin/alpha2', 'usr/bin/alpha')])
pb, sb = pack('beta', [('usr/bin/beta', b'#!/bin/sh\necho beta\n', 0o755)])
pe, se = pack('evil', [('usr/bin/evil', b'x', 0o755)], links=[('usr/lib/abs', '/etc')])
idx = [{'name': 'alpha', 'version': '1', 'url': 'file://' + pa, 'sha256': sa, 'depends': ['beta']},
       {'name': 'beta', 'version': '1', 'url': 'file://' + pb, 'sha256': sb, 'depends': []},
       {'name': 'bad', 'version': '1', 'url': 'file://' + pb, 'sha256': '0' * 64, 'depends': []},
       {'name': 'evil', 'version': '1', 'url': 'file://' + pe, 'sha256': se, 'depends': []}]
json.dump(idx, open(t + '/index.json', 'w'))
PY
export JC_PKG_INDEX="$T/index.json" JC_PKG_ROOT="$T/pkgroot"
"$J" pkg search | grep -q "^alpha  1" || { echo "ex test: pkg search"; exit 1; }
"$J" pkg install alpha > /dev/null || { echo "ex test: pkg install"; exit 1; }
[ "$("$T/pkgroot/usr/bin/alpha")" = "alpha" ] && [ "$("$T/pkgroot/usr/bin/beta")" = "beta" ] || { echo "ex test: pkg files and dependency"; exit 1; }
[ "$("$T/pkgroot/usr/bin/alpha2")" = "alpha" ] || { echo "ex test: pkg hard link"; exit 1; }
[ -L "$T/pkgroot/usr/lib/libalpha.so" ] && [ "$(cat "$T/pkgroot/usr/lib/libalpha.so")" = "lib" ] || { echo "ex test: pkg symbolic link"; exit 1; }
[ "$(cat "$T"/pkgroot/usr/share/xxxxxxxxxx*/file.txt)" = "long" ] || { echo "ex test: pkg long name"; exit 1; }
"$J" pkg list > "$T/plist"; grep -q "^alpha  1" "$T/plist" && grep -q "^beta  1" "$T/plist" || { echo "ex test: pkg list"; cat "$T/plist"; exit 1; }
"$J" pkg remove alpha > /dev/null || { echo "ex test: pkg remove"; exit 1; }
[ ! -e "$T/pkgroot/usr/bin/alpha" ] && [ ! -L "$T/pkgroot/usr/lib/libalpha.so" ] && [ -e "$T/pkgroot/usr/bin/beta" ] || { echo "ex test: pkg remove leaves the others"; exit 1; }
"$J" pkg install bad > /dev/null 2>&1 && { echo "ex test: a wrong checksum must be refused"; exit 1; }
[ ! -e "$T/pkgroot/usr/var/lib/jcpkg/bad.list" ] || { echo "ex test: bad package was recorded"; exit 1; }
"$J" pkg install evil > /dev/null 2>&1 || { echo "ex test: a package may have an absolute link (to the prefix)"; exit 1; }
[ -L "$T/pkgroot/usr/lib/abs" ] || { echo "ex test: absolute link not made"; exit 1; }
"$J" pkg install nothing > /dev/null 2>&1 && { echo "ex test: an unknown package must fail"; exit 1; }
unset JC_PKG_INDEX JC_PKG_ROOT

# jc install NAME: not a tool, so a package of ex-pkg
export JC_PKG_INDEX="$T/index.json" JC_PKG_ROOT="$T/pkgroot2"
"$J" install beta > /dev/null 2>&1 || { echo "ex test: install of a package by name"; exit 1; }
[ "$("$T/pkgroot2/usr/bin/beta")" = "beta" ] || { echo "ex test: install of a package by name: files"; exit 1; }
unset JC_PKG_INDEX JC_PKG_ROOT

# jc pkg update: another version in the index = removed and installed again
python3 - "$T" <<'PY'
import sys, json
t = sys.argv[1]
idx = json.load(open(t + '/index.json'))
for e in idx:
    if e['name'] == 'beta': e['version'] = '2'
json.dump(idx, open(t + '/index2.json', 'w'))
PY
export JC_PKG_INDEX="$T/index2.json" JC_PKG_ROOT="$T/pkgroot2"
"$J" pkg update -n | grep -q "beta: 1 -> 2" || { echo "ex test: pkg update -n"; exit 1; }
"$J" pkg list | grep -q "^beta  1" || { echo "ex test: pkg update -n must change nothing"; exit 1; }
"$J" pkg update > /dev/null || { echo "ex test: pkg update"; exit 1; }
"$J" pkg list | grep -q "^beta  2" && [ "$("$T/pkgroot2/usr/bin/beta")" = "beta" ] || { echo "ex test: pkg update result"; exit 1; }
"$J" pkg update | grep -q "up to date" || { echo "ex test: pkg update twice"; exit 1; }
unset JC_PKG_INDEX JC_PKG_ROOT

# jc update asks quietly about packages: with none installed it prints nothing more and does not fetch the index (a wrong index address must not matter)
P=$(mktemp -d)
JC_PKG_ROOT="$P" JC_PKG_INDEX="$P/no-such-index.json" "$J" pkg update --quiet > "$P/q.txt" 2>&1 || { echo "ex test: pkg update --quiet with no packages"; exit 1; }
[ ! -s "$P/q.txt" ] || { echo "ex test: pkg update --quiet printed: $(cat "$P/q.txt")"; exit 1; }

# the settings of the app: ex talks by ESC ] 7777 ; words BEL
say() { "$J" "$@" | od -An -c | tr -d ' \n'; }
[ "$(say setting)" = '033]7777;settings\a' ] || { echo "ex test: setting: $(say setting)"; exit 1; }
[ "$(say theme black)" = '033]7777;set;theme;black\a' ] || { echo "ex test: theme"; exit 1; }
[ "$(say awake on)" = '033]7777;set;awake;on\a' ] || { echo "ex test: awake"; exit 1; }
[ "$(say set size 32)" = '033]7777;set;size;32\a' ] || { echo "ex test: set"; exit 1; }
long=$("$J" help | awk 'length($0) > 38' | wc -l)
[ "$long" = 0 ] || { echo "ex test: a line of help is longer than 38 characters"; exit 1; }
# ex update brings itself up to date (the app once ran a copy under another name that was never updated)
U="$T/self"; mkdir -p "$U/bin" "$U/mirror/tools/ex" "$U/mirror/dl/ex-v9.9.9"
cp "$J" "$U/bin/ex"; printf '# tools\nex|the commands\n' > "$U/mirror/tools.txt"; echo 9.9.9 > "$U/mirror/tools/ex/LATEST"
printf '#!/bin/sh\necho "ex 9.9.9"\n' > "$U/mirror/dl/ex-v9.9.9/ex"; ( cd "$U/mirror/dl/ex-v9.9.9" && sha256sum ex > SHA256SUMS )
( cd "$U/bin" && JC_PKG_ROOT="$U/pkg" JCMPTOOLS_RAW="file://$U/mirror" JCMPTOOLS_DL="file://$U/mirror/dl" ./ex update > "$U/up.log" 2>&1 ) || true
[ "$("$U/bin/ex" --version)" = "ex 9.9.9" ] || { echo "ex test: ex update did not replace itself: $(cat "$U/up.log")"; exit 1; }
# ex app: what the newest app is comes from a file; a newer one is downloaded, checked and given to jearlink (a fake one records the words)
X="$T/app"; mkdir -p "$X/bin" "$X/home" "$X/tmp"
printf 'not really an app\n' > "$X/new.apk"
printf 'version 9.9\ncode 2000000000\nsha256 %s\nurl file://%s\n' "$(sha256sum "$X/new.apk" | cut -d' ' -f1)" "$X/new.apk" > "$X/app.txt"
printf '#!/bin/sh\necho "$*" > "%s"\n' "$X/ear.log" > "$X/bin/jearlink"; chmod 755 "$X/bin/jearlink"
A() { env EXSHELL=1 EXSHELL_APK="${EXSHELL_APK:-}" EXSHELL_CODE="$1" EXSHELL_VERSION=1.0 EX_APP_INDEX="file://$X/app.txt" HOME="$X/home" TMPDIR="$X/tmp" PATH="$X/bin:$PATH" "$J" app ${2:-} ${3:-}; }
A 1 update -n | grep -q "app newest: 9.9" || { echo "ex test: app update -n"; exit 1; }
[ ! -e "$X/ear.log" ] || { echo "ex test: -n must install nothing"; exit 1; }
A 1 update > "$X/o" 2>&1 || { echo "ex test: app update: $(cat "$X/o")"; exit 1; }
[ "$(cat "$X/ear.log")" = "-ins $X/home/.cache/exshell-9.9.apk" ] || { echo "ex test: jearlink got: $(cat "$X/ear.log" 2>/dev/null)"; exit 1; }
A 2000000000 update | grep -q "up to date" || { echo "ex test: the same app must be up to date"; exit 1; }
sed -i 's/^sha256 .*/sha256 0000000000000000000000000000000000000000000000000000000000000000/' "$X/app.txt"; rm -f "$X/ear.log"
A 1 update > /dev/null 2>&1 && { echo "ex test: a wrong checksum of the app must fail"; exit 1; }
[ ! -e "$X/ear.log" ] || { echo "ex test: a wrong app must not be installed"; exit 1; }
# a patch: only the patch is fetched and the new app is made from the installed one (the patch is made by apkpatch.py of exshell, or here by hand)
rm -f "$X/ear.log" "$X/home/.cache/"*
python3 - "$X" <<'PY'
import sys, struct, hashlib
x = sys.argv[1]
old = bytes(range(256)) * 400
new = old[:50000] + b'CHANGED PART' + old[50100:]
patch = b'EXPATCH1' + struct.pack('<I', len(new)) + b'C' + struct.pack('<II', 0, 50000) + b'I' + struct.pack('<I', 12) + b'CHANGED PART' + b'C' + struct.pack('<II', 50100, len(old) - 50100) + b'E'
open(x + '/old.apk', 'wb').write(old); open(x + '/new2.apk', 'wb').write(new); open(x + '/p', 'wb').write(patch)
h = lambda b: hashlib.sha256(b).hexdigest()
# the whole file is NOT there: it works only when the patch is used
open(x + '/app.txt', 'w').write('version 9.9\ncode 2000000000\nsha256 %s\nurl file://%s/missing.apk\npatch 7 %s file://%s/p\n' % (h(new), x, h(patch), x))
PY
EXSHELL_APK="$X/old.apk" A 7 update > "$X/o" 2>&1 || { echo "ex test: patch update: $(cat "$X/o")"; exit 1; }
cmp -s "$X/home/.cache/exshell-9.9.apk" "$X/new2.apk" || { echo "ex test: the patched app differs"; exit 1; }
# a patch that does not fit the installed app: the whole file is fetched instead
sed -i "s#^url .*#url file://$X/new2.apk#" "$X/app.txt"; printf 'other' > "$X/other.apk"; rm -f "$X/home/.cache/"*
EXSHELL_APK="$X/other.apk" A 7 update > "$X/o" 2>&1 || { echo "ex test: fallback after a bad patch: $(cat "$X/o")"; exit 1; }
grep -q "the whole file is fetched" "$X/o" && cmp -s "$X/home/.cache/exshell-9.9.apk" "$X/new2.apk" || { echo "ex test: fallback: $(cat "$X/o")"; exit 1; }
# ex update does the app too, after the tools: with -n it only says so
sed -i "s#^url .*#url file://$X/new2.apk#" "$X/app.txt"; rm -f "$X/ear.log" "$X/home/.cache/"*
mkdir -p "$X/up"; cp "$J" "$X/up/ex"; : > "$X/tools.txt"; : > "$X/versions.txt"
U1() { ( cd "$X/up" && env EXSHELL=1 EXSHELL_CODE=1 EX_APP_INDEX="file://$X/app.txt" JCMPTOOLS_RAW="file://$X" JC_PKG_ROOT="$X/pr" HOME="$X/home" TMPDIR="$X/tmp" PATH="$X/bin:$PATH" ./ex update ${1:-} ); }
U1 -n > "$X/o" 2>&1; grep -q "ex app update installs it" "$X/o" && [ ! -e "$X/ear.log" ] || { echo "ex test: update -n and the app: $(cat "$X/o")"; exit 1; }
U1 > "$X/o" 2>&1; [ -e "$X/ear.log" ] || { echo "ex test: update must update the app: $(cat "$X/o")"; exit 1; }
# ex doctor says what is there and ends well
printf 'ex 9.9.9\n' > "$U/mirror/versions.txt"
( cd "$U/bin" && JCMPTOOLS_RAW="file://$U/mirror" "$J" doctor ) > "$T/doc.txt" 2>&1 || { echo "ex test: doctor: $(cat "$T/doc.txt")"; exit 1; }
grep -q "^network   ok" "$T/doc.txt" && grep -q "^free " "$T/doc.txt" || { echo "ex test: doctor said: $(cat "$T/doc.txt")"; exit 1; }
# a tool asked for as a package is installed as the tool; a package that is there already says so
P2="$T/aspkg"; mkdir -p "$P2/bin"; cp "$J" "$P2/bin/ex"; printf '[]' > "$P2/index.json"
( cd "$P2/bin" && JC_PKG_ROOT="$P2/root" JC_PKG_INDEX="$P2/index.json" JCMPTOOLS_RAW="file://$M" JCMPTOOLS_DL="file://$M/dl" ./ex pkg install foo > "$P2/o" 2>&1 ) || { echo "ex test: pkg install of a tool: $(cat "$P2/o")"; exit 1; }
[ "$("$P2/bin/foo")" = "foo 1.0.0" ] && grep -q "is a tool, not a package" "$P2/o" || { echo "ex test: pkg install of a tool: $(cat "$P2/o")"; exit 1; }
JC_PKG_ROOT="$T/pkgroot2" JC_PKG_INDEX="$T/index2.json" "$J" pkg install beta | grep -q "installed already" || { echo "ex test: installed already"; exit 1; }
# one set of words: a pack installs its names, unstall removes a package, list shows what is here
mkdir -p "$M/pack"; printf 'foo\n' > "$M/pack/p.txt"; rm -f "$P2/bin/foo" "$P2/bin/.foo.version"
( cd "$P2/bin" && JC_PKG_ROOT="$P2/root" JC_PKG_INDEX="$P2/index.json" JCMPTOOLS_RAW="file://$M" JCMPTOOLS_DL="file://$M/dl" ./ex pack install p > "$P2/o" 2>&1 ) || { echo "ex test: pack install: $(cat "$P2/o")"; exit 1; }
[ -x "$P2/bin/foo" ] || { echo "ex test: pack install: $(cat "$P2/o")"; exit 1; }
( cd "$P2/bin" && JC_PKG_ROOT="$T/pkgroot2" ./ex list ) > "$P2/l" 2>&1; grep -q "^  foo  1.0.0" "$P2/l" && grep -q "^beta  2" "$P2/l" || { echo "ex test: list: $(cat "$P2/l")"; exit 1; }
( cd "$P2/bin" && JC_PKG_ROOT="$T/pkgroot2" JCMPTOOLS_RAW="file://$M" ./ex unstall beta > "$P2/o" 2>&1 ) || { echo "ex test: unstall a package: $(cat "$P2/o")"; exit 1; }
[ ! -e "$T/pkgroot2/usr/bin/beta" ] || { echo "ex test: the package is still there"; exit 1; }
( cd "$P2/bin" && JC_PKG_ROOT="$P2/root" JC_PKG_INDEX="$T/index.json" JCMPTOOLS_RAW="file://$M" ./ex search alp ) > "$P2/s" 2>&1; grep -q "^alpha  1" "$P2/s" || { echo "ex test: search: $(cat "$P2/s")"; exit 1; }
# the packages were built for the folder of another app: links and scripts that name it are moved to the real folder
python3 - "$T" <<'PY'
import sys, io, tarfile, hashlib, json
t = sys.argv[1]; old = '/data/data/com.jaric.app/files/'
p = t + '/moved-1-aarch64.tar.gz'
with tarfile.open(p, 'w:gz', format=tarfile.GNU_FORMAT) as z:
    for n, data in [('usr/bin/real', b'#!/bin/sh\necho real\n'), ('usr/bin/script', ('#!' + old + 'usr/bin/real\necho x\n').encode())]:
        i = tarfile.TarInfo(n); i.size = len(data); i.mode = 0o755; z.addfile(i, io.BytesIO(data))
    i = tarfile.TarInfo('usr/bin/link'); i.type = tarfile.SYMTYPE; i.linkname = old + 'usr/bin/real'; z.addfile(i)
json.dump([{'name': 'moved', 'version': '1', 'url': 'file://' + p, 'sha256': hashlib.sha256(open(p, 'rb').read()).hexdigest(), 'depends': []}], open(t + '/moved.json', 'w'))
PY
( cd "$P2/bin" && JC_PKG_ROOT="$T/moved" JC_PKG_INDEX="$T/moved.json" JCMPTOOLS_RAW="file://$M" ./ex install moved > "$P2/o" 2>&1 ) || { echo "ex test: install moved: $(cat "$P2/o")"; exit 1; }
[ "$("$T/moved/usr/bin/link")" = "real" ] || { echo "ex test: a link to the old folder was not moved: $(ls -l "$T/moved/usr/bin")"; exit 1; }
[ "$(head -1 "$T/moved/usr/bin/script")" = "#!$T/moved/usr/bin/real" ] || { echo "ex test: a script was not moved: $(head -1 "$T/moved/usr/bin/script")"; exit 1; }
# the app: ex toast, ex battery ... and the library exapi, against a socket of the test
cat > "$T/appsrv.py" <<'PY'
import socket, sys, os, json
p, log = sys.argv[1], open(sys.argv[2], 'a')
s = socket.socket(socket.AF_UNIX); s.bind(p); s.listen(8)
while True:
    c, _ = s.accept(); data = b''
    while True:
        d = c.recv(4096)
        if not d: break
        data += d
    w = data.decode().split('\0'); log.write(json.dumps(w) + '\n'); log.flush()
    a = {'battery': '0' + '87 charging', 'paste': '0from the phone', 'launch': '1no such app', 'api': '0toast\nnotify', 'get': '0black', 'pick': '0/h/tmp/cam-picked.bin'}.get(w[0], '0')
    c.sendall(a.encode()); c.close()
PY
python3 "$T/appsrv.py" "$T/exapi.sock" "$T/app.log" & APPSRV=$!
for i in 1 2 3 4 5 6 7 8 9 10; do [ -S "$T/exapi.sock" ] && break; sleep 0.3; done
app() { EXSHELL_API="$T/exapi.sock" "$J" "$@"; }
[ "$(app battery)" = "87 charging" ] || { echo "ex test: battery: $(app battery 2>&1)"; kill $APPSRV; exit 1; }
app toast hello there || { echo "ex test: toast"; kill $APPSRV; exit 1; }
app notify "the build" passed now || { echo "ex test: notify"; kill $APPSRV; exit 1; }
( cd "$T" && echo x > doc.txt && app open doc.txt && app open https://example.com && app tab echo hi ) || { echo "ex test: open"; kill $APPSRV; exit 1; }
printf 'piped text' | app copy || { echo "ex test: copy"; kill $APPSRV; exit 1; }
out=$(app launch nothing 2>&1) && { echo "ex test: a refused request must fail"; kill $APPSRV; exit 1; }
echo "$out" | grep -q "no such app" || { echo "ex test: the reason: $out"; kill $APPSRV; exit 1; }
out=$(EXSHELL_API= "$J" toast x 2>&1) && { echo "ex test: outside the app must fail"; kill $APPSRV; exit 1; }
echo "$out" | grep -q "not exshell" || { echo "ex test: outside: $out"; kill $APPSRV; exit 1; }
cat > "$T/use.jk" <<'JK'
#import <exapi>
fn main() {
    if !Ex::inside() { return 1; }
    Ex::toast("from code");
    jout << Ex::battery() << " " << Ex::charging() << " " << Ex::paste() << " " << Ex::get("theme") << " " << Ex::pick("image") << nl;
    if Ex::launch("nothing") { return 2; }
    jout << Ex::system("exit 7") << nl;
    ExResult r = Ex::send("echo 'two words' last");
    jout << r.ok << " " << r.text;
    ExResult m = Ex::send("no-such-tool -x");
    jout << m.missing << " " << m.hint << nl;
    ExResult f = Ex::send("ls /no/such/place");
    jout << f.ok << " " << (f.text.len > 0) << nl;
    return 0;
}
JK
J2K_PATH="$PWD:$J2K_PATH" "${JCMP:-jcmp}" "$T/use.jk" -o "$T/use" > "$T/use.txt" 2>&1 || { echo "ex test: the library does not build:"; cat "$T/use.txt"; kill $APPSRV; exit 1; }
got=$(EXSHELL_API="$T/exapi.sock" "$T/use" | tr '\n' '|')
[ "$got" = "87 true from the phone black /h/tmp/cam-picked.bin|7|true two words last|true ex install no-such-tool|false true|" ] || { echo "ex test: the library: $got"; kill $APPSRV; exit 1; }
kill $APPSRV
python3 - "$T/app.log" "$T" <<'PY' || { echo "ex test: the requests"; exit 1; }
import json, sys, os
r = [json.loads(l) for l in open(sys.argv[1])]
for want in (['battery'], ['toast', 'hello there'], ['notify', 'the build', 'passed now'], ['open', os.path.realpath(sys.argv[2] + '/doc.txt')], ['open', 'https://example.com'], ['tab', 'echo hi'], ['copy', 'piped text'], ['toast', 'from code']):
    assert want in r, (want, r)
PY
# a person at a terminal is asked before anything is installed; a name means only that one; -y does not ask; a script is not asked
Q="$T/ask"; mkdir -p "$Q/bin" "$Q/mirror/tools/foo" "$Q/mirror/tools/bar" "$Q/mirror/tools/baz" "$Q/mirror/dl/foo-v2.0.0" "$Q/mirror/dl/bar-v2.0.0" "$Q/mirror/dl/baz-v1.0.0"
cp "$J" "$Q/bin/ex"; printf '# tools\nfoo|a\nbar|b\nbaz|c\n' > "$Q/mirror/tools.txt"; printf 'foo 2.0.0\nbar 2.0.0\nbaz 1.0.0\n' > "$Q/mirror/versions.txt"
for p in foo:2.0.0 bar:2.0.0 baz:1.0.0; do n=${p%:*}; v=${p#*:}; echo $v > "$Q/mirror/tools/$n/LATEST"; printf '#!/bin/sh\necho "%s %s"\n' $n $v > "$Q/mirror/dl/$n-v$v/$n"; ( cd "$Q/mirror/dl/$n-v$v" && sha256sum $n > SHA256SUMS ); done
old() { for n in foo bar; do printf '#!/bin/sh\necho "%s 1.0.0"\n' $n > "$Q/bin/$n"; chmod 755 "$Q/bin/$n"; rm -f "$Q/bin/.$n.version"; done; rm -f "$Q/bin/baz" "$Q/bin/.baz.version"; }
cat > "$Q/ask.py" <<'PY'
import os, pty, select, sys, time
answer = sys.argv[1]
pid, fd = pty.fork()
if pid == 0: os.execv(sys.argv[2], sys.argv[2:])
out = b''; asked = 0; end = time.time() + 40
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 1)
    if not r: continue
    try: c = os.read(fd, 4096)
    except OSError: break
    if not c: break
    out += c
    while out.count(b'[y/n]') > asked:
        asked += 1; time.sleep(0.2); os.write(fd, answer.encode() + b'\r')
os.waitpid(pid, 0)
sys.stdout.write(out.decode(errors='replace') + '\nASKED %d\n' % asked)
PY
AX() { ans=$1; shift; env JC_PKG_ROOT="$Q/pkg" JC_PKG_INDEX="$T/index.json" JCMPTOOLS_RAW="file://$Q/mirror" JCMPTOOLS_DL="file://$Q/mirror/dl" EXSHELL= python3 -I "$Q/ask.py" $ans "$Q/bin/ex" "$@" > "$Q/o"; }
ver() { "$Q/bin/$1" --version; }
bad() { echo "ex test: $1:"; cat "$Q/o"; exit 1; }
old; AX n update; grep -q "ASKED 1" "$Q/o" && [ "$(ver foo)" = "foo 1.0.0" ] && [ "$(ver bar)" = "bar 1.0.0" ] || bad "update, no"
old; AX y update; grep -q "ASKED 1" "$Q/o" && [ "$(ver foo)" = "foo 2.0.0" ] && [ "$(ver bar)" = "bar 2.0.0" ] || bad "update, yes"
old; AX y update foo; [ "$(ver foo)" = "foo 2.0.0" ] && [ "$(ver bar)" = "bar 1.0.0" ] || bad "update of one name"
grep -q "bar: " "$Q/o" && bad "update of one name shows the others"
AX y update foo; grep -q "up to date" "$Q/o" && grep -q "ASKED 0" "$Q/o" || bad "update of a name that is new already"
AX y update baz; grep -q "not installed" "$Q/o" && [ ! -e "$Q/bin/baz" ] || bad "update of a name that is not installed"
old; AX n update -y; grep -q "ASKED 0" "$Q/o" && [ "$(ver bar)" = "bar 2.0.0" ] || bad "update -y"
old; AX n update -y foo; [ "$(ver foo)" = "foo 2.0.0" ] && [ "$(ver bar)" = "bar 1.0.0" ] || bad "update -y NAME"
old; AX n install baz; grep -q "ASKED 1" "$Q/o" && [ ! -e "$Q/bin/baz" ] || bad "install, no"
AX y install baz; grep -q "ASKED 1" "$Q/o" && [ "$(ver baz)" = "baz 1.0.0" ] || bad "install, yes"
old; AX n install baz -y; grep -q "ASKED 0" "$Q/o" && [ -x "$Q/bin/baz" ] || bad "install -y"
rm -rf "$Q/pkg"; AX n install beta; grep -q "ASKED 1" "$Q/o" && [ ! -e "$Q/pkg/usr/bin/beta" ] || bad "package, no"
AX y install beta; grep -q "ASKED 1" "$Q/o" && [ -x "$Q/pkg/usr/bin/beta" ] || bad "package, yes (asked once)"
old; AX n unstall foo; grep -q "ASKED 1" "$Q/o" && [ -x "$Q/bin/foo" ] || bad "unstall, no"
AX y unstall foo; grep -q "ASKED 1" "$Q/o" && [ ! -e "$Q/bin/foo" ] || bad "unstall, yes"
old; AX n unstall foo -y; grep -q "ASKED 0" "$Q/o" && [ ! -e "$Q/bin/foo" ] || bad "unstall -y"
AX n pkg remove beta; grep -q "ASKED 1" "$Q/o" && [ -x "$Q/pkg/usr/bin/beta" ] || bad "package remove, no"
AX y unstall mascos; grep -q "ASKED 1" "$Q/o" && grep -q "mascot;off" "$Q/o" || bad "unstall mascot"
AX n install mascot; grep -q "ASKED 1" "$Q/o" && ! grep -q "mascot;on" "$Q/o" || bad "install mascot, no"
AX y install mascot; grep -q "mascot;on" "$Q/o" || bad "install mascot, yes"
old; ( env JCMPTOOLS_RAW="file://$Q/mirror" JCMPTOOLS_DL="file://$Q/mirror/dl" EXSHELL= "$Q/bin/ex" install baz < /dev/null > "$Q/o" 2>&1 ) && [ -x "$Q/bin/baz" ] || bad "a script is not asked"
echo "ex tests: ok"
