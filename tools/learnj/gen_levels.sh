#!/bin/sh
# gen_levels.sh: rebuilds levels_data.j from levels.txt and levels_en.txt of the learnj repository (default ~/learnj)
set -eu
SRC="${1:-$HOME/learnj}"
python3 - "$SRC" <<'PY'
import sys
d=sys.argv[1]
def esc(t): return t.replace("\\","\\\\").replace('"','\\"').replace("\t","\\t")
def chunks(l, n=300):
    b=l.encode("utf-8"); parts=[]; i=0
    while i<len(b):
        j=min(i+n,len(b))
        while j<len(b) and (b[j]&0xC0)==0x80: j-=1      # do not cut a UTF-8 letter
        parts.append(b[i:j].decode("utf-8")); i=j
    return parts
def body(fn):
    out=""
    for l in open(d+"/"+fn).read().split("\n"):
        if l:
            for p in chunks(l): out+='    r = r + "%s";\n'%esc(p)
            out+='    r = r + "\\n";\n'
    return out
src='// the levels of learnj built into the program (generated from levels.txt and levels_en.txt by gen_levels.sh)\nString embedded_levels(bool english) {\n    String r = "";\n    if english {\n'+body("levels_en.txt")+'        return r;\n    }\n'+body("levels.txt")+'    return r;\n}\n'
open("levels_data.j","w").write(src)
PY
