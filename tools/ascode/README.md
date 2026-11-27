# ascode: a harness for a model

`ascode` lets a model work in a folder, with the tools of the person: it reads, lists, searches, writes, edits and runs commands, and it asks before it changes anything. The model is yours to choose: Claude, another provider, or a server on this machine.

## First time
Run `ascode`. It asks three things:
1. **Who answers** (a number or a name)
2. **The API key** of that provider: paste it (the `Paste` key of the keys bar), Enter; it shows as stars, `q` leaves
3. **The model:** a number from the list, a word to filter it, or its name (Claude starts with `claude-opus-5-5`)

| Provider | Where a key is made | |
|---|---|---|
| `claude` | console.anthropic.com | Anthropic |
| `openrouter` | openrouter.ai/keys | many models with one key |
| `openai` | platform.openai.com | |
| `gemini` | aistudio.google.com | |
| `groq` | console.groq.com | |
| `deepseek` | platform.deepseek.com | |
| `mistral` | console.mistral.ai | |
| `together` | api.together.xyz | |
| `local` | no key | a llama.cpp server on this machine (port 8080) |
| `ollama` | no key | Ollama on this machine (port 11434) |
| `custom` | your own | any address that speaks "chat completions" |

The APIs are paid by use (some have a free part: see the provider). The model must be able to use tools, or it can only talk.

## A talk
```
ascode
```
Type what you want, one line, and Enter. The talk is remembered until you leave or change who answers.

| Command | What it does |
|---|---|
| `/setup` | choose who answers, key, model |
| `/provider NAME` | another provider (a new talk) |
| `/models word` | the models it offers |
| `/model NAME` | another model (a new talk) |
| `/key` | a new API key |
| `/url ADDRESS` | the address of `local`, `ollama`, `custom` |
| `/mode ask` / `read` / `auto` | how changes are allowed |
| `/max N` | the longest answer in tokens (0: usual) |
| `/note TEXT` | told to the model every time (`/note none`) |
| `/config` | the settings (the key is never shown) |
| `/clear` | a new talk |
| `/help`, `/exit` | |

These choices stay in `~/.config/ascode/config`; a key is in its own file there, readable by you only.

## One task
```
ascode "what is in this folder?"
ascode "fix the error in main.jex"
ascode --mode read "explain main.jex"
ascode --model claude:claude-haiku-5-5 "a small question"
ascode --provider openrouter --model NAME "a question"
ascode config
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
