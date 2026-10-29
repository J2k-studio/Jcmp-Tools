# jintent

The apps of the phone from the terminal of the Jaric app: open a link, share a text or a file, pick a file, call, start an app, list the apps, show a notification.

## Commands
```
jintent view https://example.org      # opens it in the app the phone picks
jintent send hello world              # the share sheet of the phone
jintent share ~/pic.png               # share a file
jintent pick image                    # the picker of the phone
jintent call 112                      # the dialer
jintent app Camera                    # start an app by name or package
jintent apps                          # the apps that can be started (name TAB package)
jintent notify Done "the build is ready"
```

## Install
```
jc install jintent                                                         # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jintent     # with curl (no jget needed)
```
Both check the SHA-256 of the file before anything is installed.

## A short lesson
In the terminal of Jaric: `jintent apps` lists the apps, `jintent app Camera` starts one, `jintent notify Done "build ready"` shows a notification when a long command ends: `makej && jintent notify Build ok`.

It talks to the app with `ESC ] 7777 ; intent ; ... BEL` and `ESC ] 7777 ; notify ; ... BEL`, so it works only in the terminal of the Jaric app (needs app 0.0.154 or newer).

License: MPL-2.0.
