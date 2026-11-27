#!/bin/bash
# the network of jgit against a real git server (git http-backend behind gitserver.py): clone, push, pull, the refusals; git itself checks the result
set -eu
JG="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d); SPID=""
trap '[ -n "$SPID" ] && kill $SPID 2>/dev/null; rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
git config --global init.defaultBranch main; git config --global user.email a@b.c; git config --global user.name A; git config --global advice.defaultBranchName false
export JGIT_NAME=Tester JGIT_EMAIL=t@example.org
cd "$T"; mkdir srv
git init -q --bare srv/repo.git; git -C srv/repo.git config http.receivepack true; git -C srv/repo.git symbolic-ref HEAD refs/heads/main
git init -q seed; cd seed
printf 'hello\n' > a.txt; mkdir -p sub/deep; seq 1 500 > sub/nums.txt; head -c 3000 /dev/urandom > sub/deep/rand.bin; printf '#!/bin/sh\necho run\n' > run.sh; chmod +x run.sh
git add .; git commit -qm one
seq 1 500 | sed 's/7/seven/' > sub/nums.txt; printf 'hello 2\n' > a.txt; git add .; git commit -qm two
seq 1 500 | sed 's/8/eight/' > sub/nums.txt; git commit -qam three
git remote add o ../srv/repo.git; git push -q o main; git -C ../srv/repo.git gc -q     # a packed repository: the clone has to read deltas
cd "$T"
python3 -I "$HERE/gitserver.py" "$T/srv" "$T/port" > /dev/null 2>&1 &
SPID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do [ -s "$T/port" ] && break; sleep 0.5; done
PORT=$(cat "$T/port"); URL="http://127.0.0.1:$PORT/repo.git"
"$JG" clone "$URL" work1 > /dev/null || { echo "net test: clone"; exit 1; }
diff -r seed work1 -x .git > /dev/null || { echo "net test: the clone has other files"; exit 1; }
[ "$(git -C work1 log --format=%s | tr '\n' ' ')" = "three two one " ] || { echo "net test: git does not read the log of the clone"; exit 1; }
git -C work1 fsck --strict > /dev/null 2>&1 || { echo "net test: git fsck finds a problem in the clone"; exit 1; }
[ -z "$(git -C work1 status --short)" ] || { echo "net test: git status is not clean after the clone"; exit 1; }
[ -x work1/run.sh ] || { echo "net test: the execute right is lost"; exit 1; }
# the pack of the server is kept as a pack (with an index that git accepts), not unpacked object by object
ls work1/.git/objects/pack/pack-*.pack > /dev/null 2>&1 || { echo "net test: no pack was kept"; exit 1; }
git verify-pack work1/.git/objects/pack/pack-*.idx || { echo "net test: git does not accept the index of the pack"; exit 1; }
[ "$(find work1/.git/objects -type f -path '*/objects/??/*' | wc -l)" -eq 0 ] || { echo "net test: loose objects after a clone"; exit 1; }
# a person at a terminal sees that something happens
python3 -I - "$JG" "$URL" "$T/seen" <<'PY' || { echo "net test: the progress of a clone"; exit 1; }
import os, pty, sys
pid, fd = pty.fork()
if pid == 0: os.execv(sys.argv[1], ['jgit', 'clone', sys.argv[2], sys.argv[3]])
out = b''
while True:
    try: c = os.read(fd, 4096)
    except OSError: break
    if not c: break
    out += c
