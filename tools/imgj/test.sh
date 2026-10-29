#!/bin/sh
# imgj: JPEG and PNG are read as another decoder (Pillow) reads them, the background of a photo goes, the sizes and the pieces are right
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/imgj --version)" = "imgj $(cat VERSION)" ] || { echo "imgj test: --version differs from VERSION"; exit 1; }
./_out/imgj --help > /dev/null || { echo "imgj test: --help"; exit 1; }
I="$PWD/_out/imgj"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
python3 -I - <<'PY' || { echo "imgj test: Pillow is needed to make the test pictures"; exit 1; }
from PIL import Image, ImageDraw, ImageFilter
im = Image.new('RGB', (53, 37), (200, 30, 30))                       # not a multiple of 8, on purpose
d = ImageDraw.Draw(im)
d.rectangle((5, 5, 30, 20), fill=(30, 200, 30)); d.ellipse((20, 10, 48, 34), fill=(30, 30, 220)); d.line((0, 0, 52, 36), fill=(250, 250, 0), width=2)
im.save('j444.jpg', quality=95, subsampling=0)
im.save('j420.jpg', quality=95, subsampling=2)
im.convert('L').save('jgrey.jpg', quality=95)
im.save('jprog.jpg', quality=90, progressive=True)
for n in ('j444', 'j420', 'jgrey'):
    Image.open(n + '.jpg').convert('RGB').save(n + '_ref.png')
# a "photo": a rocket (a polygon) on a sky with a gradient and noise, as JPEG
import random
random.seed(5)
W, H = 300, 600
sky = Image.new('RGB', (W, H))
px = sky.load()
for y in range(H):
    for x in range(W):
        px[x, y] = (110 + y // 40, 150 + y // 50, 205 - y // 60)
sky = sky.filter(ImageFilter.GaussianBlur(2))
mask = Image.new('L', (W, H), 0)
md = ImageDraw.Draw(mask)
md.polygon([(150, 40), (185, 140), (185, 520), (115, 520), (115, 140)], fill=255)
rocket = Image.new('RGB', (W, H), (235, 235, 238))
rd = ImageDraw.Draw(rocket)
rd.rectangle((115, 300, 185, 360), fill=(30, 30, 30)); rd.rectangle((115, 450, 185, 520), fill=(160, 60, 40))
sky.paste(rocket, (0, 0), mask)
sky.save('photo.jpg', quality=92, subsampling=2)
mask.save('mask_ref.png')
Image.new('RGB', (40, 40), (128, 128, 128)).save('flat.png')
PY
for n in j444 j420 jgrey; do
    "$I" convert $n.jpg $n.png > /dev/null || { echo "imgj test: convert $n"; exit 1; }
    python3 -I -c "
from PIL import Image, ImageChops
a=Image.open('$n.png').convert('RGB'); b=Image.open('${n}_ref.png').convert('RGB')
assert a.size==b.size, (a.size,b.size)
diff=ImageChops.difference(a,b); m=max(diff.getextrema(),key=lambda e:e[1])[1]
assert m<=4, ('$n', 'largest difference', m)" || { echo "imgj test: $n differs from Pillow"; exit 1; }
done
if "$I" convert jprog.jpg p.png > /dev/null 2> err.txt; then echo "imgj test: a progressive JPEG must be refused"; exit 1; fi
grep -q progressive err.txt || { echo "imgj test: the message about a progressive JPEG"; exit 1; }
printf 'not a picture' > bad.bin
if "$I" info bad.bin > /dev/null 2>&1; then echo "imgj test: a file that is no picture must fail"; exit 1; fi
"$I" info photo.jpg | grep -q "300 x 600" || { echo "imgj test: info"; exit 1; }
"$I" cut photo.jpg cut.png --tol 30 > /dev/null || { echo "imgj test: cut"; exit 1; }
python3 -I -c "
from PIL import Image
c=Image.open('cut.png').convert('RGBA'); m=Image.open('mask_ref.png').convert('L')
# the rocket is 70 wide and 480 high in the picture: the cut is trimmed to it
bb=m.getbbox(); assert abs(c.width-(bb[2]-bb[0]))<=3 and abs(c.height-(bb[3]-bb[1]))<=3, (c.size, bb)
m=m.crop((bb[0]-0,bb[1]-0,bb[2],bb[3])).resize(c.size)
bad=0; tot=0
for y in range(c.height):
    for x in range(c.width):
        inside=m.getpixel((x,y))>127
        if inside or c.getpixel((x,y))[3]>0:
            tot+=1
            if inside!=(c.getpixel((x,y))[3]>127): bad+=1
assert bad*100<tot*8, ('mask differs', bad, tot)
assert c.getpixel((0,0))[3]==0" || { echo "imgj test: the cut picture differs from the rocket"; exit 1; }
"$I" meter cut.png meter.png --height-m 50 --ppm 4 > /dev/null || { echo "imgj test: meter"; exit 1; }
python3 -I -c "
from PIL import Image
m=Image.open('meter.png'); assert m.height==200, m.size" || { echo "imgj test: meter height"; exit 1; }
"$I" scale cut.png s.png --width 35 > /dev/null || { echo "imgj test: scale"; exit 1; }
python3 -I -c "
from PIL import Image
s=Image.open('s.png'); assert s.width==35, s.size" || { echo "imgj test: scale width"; exit 1; }
"$I" slice cut.png part --at 0.25,0.5 > /dev/null || { echo "imgj test: slice"; exit 1; }
python3 -I -c "
from PIL import Image
c=Image.open('cut.png'); a=Image.open('part_1.png'); b=Image.open('part_2.png'); d=Image.open('part_3.png')
assert a.height+b.height+d.height==c.height, (a.size,b.size,d.size,c.size)
assert abs(a.height-c.height*0.25)<=1" || { echo "imgj test: slice heights"; exit 1; }
"$I" normal flat.png n.png > /dev/null || { echo "imgj test: normal"; exit 1; }
python3 -I -c "
from PIL import Image
p=Image.open('n.png').convert('RGB').getpixel((20,20)); assert p==(128,128,255), p" || { echo "imgj test: a flat picture has the normal (128,128,255)"; exit 1; }
"$I" credit data/art/x.png --source "Example" --license CC0 --file CREDITS.md > /dev/null || { echo "imgj test: credit"; exit 1; }
grep -q 'x.png.*Example.*CC0' CREDITS.md || { echo "imgj test: the line of credit"; exit 1; }
echo "imgj tests passed"
