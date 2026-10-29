# jamanager changelog

## 0.2.0
* **Added:** `jmanager`, a screen like the Task Manager: tabs Programs (cpu in percent, memory, sort by cpu / memory / pid / name, find, stop with `k` and `K`, pause), Memory (bars, the biggest programs), Drives (bars), Caches (measure, empty one); the other name `jmanager` is a link that the installer makes (`jamanager --install DIR`); `jamanager ui` opens the screen too.
* **Fixed:** none.

## 0.1.0
* The task manager of Jaric: `jamanager ps` (pid, state, memory, cpu seconds, name), `top [-n N]` (biggest memory first, every 2 seconds, fits the screen), `mem`, `kill PID [-9]` (pid 1 is refused), `drives` (size, used, free of home, /sdcard, /data, /), `cache` (size of ~/.cache, ~/.j2k, the temporary folder). Android shows only your own programs.
