# jvp4: a video player made only of J2K

The owner's rule: the player and its decoders are written by us, in J2K (no codec of Android, no library of C). Today: `jvp4 info FILE` reads an mp4 / mov file and tells what is in it. The decoders come in steps (see `docs/jvp4-plan.md` of the Jaric documents): the container, then H.264, then AAC, then the picture and the sound in the Jaric app (`gfx` and a PCM channel), then mkv / webm and more codecs.

```
jvp4 info movie.mp4     container, length, every track (codec, size, frames per second, sound format)
jvp4 --version | --help
```
License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.1.0.0 or newer). Test: `sh test.sh` (needs python3 to make a small mp4).
