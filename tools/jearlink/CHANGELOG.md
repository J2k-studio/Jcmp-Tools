# Changelog

## 0.2.0
* **Added:** `jearlink -ins NAME.apk` (also `install`): the installer of the system opens over exshell for that file, so an app is installed without leaving the terminal and finding the file in another app. The first time Android asks to allow exshell to install apps: allow it and run the command again.
* **Changed:** `str(x)` is `stg(x)`.

## 0.1.1
* **Added:** `-viw FILE` opens a local file in the app that fits it.
* **Fixed:** `-sh Blonde.mp3` (a name next to you, a drive path or a path of the virtual root) said "there is no such file": the program now gives the app the real path of the file.

## 0.1.0
* **Added:** `view`, `send`, `share`, `pick`, `call`, `app`, `apps`, `notify`.
* **Fixed:** none (first version).
