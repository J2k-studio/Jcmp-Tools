# ex changelog

## 0.14.1
* **Added:** `ex install mascot` turns the mascot of the app on (it is off in a new app).
* **Fixed:** none.

## 0.14.0
* **Added:** `install`, `update` and `unstall` ask `[y/n]` first at a terminal; `-y` does not ask (a script is not asked).
* **Added:** `ex update NAME...` updates only those (a tool, a package or `app`).
* **Added:** `ex unstall mascot` turns the mascot of the app off.
* **Fixed:** `ex update NAME` also updated everything else.

## 0.13.0
* **Added:** the commands that ask the app: `toast notify copy paste vibrate torch battery open share send pick apk apps launch call play pause resume stop tab exit api` (exshell 0.1.89 or newer; the same as the library `exapi`).
* **Fixed:** none.
* **Removed:** the old name `jc` is no longer released; the tools that were taken out are no longer linked.

## 0.12.0
* **Changed:** the editor is `fcode` in `ex doctor` (it was `coderin`).
* **Fixed:** none.

## 0.11.0
* **Changed:** `ex update` updates everything with one command: the tools, the programs and, in exshell, the app (the patch is fetched and Android asks you to tap Update); `ex update -n` only says what is newer.
* **Fixed:** none.

## 0.10.0
* **Added:** `ex unstall`, `ex search`, `ex list` work for packages too; a package installed now has its links and scripts pointed at the real folder (the packages were built for the folder of another app: `ssh`, `dropbearkey` and others were broken links).
* **Changed:** one set of words for tools and packages: `ex install`, `ex unstall`, `ex search`, `ex tools` (both lists), `ex list` (all that is installed). `ex pkg ...` still works.
* **Fixed:** `ex pkg install authj` said "no package named authj" for a tool; `ex install jexcmp`, `ex pack install` and `jex update` took the word `install` for a name; installing what is there already said nothing.

## 0.9.0
* **Changed:** `ex app update` downloads only a patch (what differs from the installed app) and makes the new APK from the app on the phone; the whole file is fetched only when there is no patch or it does not fit. Android still asks to tap Update.
* **Fixed:** none.

## 0.8.0
* **Added:** `ex app` and `ex app update`: the app of exshell updates itself (the new APK is downloaded, its SHA-256 checked, and the installer of Android opens); `ex update` says when a newer app is there. `ex doctor`: the network, the versions of the main tools and of the app, the storage and the free space, with what to do.
* **Fixed:** none.

## 0.7.0
* **Changed:** `ex` is one program now. It was two: the `ex` of the app (the settings) and `jc` (the tools), which the app kept under the name `expkg`. `jc` is the old name of the same program and stays for two releases.
* **Added:** `ex search WORD`, `ex remove NAME`, `ex awake on|off`; the help is in the standard look (lines of at most 38 characters).
* **Fixed:** in the app `ex update` downloaded a new package tool as `jc` while the app kept running the old copy `expkg`, so the app never got the new tool. `ex update` now replaces `ex` itself.
