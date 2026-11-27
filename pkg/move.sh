#!/bin/sh
# move.sh [N]: moves N packages (default 2) from the releases of Jcmp-pkg to the releases of ex-pkg, a few at a time (the owner: "move them slowly").
# For each package of index.json whose url still points at Jcmp-pkg: download the archive, check its sha256, make the release TAG in ex-pkg (when it is missing),
# upload the archive, then change the url in index.json. The old release stays until all are moved. Needs gh and GH_TOKEN (never printed).
set -eu
cd "$(dirname "$0")"
N="${1:-2}"
python3 - "$N" <<'PY'
import json, sys, os, subprocess, hashlib, urllib.request, re
n = int(sys.argv[1]); idx = json.load(open('index.json')); done = 0
def walk(o):
    if isinstance(o, dict):
        yield o
        for v in o.values(): yield from walk(v)
    elif isinstance(o, list):
        for v in o: yield from walk(v)
for d in walk(idx):
    u = d.get('url', '')
    m = re.match(r'https://github.com/J2k-studio/Jcmp-pkg/releases/download/([^/]+)/(.+)$', u)
    if not m or done >= n: continue
    tag, fn = m.groups(); tmp = os.path.join(os.environ.get('TMPDIR', '/tmp'), fn)
    urllib.request.urlretrieve(u, tmp)
    if 'sha256' in d and hashlib.sha256(open(tmp, 'rb').read()).hexdigest() != d['sha256']: sys.exit('sha256 differs: ' + fn)
    if subprocess.call(['gh', 'release', 'view', tag, '-R', 'J2k-studio/ex-pkg'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) != 0:
        subprocess.check_call(['gh', 'release', 'create', tag, '-R', 'J2k-studio/ex-pkg', '-t', tag, '-n', 'moved from Jcmp-pkg'])
    subprocess.check_call(['gh', 'release', 'upload', tag, tmp, '-R', 'J2k-studio/ex-pkg', '--clobber'])
    d['url'] = u.replace('J2k-studio/Jcmp-pkg', 'J2k-studio/ex-pkg'); os.remove(tmp); done += 1; print('moved', tag, fn)
json.dump(idx, open('index.json', 'w'), indent=2); open('index.json', 'a').write('\n')
print(done, 'moved')
PY
