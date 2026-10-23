#!/bin/sh
# jgit: the repositories of jgit are read by git (fsck, log, tree, status) and the repositories of git are read by jgit; packed objects are said clearly
set -eu
cd "$(dirname "$0")"; export J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}"; sh build.sh >/dev/null
J="$PWD/_out/jgit"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export JGIT_NAME="Tester" JGIT_EMAIL="t@example.org" HOME="$T/home"; mkdir -p "$HOME"
[ "$("$J" --version)" = "jgit 0.2.0" ] || { echo "jgit test: version"; exit 1; }
cd "$T"; "$J" init r1 > /dev/null; cd r1
"$J" status > /dev/null 2>&1 && true
mkdir -p src/deep; echo hello > a.txt; echo world > src/b.txt; printf '#!/bin/sh\necho x\n' > src/run.sh; chmod 755 src/run.sh; head -c 3000 /dev/urandom > bin.dat; echo deep > src/deep/c.txt
"$J" add . || { echo "jgit test: add ."; exit 1; }
"$J" status | grep -q "A  src/run.sh" || { echo "jgit test: status after add"; exit 1; }
"$J" commit -m "first commit" | grep -q "first commit" || { echo "jgit test: commit"; exit 1; }
"$J" commit -m "again" > /dev/null 2>&1 && { echo "jgit test: a commit with nothing new must be refused"; exit 1; }
echo more >> a.txt; "$J" add a.txt; "$J" commit -m "second" > /dev/null || { echo "jgit test: second commit"; exit 1; }
"$J" log | grep -c "^commit " | grep -q 2 || { echo "jgit test: log"; exit 1; }
if command -v git > /dev/null 2>&1; then
    git fsck > "$T/fsck.txt" 2>&1 || { cat "$T/fsck.txt"; echo "jgit test: git fsck"; exit 1; }
    [ "$(git log --format=%s | tr '\n' ,)" = "second,first commit," ] || { echo "jgit test: git log"; exit 1; }
    git ls-tree -r HEAD | grep -q "^100755 blob .*src/run.sh" || { echo "jgit test: the right to run"; exit 1; }
    [ -z "$(git status --short)" ] || { echo "jgit test: git status says: $(git status --short)"; exit 1; }
    cmp -s bin.dat "$(git show HEAD:bin.dat > "$T/bin.out"; echo "$T/bin.out")" || { echo "jgit test: a file with zero bytes"; exit 1; }
    # the other way: a repository made by git
    cd "$T"; git init -q r2; cd r2
    git config user.name G; git config user.email g@x; git config gc.auto 0
    mkdir sub; echo one > a.txt; echo two > sub/b.txt; git add .; git commit -qm "git first"
    echo more >> a.txt; git add a.txt; git commit -qm "git second"
    git checkout -q -b feature; echo f > feat.txt; git add feat.txt; git commit -qm "on feature"; git checkout -q -
    "$J" log | grep -q "git second" || { echo "jgit test: log of a repository of git"; exit 1; }
    "$J" status | grep -q "work folder is clean" || { echo "jgit test: status of a repository of git: $("$J" status)"; exit 1; }
    echo changed >> sub/b.txt; echo new > n.txt
    st=$("$J" status); echo "$st" | grep -q " M sub/b.txt" && echo "$st" | grep -q "?? n.txt" || { echo "jgit test: status with changes"; exit 1; }
    "$J" diff | grep -q "^+changed" || { echo "jgit test: diff"; exit 1; }
    "$J" switch feature > /dev/null 2>&1 && { echo "jgit test: switch must refuse with unsaved changes"; exit 1; }
    git checkout -q -- sub/b.txt; rm -f n.txt
    "$J" switch feature > /dev/null || { echo "jgit test: switch"; exit 1; }
    [ -f feat.txt ] && [ "$(git rev-parse --abbrev-ref HEAD)" = feature ] && [ -z "$(git status --short)" ] || { echo "jgit test: after switch git says: $(git status --short)"; exit 1; }
    # packed objects (git gc --aggressive makes deltas) and a clone (a pack): every object is read byte for byte, like git reads it
    python3 - <<'PY'
import random
random.seed(5)
open('big.txt', 'w').write('\n'.join(f"line {i} " + "x" * random.randint(5, 60) for i in range(300)) + '\n')
PY
    git add big.txt; git commit -qm "big"
    for n in 1 2 3 4; do python3 -c "
n=$n
ls=open('big.txt').read().split('\n')
ls[n*20]='CHANGED $n '+ls[n*20]
ls.insert(n*50,'inserted $n')
open('big.txt','w').write('\n'.join(ls))
"; git commit -qam "change $n"; done
    git gc -q --aggressive 2> /dev/null
    [ -z "$(ls objects 2>/dev/null)" ] || true
    bad=0; n=0
    for h in $(git rev-list --objects --all | cut -d' ' -f1); do
        k=$(git cat-file -t "$h"); git cat-file "$k" "$h" > "$T/exp.bin"; "$J" cat -r "$h" > "$T/got.bin" 2> /dev/null
        cmp -s "$T/exp.bin" "$T/got.bin" || { bad=$((bad+1)); echo "jgit test: object $h ($k) differs from git"; }
        n=$((n+1))
    done
    [ "$bad" = 0 ] && [ "$n" -gt 10 ] || { echo "jgit test: packed objects ($bad of $n differ)"; exit 1; }
    "$J" log -n 2 | grep -q "change 4" || { echo "jgit test: log of a packed repository"; exit 1; }
    cd "$T"; git clone -q --no-local r2 r3; cd r3
    "$J" log | grep -q "git first" || { echo "jgit test: log of a clone"; exit 1; }
    "$J" status | grep -q "clean" || { echo "jgit test: status of a clone"; exit 1; }
    git branch -q old HEAD~2; "$J" switch old > /dev/null || { echo "jgit test: switch in a clone"; exit 1; }
    [ "$(git rev-parse --abbrev-ref HEAD)" = old ] && [ -z "$(git status --short)" ] || { echo "jgit test: after switch in a clone"; exit 1; }
fi
echo "jgit tests: ok"
