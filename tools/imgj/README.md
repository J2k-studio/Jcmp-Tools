# imgj: real pictures into pictures for a game

`imgj` reads a PNG or a JPEG (a photo, a drawing) and writes PNG pictures that a game can use: the background gone, cut to the object, the size of the real object, cut into parts, and a normal map for lit metal. Written in J2K (it has its own JPEG reader). Made for the game Apsis, useful for any game.

## Commands
```
imgj info photo.jpg                                    size, and how many dots are see-through
imgj convert photo.jpg photo.png                       any picture to PNG
imgj cut photo.jpg rocket.png [--tol 24] [--bg RRGGBB] [--pad 0] [--hard]
                                                       the sky (the colour of the corner, or --bg) goes see-through: it is flood-filled from the
                                                       border, so a white rocket on a white sky keeps its body; the edge is soft (--hard: sharp);
                                                       the picture is trimmed to the object
imgj scale rocket.png small.png --width 64             also --height N and --factor 0.5
imgj meter rocket.png ship.png --height-m 110.6 --ppm 8   the object is 110.6 m tall at 8 pixels for a metre (the width follows)
imgj slice rocket.png stage --at 0.25,0.6              stage_1.png (top 25 %), stage_2.png, stage_3.png: parts to put together in the game
imgj normal ship.png ship_n.png [--strength 2.0]       a normal map made from the light and the dark of the picture
imgj credit data/art/ship.png --source "NASA Image Library" --license "public domain" [--file CREDITS.md]
                                                       adds one line to the table of credits (do it for every picture you take)
```
* Reads: PNG (all kinds without interlacing) and JPEG (baseline and extended sequential, grey and colour, any chroma subsampling, restart markers). **Not yet:** progressive JPEG (the message says so; save it as baseline or PNG), CMYK, arithmetic coding.
* Writes: PNG with alpha (8 bits, filter none, deflate).
* `cut` works best on a plain sky or a studio background. A picture shot at an angle, with shadows on the sky, or with the same colour in the sky and in the rocket may need a higher `--tol` or a `--bg` colour. Always look at the result.
* Check the **license of a picture** before you use it (NASA pictures are mostly free to use, not the logos). `imgj credit` writes the line.

```
sh build.sh      # needs jcmp 1.2.2.0 or newer and the libraries deflate and png (jc lib install deflate png); JCMP=path chooses the compiler
sh test.sh       # needs python3 with Pillow: the JPEG reader is compared with Pillow, the cut with a known mask
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).

## Install
```
jc install imgj                                                        # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s imgj     # with curl (no jget needed)
```
In jsh: `jc install imgj`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. Get a picture you may use (for example from images.nasa.gov) and look at it: `imgj info rocket.jpg`.
2. Take the sky away: `imgj cut rocket.jpg rocket.png`. Open `rocket.png`; if a piece of the rocket is missing, raise `--tol 40`; if sky is left, lower it or give `--bg`.
3. Give it its real size: `imgj meter rocket.png ship.png --height-m 110 --ppm 8`.
4. For lit metal in a shader: `imgj normal ship.png ship_n.png`.
5. Write where it came from: `imgj credit data/art/ship.png --source "images.nasa.gov, name of the picture" --license "public domain"`.
