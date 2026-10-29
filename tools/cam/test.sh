#!/bin/sh
# cam: a pretend app (fake_app.py, on a pseudo terminal) answers the messages ESC ] 7777 ; camera ; ... BEL: a QR code is read from the pictures
# of the "camera", a photo is saved, Esc closes, and a program without an app does not hang
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/cam --version)" = "cam $(cat VERSION)" ] || { echo "cam test: --version differs from VERSION"; exit 1; }
./_out/cam --help > /dev/null || { echo "cam test: --help"; exit 1; }
C="$PWD/_out/cam"; F="$PWD/fake_app.py"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
python3 -I - "$T" <<'PY' || { echo "cam test: Python needs the modules qrcode and Pillow"; exit 1; }
import sys, qrcode
from PIL import Image
t = sys.argv[1]
q = qrcode.QRCode(box_size=6, border=4); q.add_data('otpauth://totp/Cam:me?secret=JBSWY3DPEHPK3PXP&issuer=Cam'); q.make(fit=True)
qi = q.make_image(fill_color='black', back_color='white').convert('RGB').rotate(8, expand=True, fillcolor=(255, 255, 255))
frame = Image.new('RGB', (1280, 720), (235, 235, 230)); frame.paste(qi, ((1280 - qi.width) // 2, (720 - qi.height) // 2)); frame.save(t + '/qr_frame.jpg', quality=85)
Image.new('RGB', (1280, 720), (90, 100, 110)).save(t + '/blank.jpg')
PY
out=$(python3 -I "$F" scan "$C" "$T" scan --timeout 20 2>&1) || { echo "cam test: scan: $out"; exit 1; }
echo "$out" | grep -q "otpauth://totp/Cam:me?secret=JBSWY3DPEHPK3PXP&issuer=Cam" || { echo "cam test: scan printed: $out"; exit 1; }
[ ! -f "$T/cam-scan.jpg" ] || { echo "cam test: the picture of scan must be removed"; exit 1; }
out=$(python3 -I "$F" photo "$C" "$T" photo "$T/p1.jpg" 2>&1) || { echo "cam test: photo: $out"; exit 1; }
echo "$out" | grep -q "$T/p1.jpg" || { echo "cam test: photo printed: $out"; exit 1; }
[ -s "$T/p1.jpg" ] || { echo "cam test: photo file"; exit 1; }
python3 -I "$F" photo-auto "$C" "$T" photo "$T/p2.jpg" --after 1 2>&1 | grep -q "p2.jpg" || { echo "cam test: photo --after"; exit 1; }
if python3 -I "$F" photo-quit "$C" "$T" photo "$T/p3.jpg" > /dev/null 2>&1; then echo "cam test: Esc must end photo with a failure"; exit 1; fi
if python3 -I "$F" scan-none "$C" "$T" scan --timeout 3 > /dev/null 2>&1; then echo "cam test: a scan without a code must fail"; exit 1; fi
if python3 -I "$F" no-answer "$C" "$T" scan --timeout 3 > /dev/null 2>&1; then echo "cam test: no answer of the app must fail"; exit 1; fi
# the two tabs: `cam` alone: a code that is read goes to the app as a card; the person chooses "use" (the text is printed) or "add" (authj gets it)
mkdir -p "$T/bin"
printf '#!/bin/sh\necho "$@" > "%s/authj.args"\n' "$T" > "$T/bin/authj"; chmod +x "$T/bin/authj"
out=$(python3 -I "$F" ui-use "$C" "$T" 2>&1) || { echo "cam test: ui-use: $out"; exit 1; }
echo "$out" | grep -q "otpauth://totp/Cam:me?secret=JBSWY3DPEHPK3PXP&issuer=Cam" || { echo "cam test: ui-use printed: $out"; exit 1; }
python3 -I "$F" ui-add "$C" "$T" > /dev/null 2>&1 || { echo "cam test: ui-add"; exit 1; }
grep -q "add-uri otpauth://totp/Cam:me" "$T/authj.args" || { echo "cam test: authj was not asked to add the account"; exit 1; }
# a picture of the gallery: the app sends camera-picked and the code in it comes back as a card (use prints it); a picture without a code gives a message
rm -f "$T/toast.txt"
out=$(python3 -I "$F" ui-pick "$C" "$T" 2>&1) || { echo "cam test: ui-pick: $out"; exit 1; }
echo "$out" | grep -q "otpauth://totp/Cam:me" || { echo "cam test: the picked picture was not read: $out"; exit 1; }
python3 -I "$F" ui-pick-none "$C" "$T" > /dev/null 2>&1 || true
grep -q "No QR code" "$T/toast.txt" || { echo "cam test: a picture without a code must give the message"; exit 1; }
# the history of the codes
HOME="$T" "$C" history | grep -q "otpauth://totp/Cam:me" || { echo "cam test: history shows the code that was read"; exit 1; }
[ "$(HOME="$T/none" "$C" history)" = "no codes were read yet (cam scan)" ] || { echo "cam test: history of nothing"; exit 1; }
echo "cam tests passed"
