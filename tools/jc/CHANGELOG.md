# jc changelog

## 0.5.2
* **Added:** none.
* **Fixed:** `jc update` (and `jget tool update`) printed "no packages installed" / "the packages are up to date" after its own answer, so "everything is up to date" was no longer the whole output; the package part is silent now unless something is updated.

## 0.5.1
* **Added:** none.
* **Fixed:** a package of Jcmp-pkg can have a symbolic link to an absolute path of the prefix (python-pip: `cacert.pem`); the unpacking used to stop there. Tool archives still refuse absolute links.

## 0.5.0
* **Added:** `jc pkg update [-n]` (installed packages with another version in the index are removed and installed again; -n only shows), and `jc update` now updates the packages too. `python` moved from the tools to the packages (the real CPython 3.14 of Jcmp-pkg), so `jc install python` gives it.
* **Fixed:** none.

## 0.4.1
* **Added:** `jc install NAME` installs a package of Jcmp-pkg when NAME is not a tool (`jc install git`); `jc pkg ...` stays as the explicit form.
* **Fixed:** none.

## 0.4.0
* **Added:** `jc pkg install NAME | remove NAME | list | search [WORD]`: the packages of Jcmp-pkg (programs built for the prefix of Jaric: git, clang, python ...). It reads `index.json`, installs the dependencies first, checks the SHA-256, unpacks the `.tar.gz` into the folder that holds `usr/` and keeps a list of the files so `remove` can take them away. The tar reader now makes symbolic links and hard links (a copy where the system refuses hard links) and understands GNU long names. An absolute link target is refused. `JC_PKG_INDEX` and `JC_PKG_ROOT` choose another index and folder.
* **Fixed:** none.

## 0.3.1
* **Added:** `jc install jamanager` makes the link `jmanager` next to it (the screen of the task manager), as it does for jbox, zipj and tarj.
* **Fixed:** none.

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