assert os.waitpid(pid, 0)[1] == 0, out
for w in (b'receiving', b'objects', b'files', b'cloned'): assert w in out, (w, out)
PY
# --depth 1: only the newest commit
"$JG" clone --depth 1 "$URL" thin > /dev/null || { echo "net test: a shallow clone"; exit 1; }
diff -r seed thin -x .git > /dev/null || { echo "net test: the shallow clone has other files"; exit 1; }
[ "$(git -C thin log --format=%s | tr '\n' ' ')" = "three " ] || { echo "net test: the shallow clone has more than one commit: $(git -C thin log --format=%s)"; exit 1; }
git -C thin fsck > /dev/null 2>&1 || { echo "net test: git fsck of the shallow clone"; exit 1; }
[ "$(cd thin && "$JG" log 2>&1 | grep -c '^commit')" = 1 ] || { echo "net test: jgit log of a shallow clone"; exit 1; }
[ -z "$(cd thin && "$JG" log 2>&1 >/dev/null)" ] || { echo "net test: jgit log of a shallow clone complains"; exit 1; }
# push
cd work1
printf 'changed by jgit\n' > a.txt; mkdir -p new; seq 1 50 > new/list.txt; printf 'x\n' > run2.sh; chmod +x run2.sh
"$JG" add . > /dev/null; "$JG" commit -m "from jgit" > /dev/null
if "$JG" push > /dev/null 2> "$T/err.txt"; then echo "net test: a push without a password must be refused"; exit 1; fi
grep -q "password" "$T/err.txt" || { echo "net test: the message of a push without a password: $(cat "$T/err.txt")"; exit 1; }
"$JG" token 127.0.0.1 tok > /dev/null
"$JG" push > /dev/null || { echo "net test: push"; exit 1; }
cd "$T"
[ "$(git -C srv/repo.git log --format=%s | head -1)" = "from jgit" ] || { echo "net test: the server does not have the commit"; exit 1; }
git -C srv/repo.git fsck --strict > /dev/null 2>&1 || { echo "net test: git fsck finds a problem on the server after the push"; exit 1; }
git clone -q "$URL" real || { echo "net test: a real clone"; exit 1; }
diff -r work1 real -x .git > /dev/null || { echo "net test: a clone made by git has other files than the pushed ones"; exit 1; }
# pull: a commit made by git is taken
cd real; printf 'from real git\n' > from_real.txt; git add .; git commit -qm real; git push -q "http://jgit:tok@127.0.0.1:$PORT/repo.git" main 2>/dev/null
cd ../work1
"$JG" fetch > "$T/pull.txt" || { echo "net test: fetch"; exit 1; }
"$JG" pull > /dev/null || { echo "net test: pull"; exit 1; }
[ "$(cat from_real.txt)" = "from real git" ] || { echo "net test: the pulled file is not there"; exit 1; }
N=$(sed -n 's/^fetched \([0-9]*\) objects.*/\1/p' "$T/pull.txt"); [ -n "$N" ] && [ "$N" -le 5 ] || { echo "net test: a pull must bring only what is new: $(cat "$T/pull.txt")"; exit 1; }
(cd "$T/thin" && "$JG" pull > /dev/null) || { echo "net test: pull in a shallow clone"; exit 1; }
[ "$(cat "$T/thin/from_real.txt")" = "from real git" ] && git -C "$T/thin" fsck > /dev/null 2>&1 || { echo "net test: the shallow clone after a pull"; exit 1; }
git fsck --strict > /dev/null 2>&1 || { echo "net test: git fsck after the pull"; exit 1; }
# the branches changed on both sides: no merge, a clear message, nothing broken
printf 'mine\n' > mine.txt; "$JG" add . > /dev/null; "$JG" commit -m mine > /dev/null
(cd ../real; printf 'theirs\n' > theirs.txt; git add .; git commit -qm theirs; git push -q "http://jgit:tok@127.0.0.1:$PORT/repo.git" main 2>/dev/null)
"$JG" pull > /dev/null 2> "$T/err.txt" && { echo "net test: a pull of changed branches must refuse"; exit 1; }
grep -q "merge" "$T/err.txt" || { echo "net test: the message about the merge"; exit 1; }
"$JG" push > /dev/null 2> "$T/err.txt" && { echo "net test: a push that is behind must refuse"; exit 1; }
grep -q "pull" "$T/err.txt" || { echo "net test: the message to pull first"; exit 1; }
"$JG" remote -v | grep -q "origin" || { echo "net test: remote -v"; exit 1; }
echo "net test: ok"
