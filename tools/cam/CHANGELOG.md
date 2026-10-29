# cam changelog

## 0.3.0 (app 0.0.151)
* **Added:** `cam history [-n N]` (the codes that were read, kept in `~/.cache/jaric/cam-history.txt`); in the camera of the app: **tap to focus** (a ring), **double tap** zoom 1x / 2x and a label of the zoom, a **timer** (3 or 10 seconds with a number), a **grid**, the **volume keys are the shutter**, the preview follows when the phone is turned, the picture of the gallery is copied off the screen thread.
* **Fixed:** none.

## 0.2.1
* **Changed:** photos are kept in `u:/DCIM/Jaric/` (the gallery of the phone shows them; it was the folder for temporary files); `CAM_DIR` chooses another folder.
* **Fixed:** none.

## 0.2.0
* **Added:** `cam` alone: the camera with the tabs PHOTO and SCAN (app 0.0.147): pinch to zoom, a light, the turn of the camera, a frame for the code; a code that is read shows a **card** with what it is: a link opens with one touch, a Wi-Fi code copies its password, a two-step login code goes to `authj`, any text can be copied or used (printed). `cam photo` and `cam scan` stay for scripts.
* **Fixed:** none.

## 0.1.0
* **Added:** `cam photo` (the round button or `--after`, `--front`) and `cam scan` (reads QR codes with the camera; `--timeout`, `--keep`) for the terminal of the Jaric app 0.0.146; the messages `ESC ] 7777 ; camera ; open / shot / flip / close`.
* **Fixed:** none (first release).
