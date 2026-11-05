#!/bin/sh
# a pretend learner plays level 1: reads, answers a question, fights, quits (progress in a scratch folder)
set -eu
cd "$(dirname "$0")"
sh ./build.sh >/dev/null
D=$(mktemp -d)
export LEARNJ_DIR="$D"
[ "$(./_out/learnj --version)" = "learnj 0.5.0" ] || { echo "FAIL version"; exit 1; }
OUT=$(printf '2\n\n1\n2\na\na\n0\n' | ./_out/learnj fast 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
echo "$OUT" | grep -q "What is a computer" || { echo "FAIL level title"; exit 1; }
echo "$OUT" | grep -q "Right!" || { echo "FAIL quiz"; exit 1; }
[ -f "$D/learnj_progress.txt" ] || { echo "FAIL progress file"; exit 1; }
echo "learnj tests passed"
