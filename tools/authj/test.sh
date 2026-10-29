#!/bin/sh
# authj: the codes of the RFC 6238 test table (SHA-1, SHA-256, SHA-512), the same codes as Python for other secrets, the vault (add, list, remove,
# lock with a passphrase, a wrong passphrase, a changed file), the otpauth:// text
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/authj --version)" = "authj $(cat VERSION)" ] || { echo "authj test: --version differs from VERSION"; exit 1; }
./_out/authj --help > /dev/null || { echo "authj test: --help"; exit 1; }
A="$PWD/_out/authj"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export AUTHJ_DIR="$T/vault"
b32() { python3 -I -c "import base64,sys;print(base64.b32encode(sys.argv[1].encode()).decode())" "$1"; }
S1=$(b32 12345678901234567890)
S256=$(b32 12345678901234567890123456789012)
S512=$(b32 1234567890123456789012345678901234567890123456789012345678901234)
chk() { got=$(AUTHJ_NOW=$2 "$A" now "$1" --digits 8 ${4:+--algo $4} | cut -d' ' -f1); [ "$got" = "$3" ] || { echo "authj test: RFC 6238 $4 time $2: got $got, wanted $3"; exit 1; }; }
chk $S1 59 94287082;           chk $S1 1111111109 07081804;  chk $S1 1111111111 14050471; chk $S1 1234567890 89005924
chk $S1 2000000000 69279037;   chk $S1 20000000000 65353130
chk $S256 59 46119246 sha256;  chk $S256 1111111109 68084774 sha256; chk $S256 20000000000 77737706 sha256
chk $S512 59 90693936 sha512;  chk $S512 1111111109 25091201 sha512; chk $S512 20000000000 47863826 sha512
# other secrets and times against Python (6 digits, and an odd secret with spaces and lower case)
python3 -I - "$A" <<'PY' || { echo "authj test: codes differ from Python"; exit 1; }
import sys,hmac,hashlib,struct,base64,subprocess,os,random
random.seed(7)
def totp(key,t,digits=6,period=30,algo=hashlib.sha1):
    h=hmac.new(key,struct.pack('>Q',t//period),algo).digest(); o=h[-1]&15
    return str((struct.unpack('>I',h[o:o+4])[0]&0x7fffffff)%10**digits).zfill(digits)
for i in range(25):
    key=bytes(random.randrange(256) for _ in range(random.choice([10,16,20,33,70])))
    t=random.randrange(10**9,2*10**9)
    sec=base64.b32encode(key).decode().rstrip('=')
    d=random.choice([6,7,8]); p=random.choice([30,60])
    algo=random.choice(['sha1','sha256','sha512'])
    env=dict(os.environ,AUTHJ_NOW=str(t))
    out=subprocess.run([sys.argv[1],'now',sec.lower(),'--digits',str(d),'--period',str(p),'--algo',algo],env=env,capture_output=True,text=True).stdout.split()[0]
    want=totp(key,t,d,p,getattr(hashlib,algo))
    assert out==want,(i,algo,d,p,out,want)
PY
# the vault, without a lock
"$A" add github "$S1" > /dev/null || { echo "authj test: add"; exit 1; }
"$A" add work JBSWY3DPEHPK3PXP --digits 8 --period 60 > /dev/null
"$A" list | grep -q "github" || { echo "authj test: list"; exit 1; }
"$A" list | grep -q "work  (8 digits, 60 s" || { echo "authj test: list shows the settings"; exit 1; }
[ "$(AUTHJ_NOW=59 "$A" code github | cut -d' ' -f1)" = "287082" ] || { echo "authj test: code of github at 59 (the last 6 of 94287082)"; exit 1; }
AUTHJ_NOW=59 "$A" code | grep -c . | grep -q 2 || { echo "authj test: code of all"; exit 1; }
AUTHJ_NOW=59 "$A" git 2>/dev/null | grep -q github || { echo "authj test: a part of a name"; exit 1; }
[ "$(stat -c %a "$T/vault/vault")" = "600" ] || { echo "authj test: the vault must be mode 600"; exit 1; }
"$A" add-uri 'otpauth://totp/GitHub:me%40mail.com?secret=jbswy3dpehpk3pxp&issuer=GitHub&digits=7&period=45' > /dev/null || { echo "authj test: add-uri"; exit 1; }
"$A" list | grep -q "GitHub:me@mail.com  (7 digits, 45 s, sha1)" || { echo "authj test: add-uri name and settings"; exit 1; }
"$A" remove work > /dev/null; if "$A" code work 2>/dev/null; then echo "authj test: removed account still there"; exit 1; fi
if "$A" add bad "0189" 2>/dev/null; then echo "authj test: a secret that is not base32 must be refused"; exit 1; fi
# the lock
AUTHJ_PASS=secret1 "$A" passwd > /dev/null || { echo "authj test: passwd"; exit 1; }
head -c 6 "$T/vault/vault" | grep -q AUTHJ1 || { echo "authj test: the vault must be locked"; exit 1; }
grep -q JBSWY3DPEHPK3PXP "$T/vault/vault" && { echo "authj test: the secret is visible in a locked vault"; exit 1; }
[ "$(AUTHJ_PASS=secret1 AUTHJ_NOW=59 "$A" code github | cut -d' ' -f1)" = "287082" ] || { echo "authj test: code from a locked vault"; exit 1; }
if AUTHJ_PASS=wrong "$A" list > /dev/null 2>&1; then echo "authj test: a wrong passphrase must fail"; exit 1; fi
cp "$T/vault/vault" "$T/vault/vault.bak"
python3 -I -c "
d=bytearray(open('$T/vault/vault','rb').read()); d[60]^=1; open('$T/vault/vault','wb').write(d)"
if AUTHJ_PASS=secret1 "$A" list > /dev/null 2>&1; then echo "authj test: a changed vault must be refused"; exit 1; fi
cp "$T/vault/vault.bak" "$T/vault/vault"
AUTHJ_PASS=secret1 "$A" add more JBSWY3DPEHPK3PXP > /dev/null || { echo "authj test: add to a locked vault"; exit 1; }
head -c 6 "$T/vault/vault" | grep -q AUTHJ1 || { echo "authj test: still locked after add"; exit 1; }
AUTHJ_PASS="" "$A" passwd > /dev/null 2>&1 || true
echo "authj tests passed"
