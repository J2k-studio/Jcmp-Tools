#!/bin/sh
# store/add.sh FILE.jc [PERMISSIONS|-] : put a package in store/apps and its line in store/index.txt (the id, the version and the name come from its manifest)
set -eu
cd "$(dirname "$0")"
PKG="$1"; PERMS="${2:-}"
python3 - "$PKG" "$PERMS" <<'PY'
import sys, zipfile, hashlib, shutil, os, re
pkg, perms = sys.argv[1], sys.argv[2]
z = zipfile.ZipFile(pkg)
m = z.read('manifest.toml').decode()
def val(k):
    r = re.search(r'^' + k + r'\s*=\s*"?([^"\n]*)"?', m, re.M)
    return r.group(1).strip() if r else ''
ident, ver, name = val('id'), val('version'), val('name')
if not perms:
    p = re.search(r'^permissions\s*=\s*\[(.*?)\]', m, re.M)
    perms = ','.join(x.strip().strip('"') for x in p.group(1).split(',') if x.strip()) if p else ''
perms = perms or '-'
dest = f'apps/{ident.split(".")[-1]}-{ver}.jc'
shutil.copy(pkg, dest)
h = hashlib.sha256(open(dest, 'rb').read()).hexdigest()
url = 'https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/store/' + dest
lines = [l for l in open('index.txt').read().split('\n') if l and not l.startswith(f'{ident} {ver} ')]
lines.append(f'{ident} {ver} {url} {h} {perms} {name}')
head = [l for l in lines if l.startswith('#')]
body = sorted(l for l in lines if not l.startswith('#'))
open('index.txt', 'w').write('\n'.join(head + body) + '\n')
print(ident, ver, perms, h)
PY
