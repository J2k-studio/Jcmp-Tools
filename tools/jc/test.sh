#!/bin/sh
# jc: info, install (asks for the permissions; -y gives them; no terminal = refuse), run (JC_PERMS, JC_ASSETS), list, perm, remove, bad packages
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jc"
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
[ "$("$J" --version)" = "jc 0.5.0" ] || { echo "jc test: version"; exit 1; }
"$J" info "$T/game.jc" | grep -q "permissions:  files,audio" || { echo "jc test: info"; exit 1; }
"$J" info "$T/notzip.jc" > /dev/null 2>&1 && { echo "jc test: a file that is not a zip must fail"; exit 1; }
"$J" install "$T/game.jc" > /dev/null 2>&1 && { echo "jc test: permissions without a terminal and without -y must be refused"; exit 1; }
"$J" install "$T/plain.jc" > /dev/null || { echo "jc test: a package without permissions installs without asking"; exit 1; }
"$J" install "$T/game.jc" -y > /dev/null || { echo "jc test: install -y"; exit 1; }
"$J" list | grep -q "game.mygame  1.0.0  My Game   permissions: files,audio" || { echo "jc test: list"; exit 1; }
out=$("$J" run game.mygame a b)
[ "$out" = "hello perms=files,audio assets=logo.txt home=game.mygame args=a b" ] || { echo "jc test: run said: $out"; exit 1; }
"$J" perm game.mygame network on > /dev/null; "$J" run game.mygame | grep -q "perms=files,audio,network" || { echo "jc test: perm on"; exit 1; }
"$J" perm game.mygame audio off > /dev/null; "$J" run game.mygame | grep -q "perms=files,network " || { echo "jc test: perm off"; exit 1; }
"$J" perm game.mygame rootkit on > /dev/null 2>&1 && { echo "jc test: an unknown permission must be refused"; exit 1; }
"$J" install "$T/bad.jc" -y > /dev/null 2>&1 && { echo "jc test: an unknown permission in a manifest must be refused"; exit 1; }
"$J" install "$T/noentry.jc" -y > /dev/null 2>&1 && { echo "jc test: a missing entry must be refused"; exit 1; }
"$J" install "$T/evil.jc" -y > /dev/null 2>&1; [ ! -e "$T/escape.txt" ] && [ ! -e "$T/root/escape.txt" ] && [ ! -e "$T/root/apps/escape.txt" ] || { echo "jc test: a name with .. must be skipped"; exit 1; }
"$J" run "$T/game.jc" x | grep -q "args=x" || { echo "jc test: run of a package file"; exit 1; }
"$J" remove game.mygame > /dev/null; "$J" list | grep -q "game.mygame" && { echo "jc test: remove"; exit 1; }
"$J" run game.mygame > /dev/null 2>&1 && { echo "jc test: run of a removed program"; exit 1; }
# tools: jc installs them itself (a mirror on this machine: JCMPTOOLS_RAW / JCMPTOOLS_DL); STORE.ID goes to jstore (a fake program on the PATH records its words)
M="$T/mirror"; mkdir -p "$M/tools/foo" "$M/dl/foo-v1.0.0" "$T/tb" "$T/fb"
printf '# tools\nfoo|a tool\n' > "$M/tools.txt"; echo 1.0.0 > "$M/tools/foo/LATEST"
printf '#!/bin/sh\necho "foo 1.0.0"\n' > "$M/dl/foo-v1.0.0/foo"; ( cd "$M/dl/foo-v1.0.0" && sha256sum foo > SHA256SUMS )
cp "$J" "$T/tb/jc"
TE="JCMPTOOLS_RAW=file://$M JCMPTOOLS_DL=file://$M/dl"
( cd "$T/tb" && env $TE ./jc install foo >/dev/null 2>&1 ); [ "$("$T/tb/foo")" = "foo 1.0.0" ] || { echo "jc test: jc install foo"; exit 1; }
( cd "$T/tb" && env $TE ./jc tools ) | grep -q "foo" || { echo "jc test: jc tools"; exit 1; }
( cd "$T/tb" && env $TE ./jc unstall foo >/dev/null 2>&1 ); [ ! -e "$T/tb/foo" ] || { echo "jc test: jc unstall foo"; exit 1; }
( cd "$T/tb" && env $TE ./jc unstall jc >/dev/null 2>&1 ) && { echo "jc test: jc must not remove itself"; exit 1; }
[ -e "$T/tb/jc" ] || { echo "jc test: jc is gone"; exit 1; }
printf '#!/bin/sh\necho "jstore $*" >> "$FAKELOG"\n' > "$T/fb/jstore"; chmod 755 "$T/fb/jstore"
FAKELOG="$T/fake.log"; export FAKELOG; : > "$FAKELOG"
PATH="$T/fb:$PATH" "$J" install store.hello
[ "$(cat "$FAKELOG")" = "jstore install store.hello" ] || { echo "jc test: a program of the store goes to jstore:"; cat "$FAKELOG"; exit 1; }
echo "jc tests: ok"

