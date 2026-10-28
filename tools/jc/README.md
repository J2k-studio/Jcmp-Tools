# jc: install and run the programs of Jaric

A `.jc` is one file that is a whole program: a zip with `manifest.toml` (name, id, version, type, entry, permissions), the program (the entry) and `assets/`. `makej pack` and `makej dist` make it. `jc` unpacks it into `~/.local/share/jc/apps/ID` (`JC_ROOT` names another place), shows what it asks for, and runs it with a clean set of variables.

```
jc tools                         the tools of Jcmp-Tools
jc lib list|installed|install NAME|unstall NAME     the libraries of J2K
jc info game.jc                  name, id, version, the permissions it asks for
jc install NAME                  a tool of Jcmp-Tools (jget tool NAME);  jc install STORE.ID: a store program
jc unstall NAME                  remove a tool
jc update [-n]                   jsh and the tools (and store programs) that have a newer version; -n: only show
jc install game.jc [-y]          unpack, show the permissions, ask once [Y/n] (-y: yes; with no terminal it refuses unless -y)
jc run game [args]               run an installed program (or: jc run game.jc: installed first)
jc list                          what is installed, the version and the permissions it has
jc perm game                     the permissions;   jc perm game network on|off   change one
jc remove game                   delete it
```
A program started by `jc run` gets: `JC_PERMS` (the permissions it has, with commas), `JC_ASSETS` (its `assets` folder, also `JEC_ASSETS` for old programs), `JC_HOME` (its folder); its working folder is its own folder.
**Permissions:** `files network audio camera location clipboard run sessions assistant`. A package asks in `manifest.toml`: `permissions = ["files", "audio"]`. The libraries of Jaric look at `JC_PERMS` and refuse what is not allowed. Honest limit: this is a rule that the libraries follow, not a wall (until Jaric has its own kernel a program made to cheat can cheat); it stops mistakes and honest programs from doing more than they say. See `docs/security.md` of the Jaric project.
An update (the same id) asks again only for permissions that the old version did not have.

## Install
```
jc install jc                                                         # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jc     # with curl
```
In jsh: `jc install jc`.

## A short lesson
1. Make a game: `makej init -game`, then `makej pack` writes `_out/game.jc`.
2. Look at it: `jc info _out/game.jc` (the manifest has `permissions = ["audio"]`).
3. Install it: `jc install _out/game.jc` and answer Enter; `jc list` shows it.
4. Run it: `jc run com.example.mygame` (the id of the manifest).
5. Take a permission away: `jc perm com.example.mygame audio off`. Remove it: `jc remove com.example.mygame`.

License: MPL-2.0 (the zip reader `zipcore.j` is the one of zipj). Build: `JCMP=path sh build.sh`. Test: `sh test.sh` (python3).
