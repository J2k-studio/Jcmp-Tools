# jearlink

The apps of the phone from the terminal of the Jaric app: open a link, share a text or a file, pick a file, call, start an app, list the apps, show a notification.

## Commands
```
jearlink -viw https://example.org      # opens it in the app the phone picks
jearlink -snd hello world              # the share sheet of the phone
jearlink -sh ~/pic.png               # share a file
jearlink -pk image                    # the picker of the phone
jearlink -cll 112                      # the dialer
jearlink -ap Camera                    # start an app by name or package
jearlink -aps                          # the apps that can be started (name TAB package)
jearlink -ntf Done "the build is ready"
```

## Install
```
jc install jearlink                                                         # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jearlink     # with curl (no jget needed)
```
Both check the SHA-256 of the file before anything is installed.

## A short lesson
In the terminal of Jaric: `jearlink -aps` lists the apps, `jearlink -ap Camera` starts one, `jearlink -ntf Done "build ready"` shows a notification when a long command ends: `makej && jearlink -ntf Build ok`.

It talks to the app with `ESC ] 7777 ; intent ; ... BEL` and `ESC ] 7777 ; notify ; ... BEL`, so it works only in the terminal of the Jaric app (needs app 0.0.154 or newer).

License: MPL-2.0.
