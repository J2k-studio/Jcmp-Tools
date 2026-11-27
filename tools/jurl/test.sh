#!/data/data/com.termux/files/usr/bin/bash
# test.sh [JCMP] -- build jurl with the compiler JCMP (default: jcmp) and test it. Prints PASS or FAIL lines; the exit code is the number of failures.
# Needs: jcmp with its Library (JCMP_LIB if the library is not next to it), python3 (a local web server for the http:// tests), sha256sum.
cd "$(dirname "$0")" || exit 1
HERE=$PWD
JCMP=${1:-jcmp}
W=${TMPDIR:-/tmp}/jurl_test.$$
mkdir -p "$W/src" "$W/lib" "$W/out" "$W/www" || exit 1
FAILS=0
ok()  { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; FAILS=$((FAILS+1)); }
t()   { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
# jurl imports the library deflate (jurl -li install deflate, or the folder of the Jcmp sources: build/libs)
[ -z "${J2K_PATH:-}" ] && [ -d "$HOME/Jcmp/build/libs" ] && export J2K_PATH="$HOME/Jcmp/build/libs"
$JCMP jurl.jk -o "$W/jurl" >"$W/build.txt" 2>&1 || { cat "$W/build.txt"; echo "FAIL  jurl does not build"; exit 1; }
J="$W/jurl"
( cd "$HERE/../ex" && $JCMP ex.jk -o "$W/ex" ) >"$W/build_ex.txt" 2>&1 || { cat "$W/build_ex.txt"; echo "FAIL  ex does not build"; exit 1; }
( cd "$HERE/../jex" && $JCMP jex.jk -o "$W/jex" ) >"$W/build_jex.txt" 2>&1 || { cat "$W/build_jex.txt"; echo "FAIL  jex does not build"; exit 1; }
export PATH="$W:$PATH"                                      # jurl -li ... and jurl tool ... are sent to ex and jex
mkdir -p "$W/tz/src/sub"; echo hello > "$W/tz/src/a.txt"; echo deep > "$W/tz/src/sub/b.txt"
( cd "$W/tz" && tar czf t.tar.gz src && tar cf t.tar src )
mkdir "$W/tz/o1" "$W/tz/o2"
"$J" untar "$W/tz/t.tar" "$W/tz/o1" && "$J" untar "$W/tz/t.tar.gz" "$W/tz/o2"
chmod 755 "$W/tz/src/a.txt"; ( cd "$W/tz" && tar cf t2.tar src ); mkdir "$W/tz/o3"; "$J" untar "$W/tz/t2.tar" "$W/tz/o3"
t "untar: the x bit is kept" '[ -x "$W/tz/o3/src/a.txt" ] && [ ! -x "$W/tz/o3/src/sub/b.txt" ]'
t "untar: a tar and a gzip-packed tar" '[ "$(cat "$W/tz/o1/src/sub/b.txt")" = deep ] && [ "$(cat "$W/tz/o2/src/a.txt")" = hello ]'
head -c 300000 /dev/urandom > "$W/www/big.bin"
printf 'hello jurl\n' > "$W/www/page.txt"
printf '#!/bin/sh\necho "ran with $1"\n' > "$W/www/hello.sh"
printf '\177ELFxxxx' > "$W/www/prog.bin"
printf 'int twice(int x) { return x * 2; }\n' > "$W/www/twice.j"
H=$(sha256sum "$W/www/twice.j" | cut -d' ' -f1)
PORT=$((20000 + $$ % 20000))
(cd "$W/www" && exec python3 -m http.server $PORT --bind 127.0.0.1 >/dev/null 2>&1) &
SRV=$!
# wait until the server answers (a fixed sleep is too short on a loaded phone)
for w in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do (exec 3<>/dev/tcp/127.0.0.1/$PORT) 2>/dev/null && break; sleep 0.5; done
printf '# index\ntwice 1.0 http://127.0.0.1:%s/nothing_here.j|http://127.0.0.1:%s/twice.j %s\nbad 1.0 http://127.0.0.1:%s/twice.j 0000\n' $PORT $PORT "$H" $PORT > "$W/index.txt"
cd "$W/out" || exit 1
t "version" '[ "$($J --version)" = "jurl $(cat $HERE/VERSION)" ]'
t "download: -O names the file after the address (the default in a terminal)" '$J -q -O http://127.0.0.1:$PORT/big.bin && cmp -s big.bin ../www/big.bin'
# several addresses, a folder (-P), a list (-i), tries (-r)
mkdir -p "$W/out/multi" && cd "$W/out/multi"
t "download: several addresses, each under its own name" '$J -q http://127.0.0.1:$PORT/page.txt http://127.0.0.1:$PORT/twice.j && [ "$(cat page.txt)" = "hello jurl" ] && cmp -s twice.j ../../www/twice.j'
t "download: -P puts the files into a folder (made when missing)" '$J -q -P sub/dir http://127.0.0.1:$PORT/page.txt && [ "$(cat sub/dir/page.txt)" = "hello jurl" ]'
printf '# a list\nhttp://127.0.0.1:%s/hello.sh\n\nhttp://127.0.0.1:%s/prog.bin\n' $PORT $PORT > list.txt
t "download: -l reads the addresses from a file" '$J -q -P fromlist -l list.txt && [ -f fromlist/hello.sh ] && [ -f fromlist/prog.bin ]'
t "download: one bad address in several: the others come, the exit code says it" '$J -q http://127.0.0.1:$PORT/nothing_here.xyz http://127.0.0.1:$PORT/page.txt 2>/dev/null; [ $? -ne 0 ] && [ -f page.txt ]'
t "download: -o with several addresses is refused" '! $J -q -o x http://127.0.0.1:$PORT/page.txt http://127.0.0.1:$PORT/twice.j 2>/dev/null'
t "download: -r tries a mirror list again and ends with an error when nothing works" '! $J -q -r 2 http://127.0.0.1:$PORT/no1.zz 2>/dev/null'
cd "$W/out"
t "download: -o names the file" '$J -q http://127.0.0.1:$PORT/page.txt -o mine.txt && [ "$(cat mine.txt)" = "hello jurl" ]'
t "download: -o - writes to the screen" '[ "$($J http://127.0.0.1:$PORT/page.txt -o - 2>/dev/null)" = "hello jurl" ]'
t "download: -h URL is the same" '$J -q -h http://127.0.0.1:$PORT/page.txt -o h.txt && [ "$(cat h.txt)" = "hello jurl" ]'
# the commands people copy from the web are written for curl: jurl understands their flags, in a bundle and by their long names, in any order
U=http://127.0.0.1:$PORT
mkdir -p "$W/out/curl" && cd "$W/out/curl"
t "curl: -fsSL prints the answer" '[ "$($J -fsSL $U/page.txt 2>&1)" = "hello jurl" ]'
t "curl: -fsSL URL | sh" '[ "$($J -fsSL $U/hello.sh | sh -s -- there)" = "ran with there" ]'
t "curl: -sSfL and long names" '[ "$($J --silent --show-error --fail --location $U/page.txt 2>&1)" = "hello jurl" ]'
t "curl: -LO saves under the name of the address" '$J -LOs $U/page.txt && [ "$(cat page.txt)" = "hello jurl" ]'
t "curl: -sSLo FILE" '$J -sSLo one.txt $U/page.txt && [ "$(cat one.txt)" = "hello jurl" ]'
t "curl: -ofile with the name attached" '$J -s -otwo.txt $U/page.txt && [ "$(cat two.txt)" = "hello jurl" ]'
t "curl: -o before the address" '$J -s -o three.txt $U/page.txt && [ "$(cat three.txt)" = "hello jurl" ]'
t "curl: --output after the address" '$J $U/page.txt --silent --output four.txt && [ "$(cat four.txt)" = "hello jurl" ]'
t "curl: -f on a page that is not there: it fails and prints nothing" 'out=$($J -fsSL $U/nothing.zz 2>/dev/null); [ $? -ne 0 ] && [ -z "$out" ]'
t "curl: -sI shows the head only" '$J -sI $U/page.txt > head.txt && grep -qi "^content-length: 11" head.txt && ! grep -q "hello jurl" head.txt'
t "curl: flags that change nothing here are taken" '[ "$($J -fsSL --compressed --retry 2 --max-time 30 --connect-timeout 5 -4 $U/page.txt 2>&1)" = "hello jurl" ]'
t "curl: -k is refused (certificates are always checked)" 'out=$($J -k $U/page.txt 2>&1); [ $? -ne 0 ] && echo "$out" | grep -q certificate'
t "help: short, with examples, narrow" '$J --help > help.txt 2>&1; grep -q "jurl -fsSL LINK" help.txt && [ "$(awk "length > 40" help.txt | wc -l)" = 0 ]'
t "help: --help-all has the rest" '$J --help-all 2>&1 | grep -q -- "-P DIR"'
cd "$W/out"
PORT2=$((PORT + 2))
(cd "$HERE" && exec python3 echo_server.py $PORT2 >/dev/null 2>&1) &
for w in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do (exec 3<>/dev/tcp/127.0.0.1/$PORT2) 2>/dev/null && break; sleep 0.5; done
t "request: -d sends a POST with the data (and joins two -d with &)" '[ "$($J -d a=1 -d b=2 http://127.0.0.1:$PORT2/echo)" = "POST:a=1&b=2" ]'
t "request: -X and -H" '$J -i -X POST -H "X-Test: seven" -d z http://127.0.0.1:$PORT2/echo | grep -q "^X-Got: seven"'
t "request: -d @file reads the data from a file" 'printf "from file" > "$W/body.txt" && [ "$($J -d @$W/body.txt http://127.0.0.1:$PORT2/echo)" = "POST:from file" ]'
t "request: -u sends Basic authorization" '$J -i -u me:pw http://127.0.0.1:$PORT2/q | grep -q "^X-Auth: Basic bWU6cHc="'
t "request: a redirect is followed (and --no-location stops it)" '[ "$($J -H "A: b" http://127.0.0.1:$PORT2/r)" = "GET /echo" ] && $J -i --no-location http://127.0.0.1:$PORT2/r | head -1 | grep -q 302'
t "request: -I asks for the head only" '$J -I http://127.0.0.1:$PORT2/x | head -1 | grep -q "200" && [ -z "$($J -I http://127.0.0.1:$PORT2/x | tail -n +20 | tr -d "\r\n")" ]'
t "request: -f makes a 404 an error (exit 22), without it the body is shown" '$J -f -H "A: b" http://127.0.0.1:$PORT2/nf >/dev/null 2>&1; [ $? = 22 ] && [ "$($J -H "A: b" http://127.0.0.1:$PORT2/nf)" = "GET /nf" ]'
t "request: -o writes the answer to a file" '$J -H "A: b" -o "$W/ans.txt" http://127.0.0.1:$PORT2/file && [ "$(cat "$W/ans.txt")" = "GET /file" ]'
t "download: -x makes the file executable" '$J -q -x http://127.0.0.1:$PORT/hello.sh -o x.sh && [ -x x.sh ] && [ "$(./x.sh a)" = "ran with a" ]'
t "download: a script is made executable by itself" '$J -q http://127.0.0.1:$PORT/hello.sh -o y.sh && [ -x y.sh ] && [ "$(./y.sh b)" = "ran with b" ]'
t "download: an ordinary file is not made executable" '$J -q http://127.0.0.1:$PORT/page.txt -o plain.txt && [ ! -x plain.txt ]'
t "download: a program (ELF) is made executable by itself" '$J -q http://127.0.0.1:$PORT/prog.bin -o prog.bin && [ -x prog.bin ]'
mkdir -p "$W/bin"; printf '#!/bin/sh\necho "via jsh"\nexec sh "$@"\n' > "$W/bin/jsh"; chmod +x "$W/bin/jsh"
printf 'run_net = never\n' > "$W/never.conf"; printf 'run_net = allow\n' > "$W/allow.conf"
t "run_net = never: the script is not run" '[ -z "$(JGET_CONFIG="$W/never.conf" $J -sh http://127.0.0.1:$PORT/hello.sh one 2>/dev/null)" ]'
t "run_net = allow: the script is run" '[ "$(JGET_CONFIG="$W/allow.conf" $J -sh http://127.0.0.1:$PORT/hello.sh one 2>/dev/null)" = "ran with one" ]'
cat > "$W/ask.py" <<'PY'
import pty, os, sys, time, select
answer, jurl, url = sys.argv[1], sys.argv[2], sys.argv[3]
pid, fd = pty.fork()
if pid == 0:
    os.environ['JGET_CONFIG'] = '/nonexistent'
    os.execv(jurl, ['jurl', '-sh', url, 'one'])
out = b''
asked = False
end = time.time() + 15
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 0.2)
    if r:
        try: d = os.read(fd, 65536)
        except OSError: break
        if not d: break
        out += d
        if b'Run it?' in out and not asked:
            asked = True
            os.write(fd, answer.encode() + b'\r')
