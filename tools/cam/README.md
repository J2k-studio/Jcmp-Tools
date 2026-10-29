# cam: the camera of the phone for the programs of the Jaric app

`cam` lets a program in the terminal of the **Jaric app** use the camera: take a photo, or read a QR code (for example the code of a two-step login). The app shows the camera over the terminal (it asks the phone once for the permission); the program saves the picture or reads the code. Written in J2K (the JPEG reader and the QR reader are in the program).

## Commands
```
cam                            the camera with two tabs: SCAN (point it at a QR code: a card shows a link to touch, a Wi-Fi password to copy, a login code to add to authj) and PHOTO
cam photo                      the camera opens; touch the round button: the picture is saved as u:/DCIM/Jaric/photo-TIME.jpg (the path is printed)
cam photo out.jpg --after 3    taken by itself after 3 seconds
cam photo --front              the front camera (the button with the two arrows on the screen turns it)
cam scan                       reads a QR code with the camera and prints its text; Esc, q, Ctrl-C or the cross on the screen close it
cam history                    the codes that were read before, the newest first
cam scan --timeout 30 --keep last.jpg     give up after 30 seconds; keep the last picture that was looked at
```
* In the camera: tap = focus, double tap = zoom 1x / 2x, pinch = zoom, the volume keys = the shutter, the clock button = a timer (3, 10 s), `#` = a grid, the light and the turn of the camera at the top.
* A scan looks at a picture about once a second (2 million dots) and stops at the first code that is read. Hold the code still, light on it, 15 to 30 cm away.
* Use it with `authj`:  `authj add-uri "$(cam scan)"`  (the code of GitHub or another site becomes an account).
* The pictures are JPEG files in the folder you name (by default `u:/DCIM/Jaric/`, which the gallery shows). Photos have up to 12 million dots.
* It works only in the terminal of the Jaric app (app 0.0.146 or newer): the messages `ESC ] 7777 ; camera ; ... BEL` are answered by the app. In another terminal it says so and ends.

```
sh build.sh      # needs jcmp 1.2.2.0 or newer and the libraries deflate and png
sh test.sh       # needs python3 with qrcode and Pillow: a pretend app (fake_app.py) answers on a pseudo terminal
```

**Licence:** Mozilla Public License 2.0 (`LICENSE` in this folder).

## Install
```
jc install cam                                                         # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s cam     # with curl (no jget needed)
```
In jsh: `jc install cam`. Both check the SHA-256 of the file before anything is installed. Update later with the same command.

## A short lesson
1. In the Jaric app: `jc install cam`, then `cam photo`. Touch the round button. The path of the picture is printed.
2. `cam scan` and show it a QR code (a screen of a computer works). The text is printed.
3. Two-step login: on the site choose the app code, `authj add-uri "$(cam scan)"`, then `authj NAME` gives the six digits.
