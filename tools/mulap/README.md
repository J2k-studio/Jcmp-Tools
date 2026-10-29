# mulap

An app to record songs and make beats. This first step is the **engine**: a plan of a beat (a small text file) becomes a sound file, with no screen needed. The pads, the step grid, the recording and the timeline come next (see the plan of the Jaric documents).

## Commands
```
mulap demo beat.wav                    a small beat of its own (140 bpm, 2 bars)
mulap render plan.mlp beat.wav         a beat from a plan (44100 Hz, 16 bit, mono)
mulap --version | --help
```
A plan is a text file:
```
bpm = 120            beats a minute (a beat is four steps)
bars = 2             a bar is 16 steps
swing = 0.15         0 .. 0.5: the odd steps come later
track kick  x...x...x...x...
track snare ....x.......x...  gain 0.9
```
`x` is a hit, `X` a strong hit, `.` silence; a pattern that is shorter than the song repeats. The voices are made by the program (no sample files): `kick snare hat openhat clap tom bass`.

## Install
```
jc install mulap                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s mulap     # with curl (no jget needed)
```
Both check the SHA-256 of the file before anything is installed.

## A short lesson
Make `plan.mlp` with the lines above, run `mulap render plan.mlp beat.wav`, then listen: `mujic play beat.wav -b` in the Jaric app. Change a pattern, render again, listen again. License: MPL-2.0.
