# island: alarms, timers and notices on the island of the Jaric app, from the terminal

The Jaric app has an island: a small black pill at the top of the screen (near the camera hole, like the island of Huawei, or in the middle) that shows what is going on: an alarm or a timer that rings, the timers that count down, a short notice, the music. `island` is the command line for it. `jc install island` also makes the commands `timer` and `alarm`.

```
timer 5m                    a timer of 5 minutes (also 90s, 1h30m, 2h, or just seconds: timer 90)
timer 10m pasta             with a name that the island shows when it rings
timer list                  what is counting down
timer cancel 3              cancel the timer number 3 (timer cancel all)
alarm 07:30                 an alarm at the next 07:30
alarm 7:15 wake up daily    every day (the last word "daily")
alarm list    alarm cancel 2    alarm cancel all
island on | off             show the island in the app, or hide it
island app | over           in the window of Jaric, or over every app (the phone asks once to allow it)
island hole | middle        near the camera hole, or in the middle
island notice TEXT          a short notice for three seconds
```
The island also has a switch in **Jaric Settings** (Island). Touch the island to open it into buttons: stop or snooze (5 minutes) for a ringing alarm, cancel and +1 minute for a timer, previous / play / next for the music.

Alarms and timers are kept by the clock of Android (they ring when the phone sleeps and come back after a restart). The list is in `~/.config/jaric/island.txt`.

This works only inside the Jaric app (the commands send a message to the app). Written in J2K.

Licence: MPL-2.0 (see LICENSE).
