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
[ "$("$J" --version)" = "jc 0.3.0" ] || { echo "jc test: version"; exit 1; }
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
