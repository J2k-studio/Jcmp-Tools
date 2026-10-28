# makes jaric-os-font: the letters of the text screen (ASCII 32..126), smooth (8 bits of cover for each dot), from a mono font of the phone. Run: python3 mkfont.py [FONT.ttf] [SIZE]
import sys
from PIL import Image, ImageDraw, ImageFont
path = sys.argv[1] if len(sys.argv) > 1 else "/system/fonts/DroidSansMono.ttf"
size = int(sys.argv[2]) if len(sys.argv) > 2 else 17
CW, CH = 10, 20
f = ImageFont.truetype(path, size)
out = bytearray([CW, CH, 32, 95])
asc, desc = f.getmetrics()
top = (CH - (asc + desc)) // 2
for c in range(32, 127):
    im = Image.new("L", (CW, CH), 0)
    d = ImageDraw.Draw(im)
    w = d.textlength(chr(c), font=f)
    d.text(((CW - w) / 2, top), chr(c), font=f, fill=255)
    out += im.tobytes()
open("jaric-os-font", "wb").write(out)
print("jaric-os-font", len(out), "bytes")
