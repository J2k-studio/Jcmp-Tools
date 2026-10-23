# yt-dlp: download audio and video from sites

The program [yt-dlp](https://github.com/yt-dlp/yt-dlp) (Unlicense) in its one-file form, started by the launcher of the tool [python](../python/README.md) (the same program, called `yt-dlp`). **Use it only for what you may download** (your own files, free or licensed content, what the terms of the site allow). mujic uses it for `/get ADDRESS`.

```
yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --no-playlist -o "%(title)s.%(ext)s" ADDRESS
yt-dlp --version
```

## Install
```
jget tool python yt-dlp                                              # with jget (python first)
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s python yt-dlp     # with curl
```
Update later with `jget tool yt-dlp` again (the sites change often, so an old yt-dlp stops working).

## A short lesson
1. `yt-dlp --version` shows the version; `yt-dlp -F ADDRESS` lists the formats of an address.
2. Sound only: `yt-dlp -f "bestaudio[ext=m4a]/bestaudio" ADDRESS` (no ffmpeg needed for m4a).
3. Into the music folder of mujic: add `-o "$HOME/music/%(title)s.%(ext)s"`.
4. Playlists: leave out `--no-playlist` (this takes long); one video: keep it.
5. Fails with an error about the site? Update: `jget tool yt-dlp`.
