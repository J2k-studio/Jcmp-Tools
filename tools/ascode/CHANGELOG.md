# Changelog

## 0.3.0
* **Added:** other providers: `openrouter`, `openai`, `gemini`, `groq`, `deepseek`, `mistral`, `together`, `local` (llama.cpp), `ollama` and `custom` (any address that speaks chat completions). `ascode setup` chooses who answers, the key and the model (listed from the provider).
* **Added:** settings that stay (`~/.config/ascode/config`): `/provider`, `/models`, `/model`, `/url`, `/mode`, `/max`, `/note`, `/config`; `ascode config`; `--provider`, `--url`.
* **Fixed:** a key is never sent over plain http (only https, or this machine itself).

## 0.2.1
* **Added:** the key shows as stars while it is pasted; `q` leaves the question.
* **Fixed:** one empty line ended the question (a pasted key could then go to the shell); marks and spaces round a pasted key were saved with it.

## 0.2.0
* **Added:** a session: `ascode` (or `ascode claude`) asks for the API key the first time (not shown, saved for you only), then you talk line by line; `/help /model /mode /key /clear /exit`.
* **Added:** the model Claude (`ascode "task"`, or `--model claude:ID`): the Messages API with the six tools, the key from `~/.config/ascode/key` (or `ANTHROPIC_API_KEY`), never printed; the default model is `claude-opus-5-5`.
* **Fixed:** `ascode claude` said "a model is needed".

## 0.1.0
* **Added:** `ascode`, a harness for a model (like the claude command), step A1: the loop, the tools `read`, `list`, `search`, `write`, `edit` (the old text must be in the file once), `run` (a command of jsh, the output comes back), the modes `ask` (the default), `read` and `auto`, and a scripted model for tests (`--model mock:FILE`). The models claude (API) and llama come next.