txt = out.decode(errors='ignore')
print('ASKED' if 'Run it?' in txt else 'NOT-ASKED')
print('RAN' if 'ran with one' in txt else 'NOT-RAN')
PY
t "run_net = ask at a terminal: the first lines are shown and n does not run" 'python3 "$W/ask.py" n "$J" http://127.0.0.1:$PORT/hello.sh | tr "\n" " " | grep -q "ASKED NOT-RAN"'
t "run_net = ask at a terminal: y runs it" 'python3 "$W/ask.py" y "$J" http://127.0.0.1:$PORT/hello.sh | tr "\n" " " | grep -q "ASKED RAN"'
t "-jsh: the script is run by the program jsh, with the arguments" '[ "$(PATH="$W/bin:$PATH" $J -jsh http://127.0.0.1:$PORT/hello.sh two 2>/dev/null | tr "\n" "|")" = "via jsh|ran with two|" ]'
t "-sh: downloads a script, runs it with the arguments, leaves nothing" '[ "$($J -sh http://127.0.0.1:$PORT/hello.sh one 2>/dev/null)" = "ran with one" ]'
t "pipe: with no -o the data goes to the output (jurl URL | sh)" '[ "$($J -q http://127.0.0.1:$PORT/page.txt)" = "hello jurl" ] && [ ! -e page.txt ]'
t "pipe: a script goes to sh and runs" '[ "$($J -q http://127.0.0.1:$PORT/hello.sh | sh -s one)" = "ran with one" ]'
t "download: no .part file is left" '[ -z "$(ls | grep part)" ]'
t "download: an error status fails and leaves no file" '! $J -q -O http://127.0.0.1:$PORT/missing.bin 2>/dev/null && [ ! -e missing.bin ]'
t "download: file:// goes to curl" '$J -q file://$W/www/page.txt -o f.txt && [ "$(cat f.txt)" = "hello jurl" ]'
t "download: a bad address" '! $J -q nosuch://x/y 2>/dev/null; true'
export JGET_INDEX="http://127.0.0.1:1/none http://127.0.0.1:$PORT/../index.txt file://$W/index.txt" JGET_LIB="$W/lib"
t "libraries: list (the first index is down, the mirror is used)" '$J -li list 2>/dev/null | grep -q "twice 1.0"'
t "libraries: install (the first address of the file is 404, the mirror works)" '$J -q -li install twice >/dev/null 2>&1 && cmp -s "$W/lib/twice.j" "$W/www/twice.j"'
t "libraries: list marks the installed one" '$J -li list 2>/dev/null | grep -q "^\* twice"'
t "libraries: a wrong checksum installs nothing" '! $J -q -li install bad >/dev/null 2>&1 && [ ! -f "$W/lib/bad.j" ]'
t "libraries: a bad name" '! $J -li install ../x >/dev/null 2>&1'
t "libraries: the standard ones need no install" '$J -li install cpu 2>&1 | grep -q "standard library" && [ ! -f "$W/lib/cpu.j" ]'
t "libraries: installed lists the folder" '$J -li installed | grep -q twice'
printf '#import <twice>\nvoid main(){ jout << twice(21) << nl; }\n' > "$W/use.jk"
t "libraries: the installed library can be imported" 'J2K_PATH="$W/lib" $JCMP "$W/use.jk" -o "$W/use" >/dev/null 2>&1 && [ "$($W/use)" = "42" ]'
t "libraries: unstall (uninstall and remove also work)" '$J -li unstall twice >/dev/null 2>&1 && [ ! -f "$W/lib/twice.j" ]'
unset JGET_INDEX JGET_LIB
if command -v openssl >/dev/null 2>&1; then
    # https against a server of our own: a CA made here, a certificate for localhost
    (cd "$W/www" && openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout ca.key -out ca.pem -days 2 -subj "/CN=jurl test CA" -addext "basicConstraints=critical,CA:TRUE" >/dev/null 2>&1 &&
     openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout key.pem -out leaf.csr -subj "/CN=localhost" >/dev/null 2>&1 &&
     printf 'subjectAltName=DNS:localhost\nbasicConstraints=CA:FALSE\n' > leaf.ext &&
     openssl x509 -req -in leaf.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out cert.pem -days 2 -sha256 -extfile leaf.ext >/dev/null 2>&1)
    SPORT=$((PORT + 1))
    (cd "$W/www" && exec openssl s_server -accept $SPORT -cert cert.pem -key key.pem -tls1_3 -ciphersuites TLS_CHACHA20_POLY1305_SHA256 -WWW -quiet >/dev/null 2>&1) &
    SSRV=$!
    sleep 1
    t "https: a file from a server whose certificate is trusted" 'J2K_CA="$W/www/ca.pem" $J -q https://localhost:$SPORT/page.txt -o s.txt && [ "$(cat s.txt)" = "hello jurl" ]'
    t "https: the certificate of an unknown CA is refused and not retried" '! J2K_CA="$W/www/page.txt" $J -q https://localhost:$SPORT/page.txt -o s2.txt 2>"$W/err.txt" && grep -q "not trusted" "$W/err.txt" && [ ! -e s2.txt ]'
    t "https: the wrong name is refused" '! J2K_CA="$W/www/ca.pem" $J -q https://127.0.0.1:$SPORT/page.txt -o s3.txt 2>"$W/err.txt" && grep -q "not made for the name" "$W/err.txt"'
    kill $SSRV 2>/dev/null
