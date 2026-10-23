#!/bin/sh
# jgit: the repositories of jgit are read by git (fsck, log, tree, status) and the repositories of git are read by jgit; packed objects are said clearly
set -eu
cd "$(dirname "$0")"; export J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}"; sh build.sh >/dev/null
J="$PWD/_out/jgit"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export JGIT_NAME="Tester" JGIT_EMAIL="t@example.org" HOME="$T/home"; mkdir -p "$HOME"
[ "$("$J" --version)" = "jgit 0.1.0" ] || { echo "jgit test: version"; exit 1; }
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
    # packed objects (git gc): said clearly
    git gc -q 2> /dev/null; out=$("$J" log 2>&1 || true)
    echo "$out" | grep -q "packed" || { echo "jgit test: a packed repository must be said clearly: $out"; exit 1; }
fi
echo "jgit tests: ok"
