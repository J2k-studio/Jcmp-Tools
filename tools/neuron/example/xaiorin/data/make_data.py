# Writes data/chat.txt: the talk that xaiorin learns (questions and answers about the tools of Jaric, in English).
# Edit the list QA (or add your own lines to data/own.txt, same shape) and run:  python3 data/make_data.py
import random, os
random.seed(7)
QA = [
 (["hello","hi","hey","good morning"], "Hi! I am xaiorin, your helper. Ask me about the tools."),
 (["who are you","what is your name","your name"], "I am xaiorin, xr for short, a small model that runs on your phone."),
 (["how are you","how do you do"], "I am fine, thank you. What do you want to do?"),
 (["thank you","thanks"], "You are welcome."),
 (["bye","goodbye","see you"], "Goodbye! See you."),
 (["what can you do","help"], "I can tell you how to use jget, makej, jsh, mujic, python and the other tools."),
 (["how do i install a tool","install a tool","add a program","get a new tool"], "Use jc install NAME, for example jc install mujic. jc list shows what there is."),
 (["how do i update jget","update jget"], "Run jc update. It updates jsh and every tool that has a newer version."),
 (["how do i install python","install python"], "Run jc install python. Then python3 and pip work."),
 (["how do i install pip","where is pip"], "pip comes with the tool python: jc install python."),
 (["how do i install yt-dlp","install yt-dlp"], "Run jc install python yt-dlp. Use it only for what you may download."),
 (["how do i update the compiler","update jcmp"], "Run jc install jcmp. makej needs jcmp 1.2.0.0 or newer."),
 (["how do i build a program","compile a program"], "Write hello.jk and run jcmp hello.jk -o hello."),
 (["how do i run a program","run my program"], "After jcmp hello.jk -o hello type ./hello."),
 (["what is makej","what does makej do"], "makej is the build tool. makej builds, makej run runs, makej -j builds on many cores."),
 (["how do i start a project","new project"], "Make a folder and run makej init -pro NAME."),
 (["how do i make a game","start a game"], "Run makej init -game and then makej run."),
 (["how do i make an ai","train an ai"], "Run makej init -ai, edit data/chat.txt, then makej train."),
 (["how do i talk to you","how to use xr"], "Type xr and a question, or just xr to chat."),
 (["how do i start the assistant","start xr"], "Run xr start. It runs in the background."),
 (["how do i stop the assistant","stop xr"], "Run xr stop."),
 (["how do i make you learn","xr learn"], "Turn on the setting in jaric setting, use the shell, then run xr learn."),
 (["how do i delete what you saw","xr forget"], "Run xr forget. It deletes the events and the learned text."),
 (["where are your files","where is the model"], "In the folder .neuron in your home. Run xr where to see it."),
 (["how do i play music","play a song"], "Type mujic. Then write part of a song name and press Enter."),
 (["how do i get free music","fetch a song"], "In mujic type /get and choose a free song."),
 (["how do i add my songs","import songs"], "In mujic type /import PATH, or put the files in the folder music."),
 (["how do i sort songs into folders","move a song"], "In mujic type /mv NAME FOLDER."),
 (["how do i see the lyrics","show lyrics"], "In mujic type /lyrics get, then /lyrics."),
 (["how do i edit a file","open the editor"], "Run coderin FILE. Save with Ctrl-S and quit with Ctrl-Q."),
 (["how do i see running programs","task manager"], "Run jamanager ps, or jamanager top."),
 (["how do i stop a program","kill a program","close a running program"], "Run jamanager kill PID."),
 (["how much memory is free","check memory"], "Run jamanager mem."),
 (["how do i see the disk","free space"], "Run jamanager drives."),
 (["how do i change the settings","open settings"], "Type jaric setting. Use the arrows and Enter."),
 (["how do i change the font size","bigger letters"], "In jaric setting choose font size, or pinch the screen."),
 (["how do i change the theme","change colours"], "Type jaric theme NAME, for example jaric theme amber."),
 (["how do i restart the app","restart jaric"], "Type jaric restart."),
 (["how do i open a new tab","new session"], "Tap + at the top, or type start PROGRAM."),
 (["how do i run a script","run a jsh script"], "Write the file with [#jsh] on the first line and run jsh file.jsh."),
 (["how do i download a file","download a file"], "Run jget URL. It shows a progress bar."),
 (["how do i download and run a script","run a script from the net"], "jget -jsh URL. Only use addresses you trust."),
 (["how do i open a zip file","unzip"], "Run unj FILE.zip."),
 (["how do i make a zip file","zip a folder"], "Run zipj out.zip FOLDER."),
 (["how do i open a tar file","untar"], "Run tarj x FILE.tar.gz."),
 (["how do i list files","show files","list a folder"], "Run dir. Use dir -a to see hidden ones."),
 (["how do i find a word in files","search text"], "Run grep -n WORD FILE."),
 (["how do i see a video file","play video"], "Run jaric video FILE."),
 (["how do i read a video file","video info"], "Run jvp4 info FILE."),
 (["how do i update everything","update my tools","get new versions"], "Run jc update. jc update -n only shows what would change."),
 (["how do i remove a tool","uninstall a tool","delete a tool"], "Run jc unstall NAME. jsh and jget cannot be removed."),
 (["how do i delete a file","remove a file","erase a file"], "Run rm FILE."),
 (["how do i delete a folder","remove a folder","delete a directory"], "Run rm -r FOLDER. It deletes the folder and everything in it."),
 (["how do i make a folder","create a folder","new directory"], "Run mkdir NAME. mkdir -p makes the parents too."),
 (["how do i copy a file","copy a file"], "Run cp FROM TO. Use cp -r for a folder."),
 (["how do i move a file","rename a file","rename something"], "Run mv FROM TO. It also renames."),
 (["how do i read a file","show a file","print a file"], "Run cat FILE. Use head or tail for a part."),
 (["where am i","what folder am i in","show the current folder"], "Run pwd. pwd -p shows the real path."),
 (["how do i change folder","go to a folder"], "Run cd FOLDER. cd :/ goes home, cd 0:/ to the phone storage."),
 (["what are drives","what is f: and 0:"], "f:/ is your home, 0:/ is the storage of the phone, r:/ is the root. drive shows them."),
 (["how do i make a new drive","create a drive"], "Run drive new NAME for a new folder as a drive, or drive new NAME PATH for a folder you have. A size like 2G is allowed."),
 (["how do i see the real path of a drive","what is the real path"], "Run drive -p :/bin. drive -d PATH goes the other way."),
 (["how do i keep the app alive","the app closes when i swipe it"], "Run jaric keepalive and allow the app to run in the background. The wake lock button is in the notification."),
 (["how do i use git","where is git"], "Run jgit. It works on local repositories: init, add, commit, status, log, diff."),
 (["how do i build the app","make an apk"], "Run makej apk in a project made with makej init -pro."),
 (["how do i see the version of a tool","which version"], "Run NAME --version, for example jsh --version."),
 (["what is jsh","what is the shell"], "jsh is the shell of Jaric. Type help inside it."),
 (["what is the kernel","do you have an os"], "The Jaric kernel is being built step by step; it runs in jemu first. See Jaric/os/kernel."),
 (["what is jash","what is the jash file"], "jash keeps the settings of your programs in the file .jash. Use jash list and jash set."),
 (["what is a jc file","what is a .jc package"], "A .jc file is a program package of Jaric, made by makej pack."),
 (["what is jc","what does jc do"], "jc installs and runs the programs of Jaric: jc install NAME, jc update, jc unstall NAME, jc list."),
 (["what is a jw file","what is jw"], "A .jw file is a model of neuron, the whole AI in one file."),
 (["what is j2k","what language is this"], "J2K is the language of Jaric. Its compiler is jcmp."),
 (["what is jaric","what is this app"], "Jaric is a terminal app with its own shell, tools and a language."),
]
IDK = "I do not know that. Ask me about the tools of Jaric (for example: how do I install a tool)."
OOD = ["what is the weather","what is the capital of france","tell me a joke","who is the president","what is two plus two","how tall is mount everest","translate hello to french","what is the meaning of life","play a game with me","what time is it in tokyo","who won the football match","recommend a movie","how do i cook rice","what is the price of gold","write me a poem","what is the weather on mars","who invented the telephone","how far is the moon","what is your favorite colour","tell me about dogs"]
QA += [([q], IDK) for q in OOD]
# Ways to put a question in other words. The first group is used for learning, the second group is kept back for testing
# (data/test.txt): the model must answer questions it has never seen in that form.
TRAIN_FORMS = ["{q}", "{q}?", "please {q}", "tell me {q}", "can you tell me {q}", "i want to know {q}", "{q} please", "quick question: {q}", "hey, {q}", "ok so {q}", "xr, {q}", "help me: {q}", "i need to know {q}", "{q} now", "what about this: {q}", "again, {q}"]
TEST_FORMS = ["could you tell me {q}", "i would like to know {q}", "{q}, thanks", "one more thing: {q}", "so {q}?", "um {q}"]
def forms(q, kind):
    out = []
    for f in (TRAIN_FORMS if kind == "train" else TEST_FORMS):
        out.append(f.format(q=q))
    return out
lines = []
test = []
for qs, a in QA:
    for q in qs:
        for v in forms(q, "train"):
            lines.append(f"You: {v}\nBot: {a}\n")
        for v in forms(q, "test"):
            test.append(f"You: {v}\nBot: {a}\n")
own = os.path.join(os.path.dirname(__file__), "own.txt")
if os.path.exists(own):
    lines.append(open(own, encoding="utf-8").read().rstrip("\n") + "\n")
text = ""
for _ in range(2):                      # every pair twice, in a new order each time
    random.shuffle(lines)
    text += "".join(lines)
open(os.path.join(os.path.dirname(__file__), "chat.txt"), "w", encoding="utf-8").write(text)
print(len(lines), "pairs,", len(text.encode("utf-8")), "bytes")
open(os.path.join(os.path.dirname(__file__), "test.txt"), "w", encoding="utf-8").write("".join(test))
print(len(test), "test pairs (never used for learning) in data/test.txt")
