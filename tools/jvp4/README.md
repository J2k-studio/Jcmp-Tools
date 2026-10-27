# jvp4: a video player made only of J2K

The owner's rule: the player and its decoders are written by us, in J2K (no codec of Android, no library of C). Today: `jvp4 info FILE` reads an mp4 / mov file and tells what is in it. The decoders come in steps (see `docs/jvp4-plan.md` of the Jaric documents): the container, then H.264, then AAC, then the picture and the sound in the Jaric app (`gfx` and a PCM channel), then mkv / webm and more codecs.

```
jvp4 info movie.mp4     container, length, every track (codec, size, frames per second, sound format)
jvp4 --version | --help
```
License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.1.0.0 or newer). Test: `sh test.sh` (needs python3 to make a small mp4).

## Install
```
jget tool jvp4                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jvp4     # with curl (no jget needed)
```
In jsh: `jc install jvp4`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Check the file: `jvp4 info movie.mp4` shows the tracks, the size, the length and the codecs.
2. Today only `info` is there; the player itself (decoders for the picture and the sound, all written in J2K) is built step by step.
3. In the Jaric app a video file can be played by the app: `jaric video FILE`.
