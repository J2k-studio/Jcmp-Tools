# jamanager (jmanager): the task manager of Jaric

Like the Task Manager of Windows, in a terminal: which programs run, how much memory they use, stop one, how full the drives are, how big the caches are. Written in J2K on the standard library only; reads `/proc`. Android lets a program see only its own programs (and the ones of the same app), so the list is shorter than on a PC.

**`jmanager`** (the same program under its other name, made by the installer) is the screen: tabs **Programs** (cpu in percent and memory of each program, biggest first; `s` sort, `/` find, `k` stop, `K` stop at once, `p` pause), **Memory**, **Drives**, **Caches** (`c` empties one); Tab or the arrows change the tab, `q` leaves. The commands below are for scripts.

```
jamanager ps               pid, state, memory (MB), cpu (s), name
jamanager top [-n N]       biggest memory first, drawn again every 2 s (Ctrl-C leaves); it fits the screen
jamanager mem              the memory of the machine and the swap
jamanager kill PID [-9]    stop a program (-9 at once); pid 1 is refused
jamanager drives           size, used and free of home, /sdcard, /data and /
jamanager cache            the size of ~/.cache, ~/.j2k and the folder for temporary files
```
Later (the plan of Jaric OS): the background programs and the sessions, the cache of the drives (`jamanager cache clear`), the drives of Jaric (`:/f`) and the tool for them.

## Install
```
jc install jamanager                                                  # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jamanager     # with curl
```
In jsh: `jc install jamanager`.

## A short lesson
1. Look: `jamanager ps`. The last line says how many programs you can see.
2. Find the big ones: `jamanager top -n 1`, or leave out `-n` and watch it (Ctrl-C leaves).
3. Start a program in the background and stop it: `sleep 100 &` (jsh prints nothing), `jamanager ps` (find `sleep`), `jamanager kill PID`.
4. Is there room? `jamanager drives` and `jamanager mem`. Is a cache big? `jamanager cache`.

License: MPL-2.0. Build: `JCMP=path sh build.sh` (jcmp 1.2.0.0 or newer). Test: `sh test.sh`.
