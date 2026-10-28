#!/bin/sh
# jaric-os: version, help, and Jaric OS from  jaric-os  (a disk made of a folder; ls, cat, echo, exit typed to the console)
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
B="$PWD/_out"
[ "$("$B/jaric-os" --version)" = "jaric-os 0.11.1" ] || { echo "jaric-os test: version"; exit 1; }
"$B/jaric-os" --help | grep -q "start Jaric OS" || { echo "jaric-os test: help"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T/home" TMPDIR="$T"; mkdir -p "$HOME" "$T/disk"
printf 'first file\n' > "$T/disk/a.txt"; printf 'second\n' > "$T/disk/b.txt"
OUT=$(printf 'ls\ncat a.txt\necho hello there\nexit\n' | "$B/jaric-os" "$T/disk" 2>&1)
case "$OUT" in *"Jaric OS 0.3"*"CPU"*"Timer"*"Memory"*"ls"*"a.txt"*"b.txt"*"first file"*"hello there"*"bye"*) ;; *) echo "jaric-os test: jemu os: $OUT"; exit 1 ;; esac
# no folder given: ~/.jaric-os is made with two small files
OUT2=$(printf 'ls\nexit\n' | "$B/jaric-os" 2>&1)
case "$OUT2" in *"hello.txt"*"readme.txt"*) ;; *) echo "jaric-os test: the default folder: $OUT2"; exit 1 ;; esac
[ -f "$HOME/.jaric-os/hello.txt" ] || { echo "jaric-os test: ~/.jaric-os"; exit 1; }
# the emulator itself (a Linux program) is for the developers: JARIC_OS_DEV=1; without it jaric-os says no

printf '#import <stdlib>\nint main() { cout << "from jemu\\n"; return 5; }\n' > "$T/p.jk"
"${JCMP:-jcmp}" "$T/p.jk" -o "$T/p" >/dev/null 2>&1
set +e; JARIC_OS_DEV=1 "$B/jaric-os" "$T/p" > "$T/p.out"; rc=$?; "$B/jaric-os" --system "$T/p" >/dev/null 2>&1; rc2=$?; set -e
[ "$rc2" = 2 ] || { echo "jaric-os test: --system must be refused ($rc2)"; exit 1; }
[ "$rc" = 5 ] && [ "$(cat "$T/p.out")" = "from jemu" ] || { echo "jaric-os test: a Linux program ($rc)"; exit 1; }
# in the Jaric app (JARIC is set) the system has a text screen of its own: the picture is sent to the app and the letters of the kernel are on it
OUTT=$(printf 'ls\nexit\n' | JARIC=1 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007')
case "$OUTT" in *"]7777;gfx;open;540;960;"*) ;; *) echo "jaric-os test: the text screen"; exit 1 ;; esac
case "$OUTT" in *"f:/> "*) echo "jaric-os test: the letters must be on the screen, not in the terminal"; exit 1 ;; esac
[ "$(wc -c < "$T/jaric-os-screen.bgra")" = 2073600 ] || { echo "jaric-os test: the text screen file"; exit 1; }
# the log is on the terminal first (one line for each check), then the screen is used; the picture follows the height the app says is seen
case "$OUTT" in *"CPU"*"Counter"*"Timer"*"Memory"*"Disk"*"Files"*"Screen"*"Touch"*"is ready"*) ;; *) echo "jaric-os test: the log of the start is not on the terminal: $OUTT"; exit 1 ;; esac
printf '\033]7777;gfx-view;500\007' | JARIC=1 JARIC_SCREEN=540x1170 "$B/jaric-os" "$T/disk" >/dev/null 2>&1 || true
[ "$(wc -c < "$T/jaric-os-screen.bgra")" = $((540*1160*4)) ] || { echo "jaric-os test: the size of the picture follows JARIC_SCREEN"; exit 1; }
# the phone: the home screen has the apps of the system and the .jc packages of the disk; a tap on the Terminal icon opens the console and asks for the keyboard
printf 'x' > "$T/disk/photos.jc"
{ sleep 1; printf '\033]7777;touch;D;100;1000;0\007\033]7777;touch;U;100;1000;0\007'; sleep 1; printf 'ls\r'; sleep 1; printf '\033]7777;gfx-closed\007'; sleep 1; } | JARIC=1 JARIC_SCREEN=540x1170 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007' > "$T/phone.out" || true
command grep -q "gfx;keys;on" "$T/phone.out" || { echo "jaric-os test: the Terminal icon did not ask for the keyboard"; cat "$T/phone.out" | head -5; exit 1; }
# the store: a tap on the Store icon asks the host for the list (jstore lines), a tap on Install gets the package (jstore get) and the disk is made again; the package is a file of the folder
mkdir -p "$T/fakebin"
cat > "$T/fakebin/jstore" <<'SH'
#!/bin/sh
case "$1" in
  lines) printf 'app.demo\t1.0.0\tDemo app\n' ;;
  get) python3 - "$3/$2.jc" "$2" <<'PYS'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1], 'w', zipfile.ZIP_DEFLATED)
