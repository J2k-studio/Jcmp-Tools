#!/bin/sh
# jvp4: the reader of mp4 boxes on a small file made here (a video track and a sound track, moov after mdat)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/jvp4 --version)" = "jvp4 $(cat VERSION)" ] || { echo "jvp4 test: --version differs from VERSION"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
python3 - "$T/t.mp4" <<'PY'
import struct,sys
def box(t,p): return struct.pack('>I',8+len(p))+t+p
def full(t,v,f,p): return box(t,struct.pack('>I',(v<<24)|f)+p)
mvhd=full(b'mvhd',0,0,struct.pack('>IIII',0,0,1000,12500)+b'\0'*80)
tkhd=full(b'tkhd',0,3,struct.pack('>IIIII',0,0,1,0,12500)+b'\0'*(8+2+2+2+2+36)+struct.pack('>II',1280<<16,720<<16))
mdhd=full(b'mdhd',0,0,struct.pack('>IIII',0,0,30000,375000)+b'\0'*4)
hdlr=full(b'hdlr',0,0,b'\0\0\0\0vide'+b'\0'*12+b'v\0')
avcc=box(b'avcC',bytes([1,100,0,40])+b'\xff\xe1\0\0\x01\0\0')
entry=b'\0'*6+struct.pack('>H',1)+b'\0'*16+struct.pack('>HH',1280,720)+struct.pack('>IIIH',0x480000,0x480000,0,1)+b'\0'*32+struct.pack('>Hh',24,-1)+avcc
stsd=full(b'stsd',0,0,struct.pack('>I',1)+box(b'avc1',entry))
stsz=full(b'stsz',0,0,struct.pack('>II',0,375))
trakv=box(b'trak',tkhd+box(b'mdia',mdhd+hdlr+box(b'minf',box(b'stbl',stsd+stsz))))
hdlr2=full(b'hdlr',0,0,b'\0\0\0\0soun'+b'\0'*12+b'a\0')
mdhd2=full(b'mdhd',0,0,struct.pack('>IIII',0,0,44100,551250)+b'\0'*4)
ae=b'\0'*6+struct.pack('>H',1)+b'\0'*8+struct.pack('>HHHH',2,16,0,0)+struct.pack('>I',44100<<16)
traka=box(b'trak',box(b'mdia',mdhd2+hdlr2+box(b'minf',box(b'stbl',full(b'stsd',0,0,struct.pack('>I',1)+box(b'mp4a',ae))))))
moov=box(b'moov',mvhd+trakv+traka)
ftyp=box(b'ftyp',b'isom'+struct.pack('>I',512)+b'isomavc1')
open(sys.argv[1],'wb').write(ftyp+box(b'mdat',b'\0'*100)+moov)
PY
out=$(./_out/jvp4 info "$T/t.mp4")
echo "$out" | grep "brand isom" >/dev/null || { echo "jvp4 test: brand"; exit 1; }
echo "$out" | grep "length: 0:12.5" >/dev/null || { echo "jvp4 test: length"; exit 1; }
echo "$out" | grep "1280x720  High, level 4.0" >/dev/null || { echo "jvp4 test: video track"; exit 1; }
echo "$out" | grep "375 frames, 30.0 fps" >/dev/null || { echo "jvp4 test: frames"; exit 1; }
echo "$out" | grep "44100 Hz, 2 channels" >/dev/null || { echo "jvp4 test: audio track"; exit 1; }
printf 'not a video file at all' > "$T/x.bin"
if ./_out/jvp4 info "$T/x.bin" >/dev/null 2>&1; then echo "jvp4 test: a bad file must fail"; exit 1; fi
echo "jvp4 tests: ok"
