# jgit: git in J2K

The history of your files, in the folder `.git`, with commands you can remember. Everything is J2K: the names of the objects (SHA-1), the packing (zlib) and the format of the repository are written here, no `git` program is needed. The format is the one of git, so a repository of jgit opens in git and a repository of git opens in jgit (tested both ways with `git fsck`, `git log`, `git status`).

```
jgit init [DIR]          make a repository
jgit add PATH...         put files in the next commit (jgit add . : everything; also the removed files)
jgit commit -m "text"    save what was added
jgit status              what changed:  A added, M changed, D removed, ?? not tracked (the first column: in the next commit, the second: not added yet)
jgit log [-n N]          the history
jgit diff                the lines that changed since the last add (+ and -)
jgit cat [-r] HASH|HEAD|NAME  an object: a commit or a file as text, a tree as a list; -r the raw bytes
jgit branch [NAME]       the branches / make one at the last commit
jgit clone URL [DIR]     copy a repository from a server (https:// or http://; also git@host:user/repo is read as https)
jgit remote [-v] | add NAME URL | remove NAME      the servers of this repository
jgit fetch [NAME]        bring the new branches of the server (refs/remotes/NAME/...)
jgit pull                fetch and move the branch forward when only the server has changes (no merge yet)
jgit push [NAME]         send the commits of the branch to the server
jgit token HOST TOKEN    keep the password (a token) of a server, for you only (~/.jgit/credentials; JGIT_TOKEN in the environment works too)
jgit switch NAME         go to a branch (it refuses while a file has changes that are not saved)
```
Who you are: `export JGIT_NAME="Your Name" JGIT_EMAIL="you@example.org"` or `[user]` in `.git/config` / `~/.gitconfig`. Times are written as UTC (+0000).

Packed repositories (after `git gc` or a `git clone`) are read: the idx and pack files and the deltas, checked byte for byte against git.

**Not yet (said clearly, not guessed):** the address must be https:// or http:// (no ssh), a pull does not merge (it says so when both sides changed), no tags or shallow clones, no merge or rebase, no `.gitignore`, only index version 2. For those, use `git` if you have it.

## Install
```
jc install jgit                                                       # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jgit     # with curl
```
In jsh: `jc install jgit`.

## A short lesson
1. `mkdir notes && cd notes`, then `jgit init`. Tell it who you are (`export JGIT_NAME=... JGIT_EMAIL=...`).
2. Write a file: `echo hello > a.txt`. `jgit status` shows `?? a.txt`.
3. `jgit add a.txt` and `jgit commit -m "first note"`.
4. Change it: `echo more >> a.txt`. `jgit diff` shows `+more`; `jgit add a.txt`, `jgit commit -m "more"`.
5. `jgit log` shows both. `jgit branch try`, `jgit switch try`: files of that branch; `jgit switch main` goes back.

License: MPL-2.0. Build: `JCMP=path sh build.sh` (the library deflate: `jc lib install deflate`, or `J2K_PATH` to the folder). Test: `sh test.sh` (the part with git needs `git`).