z.writestr('manifest.toml', 'name = "Demo app"\nid = "' + sys.argv[2] + '"\nversion = "1.0.0"\nentry = "demo"\n')
z.writestr('demo', b'\x7fELF-not-run')
z.close()
PYS
       echo "saved" ;;
esac
SH
chmod +x "$T/fakebin/jstore"
rm -f "$T/disk/photos.jc"
{ sleep 1; printf '\033]7777;touch;D;330;990;0\007\033]7777;touch;U;330;990;0\007'; sleep 2; printf '\033]7777;touch;D;450;131;0\007\033]7777;touch;U;450;131;0\007'; sleep 3; printf '\033]7777;gfx-closed\007'; sleep 1; } | PATH="$T/fakebin:$PATH" JARIC=1 JARIC_SCREEN=540x1170 "$B/jaric-os" "$T/disk" > "$T/store.out" 2>&1 || true
[ -s "$T/disk/app.demo.jc" ] || { echo "jaric-os test: the store did not put the package in the folder"; exit 1; }
command grep -q "runtime error" "$T/store.out" && { echo "jaric-os test: the store crashed"; exit 1; }
# the command jstore in the console of the system (the same store): list, install, remove
OUTJ=$(printf 'jstore list\njstore install app.demo\nls\njstore remove app.demo\nls\nexit\n' | PATH="$T/fakebin:$PATH" "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033')
case "$OUTJ" in *"app.demo  1.0.0  Demo app"*"installed"*"app.demo.mf"*"removed"*) ;; *) echo "jaric-os test: the command jstore in the console: $OUTJ"; exit 1 ;; esac
[ ! -e "$T/disk/app.demo.jc" ] || { echo "jaric-os test: jstore remove left the file"; exit 1; }
# a program of the disk runs under the console (F6b): the MMU, EL0, the ELF, the calls of the system
"${JCMP:-jcmp}" examples/hello.jk -o "$T/disk/hello" > /dev/null 2>&1
OUTR=$(printf 'run hello\nexit\n' | "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033')
case "$OUTR" in *"hi 42"*"exit 3"*) ;; *) echo "jaric-os test: run hello: $OUTR"; exit 1 ;; esac
rm -f "$T/disk/hello"
# a program that draws and reads the touch (calls 400 and 401): draw.jk shows a picture; a touch near the top ends it
"${JCMP:-jcmp}" examples/draw.jk -o "$T/disk/draw" > /dev/null 2>&1
{ sleep 1; printf '\033]7777;touch;D;100;990;0\007\033]7777;touch;U;100;990;0\007'; sleep 1; printf 'run draw\r'; sleep 5; printf '\033]7777;touch;D;300;200;0\007\033]7777;touch;U;300;200;0\007'; sleep 3; printf '\033]7777;touch;D;50;20;0\007'; sleep 3; printf '\033]7777;gfx-closed\007'; sleep 1; } | JARIC=1 JARIC_SCREEN=540x1170 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007' > "$T/draw.out" || true
command grep -q "runtime error" "$T/draw.out" && { echo "jaric-os test: draw crashed"; exit 1; }
[ "$(command grep -o 'gfx;present' "$T/draw.out" | wc -l)" -ge 6 ] || { echo "jaric-os test: draw did not show its pictures"; exit 1; }
rm -f "$T/disk/draw"
# an app of a package (.jc): the host opens the zip (manifest + program), the home screen shows the app with its name, a tap runs it, the swipe up from the bottom edge closes it
rm -f "$T"/disk/*.jc
"${JCMP:-jcmp}" examples/draw.jk -o "$T/draw_elf" > /dev/null 2>&1
python3 - "$T" <<'PY'
import sys, zipfile
t = sys.argv[1]
z = zipfile.ZipFile(t + '/disk/Sketch.jc', 'w', zipfile.ZIP_DEFLATED)
z.writestr('manifest.toml', 'name = "Sketch"\nid = "com.example.sketch"\nversion = "1.0.0"\ntype = "app"\nentry = "draw"\npermissions = []\n')
z.write(t + '/draw_elf', 'draw')
z.close()
PY
{ sleep 2; printf '\033]7777;touch;D;337;430;0\007\033]7777;touch;U;337;430;0\007'; sleep 6; printf '\033]7777;touch;D;270;1150;0\007\033]7777;touch;M;270;900;0\007\033]7777;touch;U;270;800;0\007'; sleep 3; printf '\033]7777;gfx-closed\007'; sleep 1; } | JARIC=1 JARIC_SCREEN=540x1170 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007' > "$T/app.out" || true
command grep -q "runtime error" "$T/app.out" && { echo "jaric-os test: the app crashed"; exit 1; }
[ "$(command grep -o 'gfx;present' "$T/app.out" | wc -l)" -ge 5 ] || { echo "jaric-os test: the app did not show its pictures"; exit 1; }
[ ! -e "$T/disk/Sketch.mf" ] || { echo "jaric-os test: the package must not leave files in the folder"; exit 1; }
# the desktop (the phone on its side): a wider than high picture; a tap on the pinned Terminal opens a window; the close button closes it
{ sleep 2; printf '\033]7777;touch;D;90;500;0\007\033]7777;touch;U;90;500;0\007'; sleep 2; printf 'ls\r'; sleep 1; printf '\033]7777;touch;D;825;28;0\007\033]7777;touch;U;825;28;0\007'; sleep 2; printf '\033]7777;gfx-closed\007'; sleep 1; } | JARIC=1 JARIC_SCREEN=1170x540 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007' > "$T/desk.out" || true
command grep -q "gfx;open;1170;540" "$T/desk.out" || { echo "jaric-os test: the desktop did not open a picture of 1170 x 540"; exit 1; }
command grep -q "gfx;keys;on" "$T/desk.out" || { echo "jaric-os test: the Terminal window did not ask for the keyboard"; exit 1; }
command grep -q "runtime error" "$T/desk.out" && { echo "jaric-os test: the desktop crashed"; exit 1; }
# the control panel: a swipe down from the top edge opens it, the Keyboard switch asks the app for the keyboard, Close puts back what was under it
{ sleep 2; printf '\033]7777;touch;D;270;8;0\007\033]7777;touch;M;270;200;0\007\033]7777;touch;U;270;320;0\007'; sleep 2; printf '\033]7777;touch;D;90;130;0\007\033]7777;touch;U;90;130;0\007'; sleep 2; printf '\033]7777;touch;D;400;130;0\007\033]7777;touch;U;400;130;0\007'; sleep 2; printf '\033]7777;gfx-closed\007'; sleep 1; } | JARIC=1 JARIC_SCREEN=540x1170 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007' > "$T/panel.out" || true
command grep -q "gfx;keys;on" "$T/panel.out" || { echo "jaric-os test: the Keyboard switch of the control panel did not ask for the keyboard"; exit 1; }
command grep -q "runtime error" "$T/panel.out" && { echo "jaric-os test: the control panel crashed"; exit 1; }
# the back key of the phone (gfx-back): at the home screen the app is asked to go to the background (minimize); in the Terminal app it goes home (the keyboard is dropped); the system is not turned off
{ sleep 2; printf '\033]7777;gfx-back\007'; sleep 1; printf '\033]7777;touch;D;100;1000;0\007\033]7777;touch;U;100;1000;0\007'; sleep 1; printf '\033]7777;gfx-back\007'; sleep 2; printf '\033]7777;gfx-back\007'; sleep 1; printf '\033]7777;gfx-closed\007'; sleep 1; } | JARIC=1 JARIC_SCREEN=540x1170 "$B/jaric-os" "$T/disk" 2>&1 | tr -d '\033\007' > "$T/back.out" || true
[ "$(command grep -o 'gfx;minimize' "$T/back.out" | wc -l)" -ge 2 ] || { echo "jaric-os test: the back key at the home screen must ask to minimize"; exit 1; }
[ "$(command grep -o 'gfx;keys;off' "$T/back.out" | wc -l)" -ge 3 ] || { echo "jaric-os test: the back key in the Terminal app must go home"; exit 1; }
echo "jaric-os tests: ok"
