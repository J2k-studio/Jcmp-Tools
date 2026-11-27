# ex: the commands of the system

One program for the tools, the apps, the packages and the settings of exshell. (It was `jc`; `jc` is the old name of the same program.)

```
ex tools              the list of tools
ex install NAME       a tool or a package
ex update             everything that has a newer version (ex itself too)
ex unstall NAME       remove a tool
ex search WORD        find a package
ex run FILE.jc        a program in a .jc file (asks for its permissions once)
ex theme black        a setting of the app (ex setting list shows them all)
ex awake on           keep the sessions running in the background
```
The libraries of the language are the job of `jex`; building a project is the job of `makej`.
License: MPL-2.0. Build: `JCMP=path sh build.sh`. Test: `sh test.sh`.

## A short lesson
```
ex install jexcmp     # the compiler, jex and every library
ex update -n          # what is newer (changes nothing)
ex update
```

## Install
```
ex install ex
curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install.sh | sh -s ex
```
