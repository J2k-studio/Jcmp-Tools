#!/bin/sh
# test.sh: apkj against the tools that do the same work (aapt2, apksigner, unzip). Needs a makej GL apk in $1 for the native library.
cd "$(dirname "$0")"
A=./_out/apkj; T=$(mktemp -d); ok=0; bad=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); echo "PASS  $1"; else bad=$((bad+1)); echo "FAIL  $1"; fi; }
$A selftest | command grep -q 'selftest ok'; check "ECDSA sign + verify" $?
$A key "$T/k" >/dev/null; check "key made" $?
cat > "$T/m.toml" <<'M'
name = "T"
id = "com.example.apkjtest"
version = "1.2.3"
render = "gl"
M
echo hello > "$T/a.txt"
$A build "$T/m.toml" "$T/o.apk" -k "$T/k" assets/a.txt="$T/a.txt" >/dev/null; check "build" $?
unzip -tq "$T/o.apk" >/dev/null; check "unzip -t" $?
aapt2 dump badging "$T/o.apk" 2>/dev/null | command grep -q "versionCode='10203'"; check "aapt2: versionCode 10203" $?
apksigner verify "$T/o.apk" >/dev/null 2>&1; check "apksigner verify" $?
$A build "$T/m.toml" "$T/o2.apk" -k "$T/k" assets/a.txt="$T/a.txt" >/dev/null
[ "$(apksigner verify --print-certs "$T/o.apk" | command grep -c SHA-256)" = "$(apksigner verify --print-certs "$T/o2.apk" | command grep -c SHA-256)" ]; check "same key twice" $?
printf 'x' >> "$T/o.apk"; apksigner verify "$T/o.apk" >/dev/null 2>&1; [ $? != 0 ]; check "a changed file is rejected" $?
echo "passed $ok, failed $bad"; [ $bad = 0 ]
