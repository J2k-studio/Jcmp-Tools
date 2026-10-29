# imgj changelog

## 0.2.0
* **Added:** `imgj scan FILE`: reads the QR code in a PNG or JPEG picture and prints its text (the library `qr` is in the program: all versions, error correction, turned codes).
* **Fixed:** none.

## 0.1.0
* **Added:** `info`, `convert`, `cut` (background flood-fill with a soft edge, trim), `scale`, `meter`, `slice`, `normal` and `credit`; a reader for JPEG (baseline, extended sequential, grey and colour, chroma subsampling with a linear mix, restart markers) and PNG; a writer of PNG with alpha.
* **Fixed:** none (first release). Not yet: progressive JPEG.
