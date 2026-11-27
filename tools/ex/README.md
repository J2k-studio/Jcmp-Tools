# ex: the commands of the system

One program for the tools, the apps, the packages and the settings of exshell. (It was called `jc` before.)

```
ex tools              what can be installed (tools and programs)
ex install NAME       get it (a tool, or a program such as git)
ex list               what is installed
ex update             everything that has a newer version (ex itself too)
ex unstall NAME       remove a tool
ex search WORD        find one
ex run FILE.jc        a program in a .jc file (asks for its permissions once)
ex theme black        a setting of the app (ex setting list shows them all)
ex awake on           keep the sessions running in the background
ex doctor             is everything in place, and what to do
ex app update         the newest app (Android asks you to tap Update)
```
The libraries of the language are the job of `jex`; building a project is the job of `makej`.
License: MPL-2.0. Build: `JCMP=path sh build.sh`. Test: `sh test.sh`.

## It asks first
At a terminal `ex install`, `ex update` and `ex unstall` show what they will do and ask `[y/n]`; only `y` goes on.

| Command | What it does |
|---|---|
| `ex update` | what is newer: tools, then packages, then the app; one question for each group |
| `ex update jsh` | only `jsh` (several names work; `app` is the app) |
| `ex update -n` | only show |
| `ex install git -y` | no question (`--yes` too) |
| `ex unstall mascot` | turns the mascot of the app off (`ex set mascot on` brings it back) |

A script that runs `ex` has nobody to ask, so it goes on as before.

## Ask the app
In exshell (0.1.89 or newer) these talk to the app, also from a script that runs in the background:

| Command | What it does |
|---|---|
| `ex toast TEXT` | a short note on the screen |
| `ex notify TITLE TEXT` | a notification |
| `ex copy TEXT`, `cmd \| ex copy`, `ex paste` | the clipboard (Android gives it only while exshell is in front) |
| `ex open FILE-OR-LINK`, `ex share FILE`, `ex send TEXT` | other apps of the phone |
| `ex pick image` / `ex pick file` | choose on the phone; prints the path of a copy |
| `ex apps`, `ex launch NAME`, `ex call NUMBER`, `ex apk FILE` | apps, the dialler, the installer |
| `ex play FILE`, `ex pause`, `ex resume`, `ex stop` | sound |
| `ex battery`, `ex torch on`, `ex vibrate 200` | the phone |
| `ex tab COMMAND` | a new session that runs it |
| `ex awake on`, `ex exit` | keep running, close the app |
| `ex api` | the words the app knows |

In a program: `jex lib install exapi`, then `#import <exapi>` and `Ex::notify("done", "it passed");` (see the library's page). A phone cannot be shut down or restarted by an app without root.

## A short lesson
```
ex install jexcmp     # the compiler, jex and every library
ex update -n          # what is newer (changes nothing)
ex update
```

## Install
```
ex install ex
curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install.sh | sh -s ex
```
