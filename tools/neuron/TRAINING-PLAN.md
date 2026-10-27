# Training plan: from a toy to an assistant that answers (plan, adjustable)

**Status 2026-10-27 (measured with `neuron eval example/xaiorin/assistant.jw example/xaiorin/data/test.txt`, 1104 questions in forms never used for learning): both (as xr) 98 % right, was 56 %.** What changed: the data (`make_data.py`: answers brought up to date with `jc`, 20 more topics, 20 questions outside the topic that must get "I do not know", 16 forms of each question instead of 10, 2944 pairs). The model alone is still 0 % (it writes text byte by byte and does not generalise); the answers come from the search before the model. Training: `neuron train data/chat.txt -o assistant.jw -k 16 -d 12 -h 128 -e 8 -r 0.02`, 15 minutes on the phone. A tool older than 0.4.0 saves a model WITHOUT the pairs (then 0 %): use `neuron --version` before training.

**Where we are (measured, 2026-10-23, `neuron eval`):** the model alone answers 19% of questions it never saw in that form (it has to write the whole answer exactly); the search before the model answers 96%. The model is a small network over the last 16 bytes (one hidden layer, no attention), so it repeats sentences it saw; it does not understand a question put in other words. More rounds do not change that: the loss on the learned text is already 0.08-0.11.

## What "real training" means here, step by step
1. **Measure first (done):** `neuron eval MODEL.jw TEST.txt` on pairs that are never learned. Every change below must raise this number or it is not kept. Keep a table in `example/xaiorin/RESULTS.md` (date, settings, search %, model %, both %).
2. **Data is most of the work.** For the tools of Jaric: 56 answers; write **each question in 10 or more ways** (`data/make_data.py`: forms, own paraphrases in `data/own.txt`), add answers for every command of every tool (generate them from the READMEs and `--help` texts with a script, then read and fix by hand), add 'I do not know' answers for questions outside the tools so the model learns to say it. Goal: 300 answers x 10 forms = 3000 pairs (500 KB).
3. **A model that can generalise** (each step is a new version of neuron, measured with step 1):
   * (a) word-level tokens (about 2000 words + letters for unknown words) instead of bytes: the model sees "stop" and "kill" as units; 
   * (b) two hidden layers and a bigger embedding (-d 32, -h 256); 
   * (c) an **encoder for the question** (the mean of the vectors of its words) that picks the answer from the list of known answers (classification): a small network that is trained to say *which answer*; it generalises to new wordings much better than writing letters, and it cannot invent wrong commands;
   * (d) only then, a small attention model for free text.
   The order is by gain per work: (c) gives the answer-picking that an assistant of commands needs, (a)(b) help (c), (d) is the big step.
4. **Train on the phone, in the background:** `nohup setsid neuron train ... &` (the phone gives 2-3 cores: 1120 pairs x 8 rounds take 6 minutes; 3000 pairs x 20 rounds take about 1.5 hours); a checkpoint after every round (done); `-i` goes on from a model.
5. **Learn from use, with care:** `xr learn` adds what the shell saw (fixes of mistyped commands, the commands that follow each other). It stays off by default, runs on this phone only, and is checked by `neuron eval` before the new model replaces the old one (keep `assistant.jw.old`).
6. **When to say it is good:** 90% or more of the held-out questions answered right by the whole assistant, and "I do not know" for at least 80% of questions outside the tools; until then the README says honestly what works.

## What is not planned
A big language model (billions of numbers) cannot be trained on a phone; if the owner wants one, the way is a model trained elsewhere in the same `.jw` file format with a loader for it (a separate decision).
