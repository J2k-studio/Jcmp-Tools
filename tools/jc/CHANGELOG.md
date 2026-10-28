# jc changelog

## 0.3.0
* **Added (jc installs the tools and the libraries itself):** `jc install NAME` (a tool of Jcmp-Tools: downloaded, checked with its SHA-256, put next to jc, with the files that come with it), `jc update [-n]`, `jc unstall NAME`, `jc tools` (the list), and `jc lib list | installed | install NAME | unstall NAME` (the libraries of J2K). It used to ask `jget tool ...`; now it needs no other program (the shared downloader is `core.j`).
* **Changed:** jc and jget cannot be removed with `jc unstall`.
* **Fixed:** none.

## 0.2.0
* **Added:** `jc install NAME` installs a tool of Jcmp-Tools (`jget tool NAME`), `jc install STORE.ID` a program of the store (`jstore`), `jc unstall NAME` removes a tool, `jc update [-n]` updates jsh and the tools that have a newer version, then the store programs.

## 0.1.0
* **Added:** the tool `jc`: install and run the programs of Jaric (`.jc` packages, zip files made by `makej pack` / `makej dist`). `jc info FILE.jc`, `jc install FILE.jc [-y]` (unpacks into `~/.local/share/jc/apps/ID`, shows the permissions the package asks for and asks once; without a terminal it refuses unless `-y`), `jc run ID|FILE.jc [args]` (starts the entry with `JC_PERMS`, `JC_ASSETS`, `JC_HOME`; `JEC_ASSETS` is set too), `jc list`, `jc perm ID [NAME on|off]`, `jc remove ID`.
* **Safety:** an unknown permission name, a missing entry, an odd id or a name with `..` or a first `/` in the package is refused or skipped; an update asks again only for permissions that the old version did not have.
* The permissions are `files network audio camera location clipboard run sessions assistant` (docs/security.md of Jaric). They are a convention that the libraries of Jaric follow, not a wall: until Jaric has its own kernel a program built to cheat can cheat.
