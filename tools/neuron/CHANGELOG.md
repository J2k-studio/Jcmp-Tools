# neuron changelog

## 0.3.1
* **Added:** `neuron where` (and `xr where`): shows the folder of the assistant (`~/.neuron`, a hidden folder because its name starts with a dot) and each file with its size: the model, the events, the learned talk, the settings.

## 0.3.0
* **Added:** the assistant learns from the shell. `xr learn` (or `neuron learn`) reads `~/.neuron/events.txt` (written by jsh 0.8.0 when the setting "xr learns from the shell" is on), makes `~/.neuron/learned.txt` (a wrong command followed by the right one: "Did you mean: git status"; the commands that follow each other) and goes on training the assistant model for 3 rounds (`neuron train DATA -o OUT -i MODEL` does that for any model). `xr forget` deletes what was seen. Nothing is sent anywhere; the learning is a toy until there is much text.
* **Changed:** a new model always has the whole printable ASCII in its vocabulary (so it can learn commands later). Older models still load.

## 0.2.0
* **Added:** the assistant **xaiorin** (short `xr`, also `xaiorin`: the same program under that name, installed with the tool). `xr start` puts a small server on this machine (127.0.0.1) in the background: it keeps the model in memory and remembers the talk; `xr status`, `xr stop`, `xr reset`. `xr "question"` gives one answer, `xr` alone is a chat; both use the background program when it runs and load the model themselves when it does not. Settings in `~/.jash`, section `[xr]`: `port` (7790), `temperature` (0.7), `max` (200), `autostart` (read by the Jaric app: start with the app).
## 0.1.0
* **Added:** the tool `neuron`: train and run small AI models on the phone, all in J2K. `neuron train DATA.txt -o MODEL.jw` learns to continue a text (a small language model: a vector for each byte, the last `-k` bytes side by side, one layer of `-h` neurons, a draw of the next byte; saves after every round), `neuron run MODEL.jw "start"` writes on, `neuron chat [MODEL.jw]` talks with the model (lines `You: ...` / `Bot: ...`), `neuron install MODEL.jw` makes a model the assistant of this phone (`~/.neuron/assistant.jw`; `neuron chat` without a file uses it), `neuron info`, and `neuron ask` for the numeric models of the library `neuron`.
* The file `.jw` version 2 (`neuron-jw 2`, `kind charlm`): a text file with the sizes, the vocabulary and the numbers.
* The source (`neuron.jk`) is the trainer too: read it, change it, build it with `jcmp`.
