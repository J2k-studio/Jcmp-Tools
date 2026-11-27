# ex changelog

## 0.8.0
* **Added:** `ex app` and `ex app update`: the app of exshell updates itself (the new APK is downloaded, its SHA-256 checked, and the installer of Android opens); `ex update` says when a newer app is there. `ex doctor`: the network, the versions of the main tools and of the app, the storage and the free space, with what to do.
* **Fixed:** none.

## 0.7.0
* **Changed:** `ex` is one program now. It was two: the `ex` of the app (the settings) and `jc` (the tools), which the app kept under the name `expkg`. `jc` is the old name of the same program and stays for two releases.
* **Added:** `ex search WORD`, `ex remove NAME`, `ex awake on|off`; the help is in the standard look (lines of at most 38 characters).
* **Fixed:** in the app `ex update` downloaded a new package tool as `jc` while the app kept running the old copy `expkg`, so the app never got the new tool. `ex update` now replaces `ex` itself.
