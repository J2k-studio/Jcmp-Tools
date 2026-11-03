# Changelog

## 0.2.0
* **Added:** `apkj build` makes a signed apk of a GL app (`render = "gl"`) with no Android tools: zip (zipj code), the binary AndroidManifest.xml, v1 JAR signing (ECDSA P-256, self-signed certificate, PKCS#7), an embedded classes.dex runner; `apkj manifest`, `apkj key`, `apkj selftest`.
* **Added:** `makej apk` uses apkj when aapt2, ecj, d8, zipalign or apksigner are missing (or `MAKEJ_APKJ=1`).
* **Fixed:** none (first release).