# jc pkg: packages of Jcmp-pkg (a .tar.gz of usr/ with links, an index.json with a dependency), install, list, search, remove, bad checksum
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
"$J" pkg search | grep -q "^alpha  1" || { echo "jc test: pkg search"; exit 1; }
"$J" pkg install alpha > /dev/null || { echo "jc test: pkg install"; exit 1; }
[ "$("$T/pkgroot/usr/bin/alpha")" = "alpha" ] && [ "$("$T/pkgroot/usr/bin/beta")" = "beta" ] || { echo "jc test: pkg files and dependency"; exit 1; }
[ "$("$T/pkgroot/usr/bin/alpha2")" = "alpha" ] || { echo "jc test: pkg hard link"; exit 1; }
[ -L "$T/pkgroot/usr/lib/libalpha.so" ] && [ "$(cat "$T/pkgroot/usr/lib/libalpha.so")" = "lib" ] || { echo "jc test: pkg symbolic link"; exit 1; }
[ "$(cat "$T"/pkgroot/usr/share/xxxxxxxxxx*/file.txt)" = "long" ] || { echo "jc test: pkg long name"; exit 1; }
"$J" pkg list > "$T/plist"; grep -q "^alpha  1" "$T/plist" && grep -q "^beta  1" "$T/plist" || { echo "jc test: pkg list"; cat "$T/plist"; exit 1; }
"$J" pkg remove alpha > /dev/null || { echo "jc test: pkg remove"; exit 1; }
[ ! -e "$T/pkgroot/usr/bin/alpha" ] && [ ! -L "$T/pkgroot/usr/lib/libalpha.so" ] && [ -e "$T/pkgroot/usr/bin/beta" ] || { echo "jc test: pkg remove leaves the others"; exit 1; }
"$J" pkg install bad > /dev/null 2>&1 && { echo "jc test: a wrong checksum must be refused"; exit 1; }
[ ! -e "$T/pkgroot/usr/var/lib/jcpkg/bad.list" ] || { echo "jc test: bad package was recorded"; exit 1; }
"$J" pkg install evil > /dev/null 2>&1 && { echo "jc test: an absolute link must be refused"; exit 1; }
"$J" pkg install nothing > /dev/null 2>&1 && { echo "jc test: an unknown package must fail"; exit 1; }
unset JC_PKG_INDEX JC_PKG_ROOT

# jc install NAME: not a tool, so a package of Jcmp-pkg
export JC_PKG_INDEX="$T/index.json" JC_PKG_ROOT="$T/pkgroot2"
"$J" install beta > /dev/null 2>&1 || { echo "jc test: install of a package by name"; exit 1; }
[ "$("$T/pkgroot2/usr/bin/beta")" = "beta" ] || { echo "jc test: install of a package by name: files"; exit 1; }
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
"$J" pkg update -n | grep -q "beta: 1 -> 2" || { echo "jc test: pkg update -n"; exit 1; }
"$J" pkg list | grep -q "^beta  1" || { echo "jc test: pkg update -n must change nothing"; exit 1; }
"$J" pkg update > /dev/null || { echo "jc test: pkg update"; exit 1; }
"$J" pkg list | grep -q "^beta  2" && [ "$("$T/pkgroot2/usr/bin/beta")" = "beta" ] || { echo "jc test: pkg update result"; exit 1; }
"$J" pkg update | grep -q "up to date" || { echo "jc test: pkg update twice"; exit 1; }
unset JC_PKG_INDEX JC_PKG_ROOT