else
    echo "SKIP  https tests (no openssl here)"
fi
kill $SRV 2>/dev/null
# jurl tool update / unstall against a mirror on this machine (JCMPTOOLS_RAW, JCMPTOOLS_DL): update = jsh and the installed tools that have a newer version
M="$W/mirror"; mkdir -p "$M/tools/jsh" "$M/tools/foo" "$M/tools/bar" "$M/dl/jsh-v0.3.0" "$M/dl/foo-v1.0.0" "$M/dl/bar-v1.0.0"
printf '# tools\njsh|the shell\nfoo|a tool\nbar|another tool\n' > "$M/tools.txt"
printf 'jsh 0.3.0\nfoo 1.0.0\nbar 1.0.0\n' > "$M/versions.txt"
echo 0.3.0 > "$M/tools/jsh/LATEST"; echo 1.0.0 > "$M/tools/foo/LATEST"; echo 1.0.0 > "$M/tools/bar/LATEST"
mkfake() { printf '#!/bin/sh\necho "%s %s"\n' "$2" "$3" > "$M/dl/$2-v$3/$2"; ( cd "$M/dl/$2-v$3" && sha256sum "$2" > SHA256SUMS ); }
mkfake x jsh 0.3.0; mkfake x foo 1.0.0; mkfake x bar 1.0.0
TB="$W/tbin"; mkdir -p "$TB"; cp "$J" "$TB/jurl"; cp "$W/ex" "$TB/ex"; cp "$W/jex" "$TB/jex"
printf '#!/bin/sh\necho "jsh 0.1.0"\n' > "$TB/jsh"; chmod 755 "$TB/jsh"
printf '#!/bin/sh\necho "foo 1.0.0"\n' > "$TB/foo"; chmod 755 "$TB/foo"
TE="JCMPTOOLS_RAW=file://$M JCMPTOOLS_DL=file://$M/dl"
# at a terminal jurl says where the file went (a person who types  jurl LINK  saw nothing)
SV=$(mktemp -d); printf 'twelve bytes' > "$SV/source.bin"; mkdir "$SV/into"
got=$(cd "$SV/into" && python3 -I -c 'import os, pty, sys
pid, fd = pty.fork()
if pid == 0: os.execv(sys.argv[1], ["jurl", sys.argv[2]])
out = b""
while True:
    try: c = os.read(fd, 4096)
    except OSError: break
    if not c: break
    out += c
os.waitpid(pid, 0); sys.stdout.write(out.decode(errors="replace"))' "$J" "file://$SV/source.bin")
case "$got" in *"saved source.bin (12 B)"*) ;; *) echo "jurl: FAIL: no word about the saved file: $got"; FAILS=$((FAILS+1)) ;; esac
got=$(cd "$SV/into" && "$J" -O "file://$SV/source.bin" 2>&1 >/dev/null); [ -z "$got" ] || { echo "jurl: FAIL: a script must hear nothing: $got"; FAILS=$((FAILS+1)); }
rm -rf "$SV"
cd / ; rm -rf "$W"
echo "jurl: $FAILS failures"
exit $FAILS
