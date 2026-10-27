# jgit changelog

## 0.3.0
* **Added:** `jgit login` asks your name and email once and keeps them in `~/.jgit/user` (`jgit login --name N --email E` asks nothing). `jgit commit` at a terminal asks the same when it does not know who you are; without a terminal it says `run jgit login`. The commit prints `author: NAME <EMAIL>` so you see who it was made as, and `jgit log` shows it.
* **Changed:** the identity comes from `JGIT_NAME` / `JGIT_EMAIL`, then the repository `config`, then `~/.jgit/user` (jgit login), then `~/.gitconfig`. Before, a `~/.gitconfig` that was already on the phone (for example the one of another git) was used without a word, so commits were made as that person.

## 0.2.0
* **Added:** packs. jgit reads the objects that git packed (`git gc`, `git gc --aggressive`, `git clone`): the index `.idx` (version 2, with the fanout table and 64 bit offsets), the pack `.pack`, and the deltas (against an object earlier in the pack, or against one by its name). Checked: every object of a repository packed with `--aggressive` (commits, trees, files, many deltas) is the same, byte for byte, as git reads it; `log`, `status`, `diff` and `switch` work in a clone.
* **Added:** `jgit cat` prints a tree as a list (`mode kind hash<tab>name`, like `git cat-file -p`) and `jgit cat -r` prints the raw bytes (a zero byte no longer cuts the output).
* Still not: the network (clone, fetch, push), merge, rebase, `.gitignore`, index version 3 and 4.
## 0.1.0
* **Added:** the tool `jgit`, git written in J2K (SHA-1, zlib and the format of the repository folder are its own code). It reads and writes the folder `.git` in the format of git, so a repository of jgit is a repository of git (`git fsck`, `git log`, `git status` agree with it) and the other way round. Commands: `init [DIR]`, `add PATH...` (`add .` takes everything and drops what was removed), `commit -m "text"`, `status`, `log [-n N]`, `diff` (the lines changed since the last add), `cat HASH|HEAD|BRANCH`, `branch [NAME]`, `switch BRANCH` (refuses while there are unsaved changes). The name of the author: `JGIT_NAME` / `JGIT_EMAIL`, else `[user]` of `.git/config` or `~/.gitconfig`.
* **Not yet:** objects that git packed (`git gc`, a clone) are said clearly and not read; no network (clone, fetch, push); no merge, no rebase, no `.gitignore`, index version 2 only.
