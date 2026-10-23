# xaiorin: the training project of the assistant

`data/make_data.py` writes `data/chat.txt` (1120 pairs: 56 questions and answers about the tools of Jaric, each asked in 10 ways, English only; add your own pairs to `data/own.txt`) and `data/test.txt` (672 pairs asked in 6 other ways, **never used for learning**). `makej train` learns it in about 6 minutes on a phone (`-k 16 -d 12 -h 128 -e 8 -r 0.02`) and writes `assistant.jw`; `makej install` makes it the assistant (`xr`). `neuron eval assistant.jw data/test.txt` measures it.

**The trained model is here too** (`assistant.jw`, 560 KB), so you can use it at once:
```
curl -fsSL -o assistant.jw https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/tools/neuron/example/xaiorin/assistant.jw
neuron install assistant.jw
xr start
xr "how do i play music"
```
**Measured (neuron 0.4.0):** of 150 questions asked in ways it never learned, the search before the model answers 96% right, the model alone 19%, both together (as `xr` works) 96%.

**What to expect (honest):** a model this small repeats what it was taught. The questions that are in `data/chat.txt` get the right answer; a question put in other words often gets the answer of a similar one, and a question about something else gets an unrelated sentence. To make it better: write each question in several ways (ask like a real person), add more pairs, keep the answers short, train again (`makej train`), and try `-h 128` or more rounds. A learning rate above 0.03 made the loss go up in a test (0.06 diverged).
