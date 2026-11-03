# apkj

Builds an Android apk from a J2K app without the Android tools (no aapt2, ecj, d8, zipalign, apksigner).
Written in J2K. Used by `makej apk` when those tools are missing.

    apkj key KEYFILE                          make a signing key
    apkj manifest manifest.toml OUT.xml       the binary AndroidManifest.xml
    apkj build manifest.toml OUT.apk -k KEYFILE [path-in-apk=file ...]
    apkj selftest                             ECDSA sign + verify check
    apkj --version

Limits: GL apps (`render = "gl"`), no icon yet, v1 (JAR) signature only (Android 7+ accepts it for apps targeting API < 30).
Build: `sh build.sh` (needs the zipj sources in ../zipj). Test: `sh test.sh`.
