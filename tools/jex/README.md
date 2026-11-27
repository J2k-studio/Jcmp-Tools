# jex: the command of the language

`jex` fetches the libraries of the language Jex and keeps the compiler up to date. Tools and apps are the job of `ex`; building a project is the job of `makej`.

```
jex lib list          the libraries (a * marks the ones here)
jex lib install NAME  fetch a library: then  #import <name>  works
jex lib update        fetch the newer versions of the ones here
jex update            the compiler jcmp and its Library
jex doctor            is the toolchain whole
```
License: MPL-2.0. Build: `JCMP=path sh build.sh`. Test: `sh test.sh`.

## A short lesson
```
ex install jexcmp     # the compiler, jex and every library
jex lib list
jex lib install png
```

## Install
```
ex install jex
curl -fsSL https://raw.githubusercontent.com/J2k-studio/ex-pkg/main/install.sh | sh -s jex
```
