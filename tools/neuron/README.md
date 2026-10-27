# neuron: small AI models on the phone, in J2K

Train a small language model on a text file, write with it, talk with it, and make it the assistant of your phone. Everything is J2K (the library `neuron` and this program); no Python, no GPU needed. A model is one text file, `.jw`.

```
neuron train DATA.txt -o MODEL.jw [-k 8] [-d 12] [-h 96] [-e 5] [-r 0.05]    learn a text (it saves after every round)
neuron run MODEL.jw "start of a text" [-n 200] [-t 0.8]                      write on from the start (-t 0: always the most likely byte)
neuron chat [MODEL.jw]                                                       talk: you type a line, the model answers; an empty line leaves
neuron install MODEL.jw                                                      make it the assistant (~/.neuron/assistant.jw): then  neuron chat
neuron info MODEL.jw                                                         what is in the file
neuron ask MODEL.jw X1 X2 ...                                                a numeric model made with the library neuron
```
How it learns: for every place of the text the model sees the last `-k` bytes and must guess the next one; a wrong guess changes the numbers a little (rate `-r`); one pass over the text is a round (`-e` rounds). A text of 3 KB takes about 10 seconds for 6 rounds; 1 MB takes hours: start small. `-k` is how far back it looks, `-d` the numbers for each byte, `-h` the neurons (more = remembers more, slower).

**The search before the model:** the pairs of the text are kept in the `.jw` file; when you ask, `xr` first looks for the question of the talk that is the most like yours (words in another order, small letters, a mark more or less) and answers with its answer; only when nothing is like enough (below `match`, 0.5) the model writes. Switch it off: `jash set xr.search off`.

**To teach it to chat**, write the text as lines of a talk, many of them, in the same shape: `You: hello`, `Bot: Hi!` (see `example/chat.txt`). `neuron chat` puts `You: your line` and `Bot: ` in front of the model and stops the answer at the line end. It copies and mixes what it saw: a small model on a small text is a toy, a good one needs a lot of good text and many rounds.

The program `neuron.jk` is the trainer: it is short, and it is yours to change (another model shape, another way to learn). Build: `JCMP=path sh build.sh` (jcmp 1.2.0.0; the library neuron is in `build/libs` of Jcmp or `jget -li install neuron`).

## xaiorin (xr): the assistant that runs in the background
`neuron install MODEL.jw` makes a model the assistant. It is called **xaiorin**, short **xr** (both names come with the tool: they are the same program):
```
xr start | stop | status | reset      the background program: keeps the model in memory and remembers the talk
xr "what is your name"                one answer;   xr  alone = a chat
```
Settings (`jash set xr.port 7791`): `port` (7790), `temperature` (0.7), `max` (bytes of an answer, 200), `autostart` (on / off: the Jaric app starts `xr start` when it opens; `jaric setting`, section "assistant").

## The tool and the library are two things
`jget tool neuron` installs this **program** (train, run, chat, xr). `jget -li install neuron` installs the **library** `<neuron>` (a J2K source file with `Tensor` and `Network`, for your own programs). The project of `makej init -ai` needs only the program, and its steps install it by themselves.

## Install
```
jget tool neuron                                                     # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s neuron     # with curl
```
In jsh: `jc install neuron`.

## A short lesson
1. Get the sample: write a file `chat.txt` of lines `You: ...` and `Bot: ...` (40 or more lines, the same questions again and again help a small model), or copy `example/chat.txt`.
2. Train: `neuron train chat.txt -o chat.jw -k 12 -d 8 -h 64 -e 6 -r 0.08`. Watch the loss go down.
3. Write: `neuron run chat.jw "You: hello" -n 40 -t 0`.
4. Talk: `neuron chat chat.jw`.
5. Keep it: `neuron install chat.jw`; from now `neuron chat` opens it. `makej init -ai` makes a project that does these steps (`makej train`, `makej ask`, `makej install`).

License: MPL-2.0. Test: `sh test.sh`.
