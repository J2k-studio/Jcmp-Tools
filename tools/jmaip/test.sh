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
echo "passed $ok, failed $bad"; [ $bad = 0 ]
