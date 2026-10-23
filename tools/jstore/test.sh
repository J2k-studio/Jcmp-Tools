#!/bin/sh
# jstore: list, info, install (checksum checked, permissions asked by jc), a damaged package is refused, update, remove
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jstore"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# the tool jc is needed: build it here
mkdir -p "$T/bin"
( cd ../jc && "${JCMP:-jcmp}" jc.jk -o "$T/bin/jc" ) > /dev/null 2>&1 || { echo "jstore test: jc does not build"; exit 1; }
export PATH="$T/bin:$PATH" JC_ROOT="$T/root"
python3 - "$T" <<'PY'
import sys, zipfile, hashlib
t = sys.argv[1]
def make(name, ver, perms):
    z = zipfile.ZipFile(f'{t}/{name}-{ver}.jc', 'w', zipfile.ZIP_DEFLATED)
    z.writestr('manifest.toml', f'name = "{name.title()}"\nid = "app.{name}"\nversion = "{ver}"\nentry = "run"\npermissions = {perms}\n')
    z.writestr('run', f"#!/bin/sh\necho {name} {ver}\n")
    z.close()
    return hashlib.sha256(open(f'{t}/{name}-{ver}.jc', 'rb').read()).hexdigest()
a1 = make('hello', '1.0', '[]')
a2 = make('hello', '1.1', '[]')
g = make('game', '2.0', '["audio", "files"]')
open(f'{t}/index.txt', 'w').write(f'# a test index\napp.hello 1.0 {t}/hello-1.0.jc {a1} - Hello program\napp.hello 1.1 {t}/hello-1.1.jc {a2} - Hello program\napp.game 2.0 {t}/game-2.0.jc {g} files,audio A Game\napp.bad 1.0 {t}/hello-1.0.jc {"0"*64} - Bad checksum\n')
PY
export JSTORE_INDEX="$T/index.txt"
[ "$("$J" --version)" = "jstore 0.1.0" ] || { echo "jstore test: version"; exit 1; }
out=$("$J" list)
echo "$out" | grep -q "app.hello  1.1  Hello program   \[no permissions\]" || { echo "jstore test: list: $out"; exit 1; }
echo "$out" | grep -q "app.game  2.0  A Game   \[files,audio\]" || { echo "jstore test: list perms"; exit 1; }
[ "$("$J" list game | grep -c app.)" = 1 ] || { echo "jstore test: list WORD"; exit 1; }
"$J" info app.game | grep -q "permissions: files,audio" || { echo "jstore test: info"; exit 1; }
"$J" install app.bad -y > /dev/null 2>&1 && { echo "jstore test: a wrong checksum must be refused"; exit 1; }
[ ! -d "$T/root/apps/app.bad" ] || { echo "jstore test: a refused package was installed"; exit 1; }
"$J" install app.nothing > /dev/null 2>&1 && { echo "jstore test: an unknown id must fail"; exit 1; }
"$J" install app.game > /dev/null 2>&1 && { echo "jstore test: permissions without a terminal and -y must be refused by jc"; exit 1; }
"$J" install app.game -y > /dev/null || { echo "jstore test: install -y"; exit 1; }
"$J" list | grep -q "^\* app.game" || { echo "jstore test: the mark of an installed program"; exit 1; }
# the newest version is installed; an older one is offered as an update after the old one was put in
rm -rf "$T/root/apps/app.hello"
python3 - "$T" <<'PY'
import sys
t = sys.argv[1]
# pretend version 1.0 is installed (jc install of the old package)
PY
jc install "$T/hello-1.0.jc" -y > /dev/null
"$J" update | grep -q "app.hello: 1.0 -> 1.1" || { echo "jstore test: update list: $("$J" update)"; exit 1; }
"$J" update -y > /dev/null || { echo "jstore test: update -y"; exit 1; }
[ "$(jc run app.hello)" = "hello 1.1" ] || { echo "jstore test: the update was not installed"; exit 1; }
"$J" update | grep -q "up to date" || { echo "jstore test: up to date"; exit 1; }
"$J" remove app.game > /dev/null; "$J" list | grep -q "^\* app.game" && { echo "jstore test: remove"; exit 1; }
echo "jstore tests: ok"
