#!/bin/sh
# ask: finds the right passage in a folder of texts, English and Thai, and says so when nothing is found
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
N="$PWD/_out/ask"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
[ "$("$N" --version)" = "ask 0.1.0" ] || { echo "ask test: version"; exit 1; }
printf '# Files\n\nTo open a file use Fs::read.\n\nA file closes at the end.\n' > "$T/files.md"
printf '# Math\n\nMath::sqrt gives the square root of a number.\n' > "$T/math.md"
printf '# ไทย\n\nการเปิดไฟล์ใช้ Fs::read\n' > "$T/thai.md"
"$N" -d "$T" -n 1 square root | grep -q "math.md" || { echo "ask test: square root"; exit 1; }
"$N" -d "$T" -n 1 open a file | grep -q "files.md" || { echo "ask test: open a file"; exit 1; }
"$N" -d "$T" -n 1 เปิดไฟล์ | grep -q "thai.md" || { echo "ask test: thai"; exit 1; }
if "$N" -d "$T" zzzzqqq > /dev/null; then echo "ask test: a question with no answer must fail"; exit 1; fi
echo "ask test: ok"
