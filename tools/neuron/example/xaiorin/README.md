# xaiorin: the training project of the assistant

`data/make_data.py` writes `data/chat.txt` (122 pairs of question and answer about the tools of Jaric, English and Thai; add your own pairs to `data/own.txt`). `makej train` learns it in about 2 minutes on a phone (`-k 16 -d 10 -h 96 -e 14 -r 0.02`: the loss goes from 1.78 to 0.08) and writes `assistant.jw`; `makej install` makes it the assistant (`xr`).

**The trained model is here too** (`assistant.jw`, 560 KB), so you can use it at once:
```
curl -fsSL -o assistant.jw https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/tools/neuron/example/xaiorin/assistant.jw
neuron install assistant.jw
xr start
xr "how do i play music"
```
**What to expect (honest):** a model this small repeats what it was taught. The questions that are in `data/chat.txt` get the right answer; a question put in other words often gets the answer of a similar one, and a question about something else gets an unrelated sentence. To make it better: write each question in several ways (ask like a real person), add more pairs, keep the answers short, train again (`makej train`), and try `-h 128` or more rounds. A learning rate above 0.03 made the loss go up in a test (0.06 diverged).
