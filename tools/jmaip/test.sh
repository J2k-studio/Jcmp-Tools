#!/bin/sh
# jmaip: the vault, passkeys (sign / verify), encryption with the vault key and with a passkey, tamper and wrong-key refusals, secrets
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
J="$PWD/_out/jmaip"
[ "$($J --version)" = "jmaip $(cat VERSION)" ] || { echo "jmaip test: --version differs from VERSION"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export JMAIP_DIR="$T/vault" JMAIP_PASS="correct horse battery"
ok=0; bad=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); echo "PASS  $1"; else bad=$((bad+1)); echo "FAIL  $1"; fi; }
rc() { r=0; "$@" >/dev/null 2>&1 || r=$?; echo $r; }
[ "$(rc $J key list)" = 1 ]; check "no vault: a command says so" $?
$J init >/dev/null; check "init" $?
[ "$(rc $J init)" = 1 ]; check "init twice is refused" $?
[ "$(stat -c %a "$JMAIP_DIR/master")" = 600 ]; check "the vault key file is mode 600" $?
PUB=$($J key new phone); [ ${#PUB} = 130 ]; check "key new gives 04 + x + y (130 hex digits)" $?
[ "$(rc $J key new phone)" = 1 ]; check "a second key with the name is refused" $?
$J key list | grep -q phone; check "key list" $?
[ "$($J key public phone)" = "$PUB" ]; check "key public" $?
S=$($J key sign phone "hello"); [ ${#S} = 128 ]; check "a signature is 128 hex digits" $?
[ "$($J key sign phone "hello")" = "$S" ]; check "the signature is deterministic" $?
[ "$($J key verify $PUB hello $S)" = valid ]; check "verify: valid" $?
[ "$(rc $J key verify $PUB hellx $S)" = 1 ]; check "verify: another message is NOT valid" $?
echo -n "bytes" > "$T/c.bin"; S2=$($J key sign phone "@$T/c.bin"); [ "$($J key verify $PUB hex:6279746573 $S2)" = valid ]; check "challenge from a file = the same bytes as hex:" $?
head -c 100000 /dev/urandom > "$T/big.bin"
$J enc "$T/big.bin" "$T/big.enc" >/dev/null; $J dec "$T/big.enc" "$T/big.out" >/dev/null; cmp -s "$T/big.bin" "$T/big.out"; check "encrypt and decrypt with the vault key" $?
$J enc -k phone "$T/big.bin" "$T/big.k" >/dev/null; $J dec "$T/big.k" "$T/big.out2" >/dev/null; cmp -s "$T/big.bin" "$T/big.out2"; check "encrypt and decrypt with a passkey" $?
! cmp -s "$T/big.bin" "$T/big.enc"; check "the encrypted file differs" $?
: > "$T/empty"; $J enc "$T/empty" "$T/empty.enc" >/dev/null; $J dec "$T/empty.enc" "$T/empty.out" >/dev/null; cmp -s "$T/empty" "$T/empty.out"; check "an empty file" $?
python3 -c "
d=bytearray(open('$T/big.k','rb').read()); d[200]^=1; open('$T/big.bad','wb').write(d)"
[ "$(rc $J dec "$T/big.bad" "$T/x")" = 1 ]; check "a changed file is refused" $?
[ "$(JMAIP_PASS=wrong-wrong-wrong rc $J dec "$T/big.k" "$T/x")" = 1 ]; check "a wrong passphrase is refused" $?
echo -n "from stdin" | $J enc - | $J dec - | grep -q "from stdin"; check "stdin to stdout" $?
# a passkey of another vault cannot open the file
mkdir "$T/other"; JMAIP_DIR="$T/other" $J init >/dev/null; JMAIP_DIR="$T/other" $J key new phone >/dev/null
[ "$(JMAIP_DIR="$T/other" rc $J dec "$T/big.k" "$T/x")" = 1 ]; check "another vault cannot open a passkey file" $?
# the key from outside (a command that prints the vault key) opens the vault only when it is the right key
$J secret put api-token tok_12345 >/dev/null; [ "$($J secret get api-token)" = tok_12345 ]; check "secret put and get" $?
$J secret list | grep -q api-token; check "secret list" $?
$J secret rm api-token >/dev/null; [ "$(rc $J secret get api-token)" = 1 ]; check "secret rm" $?
JMAIP_MASTERKEY_CMD='echo 0000000000000000000000000000000000000000000000000000000000000000' sh -c "[ \$($J secret list >/dev/null 2>&1; echo \$?) = 1 ]"; check "a wrong key from a command is refused" $?
$J key rm phone >/dev/null; [ "$(rc $J key sign phone x)" = 1 ]; check "key rm" $?
# the API: jmaip serve, a JSON line in and out on 127.0.0.1 with the token of the file api.token
PORT=$((20000 + $$ % 20000))
$J serve --port $PORT > "$T/serve.log" 2>&1 &
SPID=$!
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do [ -f "$JMAIP_DIR/api.token" ] && grep -q listening "$T/serve.log" && break; sleep 0.3; done
cat > "$T/client.py" <<PYEOF
import socket, json, sys
tok = open("$JMAIP_DIR/api.token").read().strip()
def call(obj, token=None):
    obj = dict(obj); obj["token"] = tok if token is None else token
    s = socket.create_connection(("127.0.0.1", $PORT), timeout=20); s.sendall((json.dumps(obj) + "\\n").encode())
    buf = b""
    while not buf.endswith(b"\\n"):
        c = s.recv(65536)
        if not c: break
        buf += c
    s.close(); return json.loads(buf)
fails = []
def check(name, cond):
    print(("PASS  " if cond else "FAIL  ") + name)
    if not cond: fails.append(name)
check("api: ping", call({"cmd": "ping"}).get("ok") is True)
check("api: a wrong token is denied", call({"cmd": "ping"}, token="nope").get("error") == "denied")
call({"cmd": "secret.put", "name": "t", "value": "v1"})
check("api: secret put and get", call({"cmd": "secret.get", "name": "t"}).get("value") == "v1")
check("api: key.list has the passkey of the tests", any(k["name"] == "other" for k in call({"cmd": "key.list"}).get("keys", [])))
call({"cmd": "key.sign", "name": "other", "challenge": "c"})
sig = call({"cmd": "key.sign", "name": "other", "challenge": "login:1"})
pub = call({"cmd": "key.public", "name": "other"})["public"]
check("api: sign then verify is valid", call({"cmd": "key.verify", "public": pub, "challenge": "login:1", "signature": sig["signature"]}).get("valid") is True)
check("api: another challenge is not valid", call({"cmd": "key.verify", "public": pub, "challenge": "login:2", "signature": sig["signature"]}).get("valid") is False)
e = call({"cmd": "enc", "data_hex": b"hello".hex(), "key": "other"})
check("api: enc then dec", bytes.fromhex(call({"cmd": "dec", "data_hex": e["data_hex"]})["data_hex"]) == b"hello")
check("api: an unknown command is an error", call({"cmd": "zzz"}).get("ok") is False)
made = call({"cmd": "key.new", "name": "made-by-api"})
check("api: key.new makes a passkey (130 hex digits)", made.get("ok") is True and len(made.get("public", "")) == 130)
check("api: key.new twice is refused", call({"cmd": "key.new", "name": "made-by-api"}).get("ok") is False)
check("api: key.rm removes it", call({"cmd": "key.rm", "name": "made-by-api"}).get("ok") is True and call({"cmd": "key.public", "name": "made-by-api"}).get("ok") is False)
sys.exit(1 if fails else 0)
PYEOF
$J key new other >/dev/null
python3 "$T/client.py" > "$T/client.out" 2>&1 || true
cat "$T/client.out"
kill $SPID 2>/dev/null || true
wait $SPID 2>/dev/null || true
np=$(grep -c '^PASS' "$T/client.out" || true); nf=$(grep -c '^FAIL' "$T/client.out" || true)
ok=$((ok + np)); bad=$((bad + nf))
if grep -qv '^PASS\|^FAIL' "$T/client.out"; then x=1; else x=0; fi; check "api: the client ran without errors" $x
echo "passed $ok, failed $bad"; [ $bad = 0 ]
