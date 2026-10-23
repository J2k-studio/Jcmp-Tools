#!/bin/sh
# neuron: train a tiny model on a tiny text, write on from it, talk with it, make it the assistant, read a numeric model
set -eu
cd "$(dirname "$0")"; export J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}"; sh build.sh >/dev/null
N="$PWD/_out/neuron"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T"
[ "$("$N" --version)" = "neuron 0.2.0" ] || { echo "neuron test: version"; exit 1; }
i=0; : > "$T/chat.txt"
while [ $i -lt 40 ]; do printf 'You: hello\nBot: Hi! I am your helper.\nYou: bye\nBot: Goodbye!\n' >> "$T/chat.txt"; i=$((i+1)); done
"$N" train "$T/chat.txt" -o "$T/chat.jw" -k 10 -d 6 -h 48 -e 6 -r 0.08 > "$T/train.txt" || { cat "$T/train.txt"; echo "neuron test: train"; exit 1; }
grep -q "saved" "$T/train.txt" || { echo "neuron test: train did not save"; exit 1; }
"$N" info "$T/chat.jw" | grep -q "language model" || { echo "neuron test: info"; exit 1; }
out=$("$N" run "$T/chat.jw" "You: hello
Bot: " -n 18 -t 0)
case "$out" in *"Hi! I am your help"*) ;; *) echo "neuron test: run wrote: $out"; exit 1 ;; esac
"$N" install "$T/chat.jw" > /dev/null; [ -f "$T/.neuron/assistant.jw" ] || { echo "neuron test: install"; exit 1; }
out=$(printf 'bye\n\n' | "$N" chat -t 0 2>&1)
case "$out" in *"Goodbye!"*) ;; *) echo "neuron test: chat said: $out"; exit 1 ;; esac
"$N" run "$T/missing.jw" "x" > /dev/null 2>&1 && { echo "neuron test: a missing model must fail"; exit 1; }
printf 'neuron-jw 1\nlayers 1\n2 1\n1 1 \n0 \n' > "$T/sum.jw"
[ "$("$N" ask "$T/sum.jw" 3 4)" = "7" ] || { echo "neuron test: ask: $("$N" ask "$T/sum.jw" 3 4)"; exit 1; }
# xaiorin (xr): the same program under another name; the background program answers, stops, and without it the model is loaded
cp "$N" "$T/xr"; printf '[#jash]\n[xr]\nport = 7793\ntemperature = 0\n' > "$T/.jash"
"$T/xr" status | grep -q "not running" || { echo "neuron test: xr status before start"; exit 1; }
"$T/xr" "hello" | grep -q "Hi! I am your helper." || { echo "neuron test: xr without the server"; exit 1; }
"$T/xr" start > /dev/null; "$T/xr" status | grep -q "runs (port 7793)" || { echo "neuron test: xr start"; exit 1; }
"$T/xr" "bye" | grep -q "Goodbye!" || { echo "neuron test: xr through the server"; exit 1; }
"$T/xr" stop > /dev/null; "$T/xr" status | grep -q "not running" || { echo "neuron test: xr stop"; exit 1; }
echo "neuron tests: ok"
