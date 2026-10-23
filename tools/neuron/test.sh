#!/bin/sh
# neuron: train a tiny model on a tiny text, write on from it, talk with it, make it the assistant, read a numeric model
set -eu
cd "$(dirname "$0")"; export J2K_PATH="${J2K_PATH:-$HOME/Jcmp/build/libs}"; sh build.sh >/dev/null
N="$PWD/_out/neuron"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T"
[ "$("$N" --version)" = "neuron 0.4.0" ] || { echo "neuron test: version"; exit 1; }
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
# the search before the model: a question put in other words gets the answer of the like one
i=0; : > "$T/qa.txt"
while [ $i -lt 20 ]; do printf 'You: how do i stop a program\nBot: Run jamanager kill PID.\nYou: how do i play music\nBot: Type mujic.\nYou: hello\nBot: Hi!\n' >> "$T/qa.txt"; i=$((i+1)); done
"$N" train "$T/qa.txt" -o "$T/qa.jw" -k 8 -d 6 -h 32 -e 2 -r 0.02 > "$T/qa_train.txt" || { echo "neuron test: train qa"; exit 1; }
grep -q "3 questions with answers" "$T/qa_train.txt" || { echo "neuron test: the pairs were not counted: $(head -n 1 "$T/qa_train.txt")"; exit 1; }
"$N" install "$T/qa.jw" > /dev/null
[ "$("$T/xr" "how to stop a program?")" = "Run jamanager kill PID." ] || { echo "neuron test: search: $("$T/xr" "how to stop a program?")"; exit 1; }
[ "$("$T/xr" "How do I PLAY music")" = "Type mujic." ] || { echo "neuron test: search 2"; exit 1; }
printf '[#jash]\n[xr]\nport = 7794\nsearch = off\n' > "$T/.jash"
[ "$("$T/xr" "how to stop a program?")" != "Run jamanager kill PID." ] || { echo "neuron test: search = off must leave it to the model"; exit 1; }
"$N" where | grep -q "assistant.jw" || { echo "neuron test: where"; exit 1; }
echo "neuron tests: ok"
