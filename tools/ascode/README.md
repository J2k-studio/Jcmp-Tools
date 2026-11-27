# ascode: a harness for a model

`ascode` lets a model work in a folder, with the tools of the person: it reads, lists, searches, writes, edits and runs commands, and it asks before it changes anything. A1 (this version) is the core; the models `claude` (API) and `llama` (on the phone) come next.

```
ascode --model mock:script.txt --mode auto "a task"
```
Modes: `ask` (the default: a change needs a y), `read` (changes are refused), `auto` (changes inside the folder are done; a path outside it is asked).
Tools of the model: `read PATH`, `list [DIR]`, `search TEXT [DIR]`, `write PATH | TEXT`, `edit PATH | OLD | NEW` (OLD must be in the file once), `run COMMAND`.
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
