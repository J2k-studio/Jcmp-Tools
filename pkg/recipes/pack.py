#!/usr/bin/env python3
"""pack.py TARGET OUTPUT_DIR DIST_DIR TAG_BASE_URL
Turns the .deb files that termux-packages built (with the prefix of Jaric) into the archives of Jcmp-pkg:
 * keeps TARGET and the packages it needs (the closure of Depends among the built files),
 * one DIST_DIR/NAME-VERSION-aarch64.tar.gz each (the folder usr/ of the prefix; a colon of an epoch becomes a dot),
 * DIST_DIR/index-TARGET.json: the lines for index.json (name, version, arch, url, sha256, size, unpacked size, depends, bin)."""
import hashlib, json, os, re, subprocess, sys, tarfile, tempfile

target, outdir, dist, base = sys.argv[1:5]
PREFIX = "data/data/com.jaric.app/files"
os.makedirs(dist, exist_ok=True)

def field(deb, name):
    r = subprocess.run(["dpkg-deb", "-f", deb, name], capture_output=True, text=True)
    return r.stdout.strip()

debs = {}
for f in sorted(os.listdir(outdir)):
    if f.endswith(".deb"):
        p = os.path.join(outdir, f)
        debs[field(p, "Package")] = p

def needs(name):
    dep = field(debs[name], "Depends")
    names = []
    for part in dep.split(","):
        n = re.split(r"[ |(]", part.strip())[0]
        if n in debs: names.append(n)
    return names

keep, todo = set(), [target]
if target not in debs:
    print("the package %s was not built; built: %s" % (target, ", ".join(sorted(debs)[:20])), file=sys.stderr); sys.exit(1)
while todo:
    n = todo.pop()
    if n in keep: continue
    keep.add(n)
    todo.extend(needs(n))

entries = []
for name in sorted(keep):
    deb = debs[name]
    version = field(deb, "Version")
    safe = version.replace(":", ".")
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["dpkg-deb", "-x", deb, tmp], check=True)
        root = os.path.join(tmp, PREFIX)
        if not os.path.isdir(os.path.join(root, "usr")):
            print("no usr/ in %s (the prefix of the build is not Jaric's?)" % name, file=sys.stderr); sys.exit(2)
        archive = os.path.join(dist, "%s-%s-aarch64.tar.gz" % (name, safe))
        with tarfile.open(archive, "w:gz", format=tarfile.GNU_FORMAT) as t:
            t.add(os.path.join(root, "usr"), arcname="usr")
        unpacked = sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(os.path.join(root, "usr")) for f in fs if os.path.isfile(os.path.join(d, f)))
        bins = sorted("bin/" + f for f in os.listdir(os.path.join(root, "usr", "bin"))) if os.path.isdir(os.path.join(root, "usr", "bin")) else []
    sha = hashlib.sha256(open(archive, "rb").read()).hexdigest()
    entries.append({"name": name, "version": version, "arch": "aarch64",
                    "url": "%s/%s" % (base, os.path.basename(archive)), "sha256": sha,
                    "size": os.path.getsize(archive), "unpacked": unpacked,
                    "depends": [d for d in needs(name) if d in keep], "bin": bins})
json.dump(entries, open(os.path.join(dist, "index-%s.json" % target), "w"), indent=1)
print("packed %d packages for %s" % (len(entries), target))
