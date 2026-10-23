# neuron changelog

## 0.2.0
* **Added:** the assistant **xaiorin** (short `xr`, also `xaiorin`: the same program under that name, installed with the tool). `xr start` puts a small server on this machine (127.0.0.1) in the background: it keeps the model in memory and remembers the talk; `xr status`, `xr stop`, `xr reset`. `xr "question"` gives one answer, `xr` alone is a chat; both use the background program when it runs and load the model themselves when it does not. Settings in `~/.jash`, section `[xr]`: `port` (7790), `temperature` (0.7), `max` (200), `autostart` (read by the Jaric app: start with the app).
## 0.1.0
* **Added:** the tool `neuron`: train and run small AI models on the phone, all in J2K. `neuron train DATA.txt -o MODEL.jw` learns to continue a text (a small language model: a vector for each byte, the last `-k` bytes side by side, one layer of `-h` neurons, a draw of the next byte; saves after every round), `neuron run MODEL.jw "start"` writes on, `neuron chat [MODEL.jw]` talks with the model (lines `You: ...` / `Bot: ...`), `neuron install MODEL.jw` makes a model the assistant of this phone (`~/.neuron/assistant.jw`; `neuron chat` without a file uses it), `neuron info`, and `neuron ask` for the numeric models of the library `neuron`.
* The file `.jw` version 2 (`neuron-jw 2`, `kind charlm`): a text file with the sizes, the vocabulary and the numbers.
* The source (`neuron.jk`) is the trainer too: read it, change it, build it with `jcmp`.
