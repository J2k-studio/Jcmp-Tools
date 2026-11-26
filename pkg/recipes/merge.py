#!/usr/bin/env python3
"""merge.py index.json index-A.json [index-B.json ...]: puts the lines of the fragments into index.json (a name already there is replaced), sorted by name."""
import json, sys
idx = {e["name"]: e for e in json.load(open(sys.argv[1]))}
for f in sys.argv[2:]:
    for e in json.load(open(f)): idx[e["name"]] = e
json.dump([idx[n] for n in sorted(idx)], open(sys.argv[1], "w"), indent=1)
print("%d packages in %s" % (len(idx), sys.argv[1]))
