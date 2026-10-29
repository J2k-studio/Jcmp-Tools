#!/bin/sh
# mulap: a plan becomes a WAV file: the format, the length, the loudness, the hits are where the pattern says, a rest is quiet, bad plans fail
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
M="$PWD/_out/mulap"
[ "$("$M" --version)" = "mulap $(cat VERSION)" ] || { echo "mulap test: --version"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
printf 'bpm = 120\nbars = 2\ntrack kick x...x...x...x...\ntrack snare ....x.......x...  gain 0.9\n' > "$T/a.mlp"
"$M" render "$T/a.mlp" "$T/a.wav" | grep -q "2 bars at 120 bpm" || { echo "mulap test: render"; exit 1; }
python3 -I - "$T/a.wav" <<'PY' || { echo "mulap test: the sound"; exit 1; }
import sys, wave, struct, math
w = wave.open(sys.argv[1])
assert (w.getframerate(), w.getnchannels(), w.getsampwidth()) == (44100, 1, 2), 'format'
n = w.getnframes()
d = struct.unpack('<%dh' % n, w.readframes(n))
step = int(60 / 120 / 4 * 44100)
assert abs(n - (2 * 16 * step + int(0.7 * 44100))) <= 2, 'length %d' % n
peak = max(abs(x) for x in d)
assert 28000 < peak < 30500, 'peak %d' % peak                      # about 0.9 of full
def rms(a, b):
    s = d[a:b]; return math.sqrt(sum(x * x for x in s) / len(s))
hit = rms(0, 1500)                                                # the kick of step 0
rest = rms(step * 2 + 6000, step * 2 + 7500)                      # step 2 is a rest, the kick has died away
assert hit > 3 * rest, 'a hit must be louder than a rest (%f %f)' % (hit, rest)
snare = rms(step * 4, step * 4 + 1500)
assert snare > 2 * rest, 'the snare at step 4'
PY
# the same plan gives the same file
"$M" render "$T/a.mlp" "$T/b.wav" >/dev/null; cmp -s "$T/a.wav" "$T/b.wav" || { echo "mulap test: the same plan must give the same file"; exit 1; }
# the swing moves the odd steps
printf 'bpm = 120\nbars = 1\nswing = 0.4\ntrack hat .x..............\n' > "$T/s.mlp"; "$M" render "$T/s.mlp" "$T/s.wav" >/dev/null
printf 'bpm = 120\nbars = 1\nswing = 0\ntrack hat .x..............\n' > "$T/n.mlp"; "$M" render "$T/n.mlp" "$T/n.wav" >/dev/null
cmp -s "$T/s.wav" "$T/n.wav" && { echo "mulap test: swing changed nothing"; exit 1; }
"$M" demo "$T/d.wav" | grep -q "2 bars at 140 bpm" || { echo "mulap test: demo"; exit 1; }
printf 'bpm = 5000\nbars = 1\ntrack kick x\n' > "$T/bad.mlp"
if "$M" render "$T/bad.mlp" "$T/bad.wav" > /dev/null 2>&1; then echo "mulap test: a bad plan must fail"; exit 1; fi
if "$M" render "$T/none.mlp" "$T/x.wav" > /dev/null 2>&1; then echo "mulap test: a missing plan must fail"; exit 1; fi
# in the app `mulap` (and `mulap studio`) asks the app for the studio window; outside the app it only prints the help
JARIC=1 "$M" | grep -q 'mulap;open' || { echo "mulap test: the studio message"; exit 1; }
JARIC=1 "$M" studio | grep -q 'mulap;open' || { echo "mulap test: mulap studio"; exit 1; }
if env -u JARIC "$M" > /dev/null 2>&1; then echo "mulap test: outside the app mulap alone must fail with the help"; exit 1; fi
echo "mulap test: ok"
