# ascode: a harness for a model

`ascode` lets a model work in a folder, with the tools of the person: it reads, lists, searches, writes, edits and runs commands, and it asks before it changes anything. The model is Claude (the Anthropic API, `claude-opus-5-5` unless you name another); a model on the phone (`llama`) comes later.

## First time
Run `ascode` and paste the key when it asks, or:
1. Make an API key at <https://console.anthropic.com>. The API is paid by use, apart from a Claude subscription.
2. Put it in a file:
```
mkdir -p ~/.config/ascode
fcode ~/.config/ascode/key
```
Paste the key, save (Ctrl-S), quit (Ctrl-Q).

## A talk
```
ascode
```
The first time it asks for the key: paste it (the `Paste` key of the keys bar) and press Enter; it shows as stars, and `q` leaves. Then type what you want, one line, and Enter. The talk is remembered until you leave.

| Command | What it does |
|---|---|
| `/help` | the commands |
| `/model NAME` | another model (a new talk) |
| `/mode ask` / `read` / `auto` | how changes are allowed |
| `/key` | a new API key |
| `/clear` | a new talk |
| `/exit` | leave |

## One task
```
ascode "what is in this folder?"
ascode "fix the error in main.jex"
ascode --mode read "explain main.jex"
ascode --model claude:claude-haiku-5-5 "a small question"
```
The key is only sent to the API; it is never printed.

```
ascode --model mock:script.txt --mode auto "a task"
```
(a scripted model, for tests)

Modes: `ask` (the default: a change needs a y), `read` (changes are refused), `auto` (changes inside the folder are done; a path outside it is asked).
Tools of the model (as a script writes them): `read PATH`, `list [DIR]`, `search TEXT [DIR]`, `write PATH | TEXT`, `edit PATH | OLD | NEW` (OLD must be in the file once), `run COMMAND`.
License: MPL-2.0. Build: `JCMP=path sh build.sh`. Test: `sh test.sh`.

## A short lesson
```
printf 'tool list .\ndone\n' > s.txt
ascode --model mock:s.txt --mode read look
```

## Install
```
ex install ascode
curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install.sh | sh -s ascode
```
