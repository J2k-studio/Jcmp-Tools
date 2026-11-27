# ex changelog

## 0.7.0
* **Changed:** `ex` is one program now. It was two: the `ex` of the app (the settings) and `jc` (the tools), which the app kept under the name `expkg`. `jc` is the old name of the same program and stays for two releases.
* **Added:** `ex search WORD`, `ex remove NAME`, `ex awake on|off`; the help is in the standard look (lines of at most 38 characters).
* **Fixed:** in the app `ex update` downloaded a new package tool as `jc` while the app kept running the old copy `expkg`, so the app never got the new tool. `ex update` now replaces `ex` itself.
